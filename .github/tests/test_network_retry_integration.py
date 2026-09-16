from __future__ import annotations

import ast
import importlib.util
import io
import json
import os
import subprocess
import tempfile
import unittest
import urllib.request
from pathlib import Path
from unittest import mock
from urllib.error import HTTPError


ROOT = Path(__file__).resolve().parents[2]


def git(root, *arguments):
    return subprocess.check_output(["git", "-C", str(root), *arguments], text=True).strip()


class NetworkRetryWorkflowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = json.loads(subprocess.check_output([
            "ruby", "-ryaml", "-rjson", "-e", "puts JSON.generate(YAML.load_file(ARGV[0]))",
            str(ROOT / ".github/workflows/ci.yml"),
        ], text=True))
        cls.runs = [step["run"] for job in cls.workflow["jobs"].values()
                    for step in job["steps"] if "run" in step]

    def test_all_four_download_entries_load_both_control_files_on_legacy_checkout(self):
        runs = [run for run in self.runs if "release_download_control_dir=" in run]
        self.assertEqual(4, len(runs))
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            git(fixture, "init", "-q")
            git(fixture, "config", "user.name", "Fixture Owner")
            git(fixture, "config", "user.email", "fixture@example.test")
            git(fixture, "commit", "-qm", "legacy", "--allow-empty")
            legacy = git(fixture, "rev-parse", "HEAD")
            scripts = fixture / ".github/scripts"
            scripts.mkdir(parents=True)
            for filename in ("download_release_assets.py", "github_http_retry.py"):
                (scripts / filename).write_bytes((ROOT / ".github/scripts" / filename).read_bytes())
            git(fixture, "add", ".github")
            git(fixture, "commit", "-qm", "control")
            control = git(fixture, "rev-parse", "HEAD")
            git(fixture, "checkout", "-q", legacy)
            self.assertFalse((fixture / ".github/scripts/github_http_retry.py").exists())
            for index, run in enumerate(runs):
                with self.subTest(entry=index):
                    invocation = 'python3 "${release_download_control_dir}/download_release_assets.py"'
                    start = run.index("release_download_control_dir=")
                    end = run.index(invocation, start) + len(invocation)
                    bootstrap = run[start:end] + " --help"
                    self.assertIn("${WORKFLOW_CONTROL_SHA}:.github/scripts/github_http_retry.py", bootstrap)
                    self.assertIn("${WORKFLOW_CONTROL_SHA}:.github/scripts/download_release_assets.py", bootstrap)
                    result = subprocess.run(
                        ["bash", "-e", "-o", "pipefail", "-c", bootstrap],
                        cwd=fixture, capture_output=True, text=True, timeout=10,
                        env={"PATH": os.environ.get("PATH", os.defpath),
                             "RUNNER_TEMP": directory, "WORKFLOW_CONTROL_SHA": control},
                    )
                    self.assertEqual(0, result.returncode, result.stderr)
                    self.assertIn("--mode", result.stdout)

    def test_inline_provenance_uses_pinned_helper_and_retries_same_request(self):
        run = next(run for run in self.runs if "comparison = call_with_retry(request_once)" in run)
        self.assertIn("${WORKFLOW_CONTROL_SHA}:.github/scripts/github_http_retry.py", run)
        self.assertIn('RELEASE_HTTP_RETRY_DIR="${release_http_control_dir}"', run)
        self.assertIn('sys.path.insert(0, os.environ["RELEASE_HTTP_RETRY_DIR"])', run)
        source = run.split("python3 - <<'PY'\n", 1)[1].rsplit("\nPY", 1)[0]
        tree = ast.parse(source)
        request_function = next(node for node in tree.body
                                if isinstance(node, ast.FunctionDef) and node.name == "request_once")
        assignment = next(node for node in tree.body if isinstance(node, ast.Assign)
                          and any(isinstance(target, ast.Name) and target.id == "comparison"
                                  for target in node.targets))
        specification = importlib.util.spec_from_file_location(
            "workflow_http_retry", ROOT / ".github/scripts/github_http_retry.py")
        retry = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(retry)
        request = urllib.request.Request("https://api.github.com/repos/owner/source/compare/a...b",
                                         headers={"Authorization": "Bearer fixture-token"})
        error = HTTPError(request.full_url, 503, "Unavailable", {}, io.BytesIO())
        namespace = {"request": request, "urllib": urllib, "json": json,
                     "call_with_retry": retry.call_with_retry}
        try:
            with mock.patch.object(urllib.request, "urlopen", side_effect=[error, io.BytesIO(b"{}")]) as opened:
                with mock.patch.object(retry.time, "sleep") as sleeper:
                    exec(compile(ast.Module(body=[request_function, assignment], type_ignores=[]),
                                 "workflow-provenance", "exec"), namespace)
            self.assertEqual({}, namespace["comparison"])
            self.assertEqual(2, opened.call_count)
            self.assertIs(opened.call_args_list[0].args[0], opened.call_args_list[1].args[0])
            sleeper.assert_called_once_with(1)
        finally:
            error.close()


if __name__ == "__main__":
    unittest.main()
