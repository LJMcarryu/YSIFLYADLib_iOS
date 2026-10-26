from __future__ import annotations

import argparse
import ast
import copy
import hashlib
import importlib.util
import json
import os
import re
import subprocess
import tempfile
import unittest
import urllib.request
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/ci.yml"


def load_module(name: str, path: Path):
    specification = importlib.util.spec_from_file_location(name, path)
    assert specification is not None and specification.loader is not None
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


MODE = load_module(
    "ys_validate_release_mode", ROOT / ".github/scripts/validate_release_mode.py"
)
DOWNLOAD = load_module(
    "ys_download_release_assets", ROOT / ".github/scripts/download_release_assets.py"
)
COCOAPODS = load_module(
    "ys_prepare_cocoapods_fixture",
    ROOT / ".github/scripts/prepare_cocoapods_fixture.py",
)
REPOSITORY_CONTRACT = load_module(
    "ys_verify_repository_contract",
    ROOT / ".github/scripts/verify_repository_contract.py",
)

RELEASE_CONTROL = json.loads(
    (ROOT / ".github/scripts/release-control.json").read_text(encoding="utf-8")
)
VERSION = RELEASE_CONTROL["targetVersion"]
CLOSED_VERSION = RELEASE_CONTROL["closedVersion"]
CANDIDATE_VERSION = VERSION
if RELEASE_CONTROL["state"] == "BOOTSTRAP_CLOSED":
    major, minor, patch = (int(part) for part in CLOSED_VERSION.split("."))
    CANDIDATE_VERSION = f"{major}.{minor}.{patch + 1}"
BINARY_COMMIT = "a" * 40
METADATA_COMMIT = "b" * 40
CANDIDATE_ID = "d" * 64
DISPATCH_NONCE = "e" * 32
CANDIDATE_BRANCH = f"release-candidate/{VERSION}-{CANDIDATE_ID}"
DRAFT_SLUG = "untagged-" + "f" * 16


def git(root: Path, *arguments: str) -> str:
    completed = subprocess.run(
        ["git", "-C", str(root), *arguments],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return completed.stdout.strip()


def write_contract(root: Path, state: str) -> None:
    marker = VERSION.replace(".", "_")
    if state == "PENDING":
        checksum = f"__YSIFLYADLIB_{marker}_SWIFTPM_CHECKSUM_PENDING__"
        binary = BINARY_COMMIT
        metadata = METADATA_COMMIT
    else:
        checksum = "1" * 64
        binary = BINARY_COMMIT
        metadata = METADATA_COMMIT
    (root / "Package.swift").write_text(
        "// swift-tools-version:5.9\n"
        'url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS/'
        f'releases/download/{VERSION}/YSIFLYADLib.xcframework.zip",\n'
        f'checksum: "{checksum}"\n',
        encoding="utf-8",
    )
    (root / "YSIFLYADLib.podspec").write_text(
        f"s.version = '{VERSION}'\n"
        "s.source = { :http => 'https://github.com/LJMcarryu/"
        f"YSIFLYADLib_iOS/releases/download/{VERSION}/"
        f"YSIFLYADLib-{VERSION}.zip' }}\n",
        encoding="utf-8",
    )
    (root / "RELEASING.md").write_text(
        "面向维护者的自由格式发布说明；不承载机器门禁事实。\n",
        encoding="utf-8",
    )
    (root / "scripts").mkdir(exist_ok=True)
    (root / "scripts/release_state.py").write_text(
        (ROOT / "scripts/release_state.py").read_text(encoding="utf-8"),
        encoding="utf-8",
    )
    phase = "PREPARING" if state == "PENDING" else "FROZEN"
    (root / "release-state.json").write_text(json.dumps({
        "schemaVersion": 1, "channel": "ys",
        "repository": "LJMcarryu/YSIFLYADLib_iOS", "version": VERSION,
        "phase": phase, "binarySourceCommit": binary,
        "releaseMetadataCommit": metadata,
        "artifactInventory": {"count": 3, "sha256": "2" * 64},
        "appleReview": {"requiredForRelease": False, "statusAtFreeze": "not-run",
                        "evidenceIncluded": False},
        "publication": None,
    }), encoding="utf-8")


def create_repository(root: Path, state: str) -> str:
    root.mkdir(parents=True)
    git(root, "init", "-q", "-b", "main")
    git(root, "config", "user.name", "Workflow Test")
    git(root, "config", "user.email", "workflow-test@example.invalid")
    write_contract(root, state)
    git(root, "add", ".")
    git(root, "commit", "-q", "-m", state)
    head = git(root, "rev-parse", "HEAD")
    git(root, "update-ref", "refs/remotes/origin/main", head)
    return head


def mode_arguments(root: Path, **overrides: str) -> argparse.Namespace:
    mode = overrides.get("mode", "draft_candidate")
    head = git(root, "rev-parse", "HEAD")
    is_draft = mode == "draft_candidate"
    values = {
        "root": root,
        "mode": mode,
        "event_name": "workflow_dispatch",
        "event_ref": f"refs/heads/{CANDIDATE_BRANCH}" if is_draft else "refs/heads/main",
        "event_ref_name": CANDIDATE_BRANCH if is_draft else "main",
        "event_ref_type": "branch",
        "event_sha": head,
        "repository": "LJMcarryu/YSIFLYADLib_iOS",
        "release_tag": "",
        "candidate_release_id": "12345" if is_draft else "",
        "candidate_id": CANDIDATE_ID if is_draft else "",
        "candidate_branch": CANDIDATE_BRANCH if is_draft else "",
        "dispatch_nonce": DISPATCH_NONCE if is_draft else "",
        "github_output": None,
    }
    values.update(overrides)
    return argparse.Namespace(**values)


def release_body(mode: str) -> str:
    binary = BINARY_COMMIT
    metadata = METADATA_COMMIT
    return (
        f"- `binarySourceCommit`（SDK 二进制源码提交）：`{binary}`\n"
        "- `releaseMetadataCommit`（仅回填 checksum、扫描汇总和发布验收事实，"
        f"不是 SDK 二进制源码提交）：`{metadata}`\n"
        + (f"- `candidateId`：`{CANDIDATE_ID}`\n" if mode == "draft_candidate" else "")
    )


def release_fixture(mode: str, contents: dict[str, bytes]) -> dict[str, object]:
    repository = "LJMcarryu/YSIFLYADLib_iOS"
    download_slug = DRAFT_SLUG if mode == "draft_candidate" else VERSION
    assets = []
    for index, name in enumerate(sorted(contents), start=1):
        digest = hashlib.sha256(contents[name]).hexdigest()
        assets.append(
            {
                "name": name,
                "state": "uploaded",
                "size": len(contents[name]),
                "digest": f"sha256:{digest}",
                "url": (
                    f"https://api.github.com/repos/{repository}/"
                    f"releases/assets/{index}"
                ),
                "browser_download_url": (
                    f"https://github.com/{repository}/releases/download/"
                    f"{download_slug}/{name}"
                ),
            }
        )
    draft = mode == "draft_candidate"
    return {
        "id": 12345,
        "tag_name": VERSION,
        "target_commitish": CANDIDATE_BRANCH if draft else "main",
        "draft": draft,
        "prerelease": False,
        "published_at": None if draft else "2026-08-10T00:00:00Z",
        "html_url": (
            f"https://github.com/{repository}/releases/tag/{download_slug}"
        ),
        "body": release_body(mode),
        "assets": assets,
    }


class ReleaseModeContractTests(unittest.TestCase):
    def test_repository_mode_has_no_release_inputs_or_asset_identity(self) -> None:
        with tempfile.TemporaryDirectory(prefix="ys-mode-repository-") as directory:
            root = Path(directory) / "repository"
            head = create_repository(root, "PENDING")
            result = MODE.validate_contract(
                mode_arguments(
                    root,
                    mode="repository",
                    event_name="push",
                    release_tag="",
                    candidate_release_id="",
                )
            )
            self.assertEqual(result["mode"], "repository")
            self.assertEqual(result["checkout_commit"], head)

            for field in (
                "release_tag",
                "candidate_release_id",
                "candidate_id",
                "candidate_branch",
                "dispatch_nonce",
            ):
                with self.subTest(field=field), self.assertRaises(MODE.ContractError):
                    MODE.validate_contract(
                        mode_arguments(
                            root,
                            mode="repository",
                            event_name="push",
                            release_tag=VERSION if field == "release_tag" else "",
                            candidate_release_id="123" if field == "candidate_release_id" else "",
                            candidate_id=CANDIDATE_ID if field == "candidate_id" else "",
                            candidate_branch=CANDIDATE_BRANCH if field == "candidate_branch" else "",
                            dispatch_nonce=DISPATCH_NONCE if field == "dispatch_nonce" else "",
                        )
                    )

    def test_draft_candidate_requires_trigger_sha_branch_final_formal_and_exact_identity(self) -> None:
        with tempfile.TemporaryDirectory(prefix="ys-mode-formal-candidate-") as directory:
            root = Path(directory) / "repository"
            head = create_repository(root, "FORMAL")
            result = MODE.validate_contract(mode_arguments(root))

            self.assertEqual(result["mode"], "draft_candidate")
            self.assertEqual(result["checkout_ref"], CANDIDATE_BRANCH)
            self.assertEqual(result["checkout_commit"], head)
            self.assertEqual(result["candidate_release_id"], "12345")
            self.assertEqual(result["candidate_id"], CANDIDATE_ID)
            self.assertEqual(result["dispatch_nonce"], DISPATCH_NONCE)
            self.assertRegex(result["candidate_identity"], r"^[0-9a-f]{64}$")

            for label, overrides in (
                ("错误分支", {"event_ref": "refs/heads/feature"}),
                ("错误 ref_name", {"event_ref_name": "feature"}),
                ("checkout 与触发 SHA 不同", {"event_sha": "f" * 40}),
                ("非手动", {"event_name": "push"}),
                ("缺少 ID", {"candidate_release_id": ""}),
                ("非法 candidateId", {"candidate_id": "D" * 64}),
                ("非法 nonce", {"dispatch_nonce": "0" * 31}),
                ("混入正式 tag", {"release_tag": VERSION}),
                ("非官方同仓", {"repository": "someone/YSIFLYADLib_iOS"}),
            ):
                with self.subTest(label=label), self.assertRaises(MODE.ContractError):
                    MODE.validate_contract(mode_arguments(root, **overrides))

    def test_formal_mode_requires_formal_manifest_and_annotated_tag_checkout(self) -> None:
        with tempfile.TemporaryDirectory(prefix="ys-mode-formal-") as directory:
            root = Path(directory) / "repository"
            head = create_repository(root, "FORMAL")
            git(root, "tag", "-a", VERSION, "-m", "formal")
            git(root, "checkout", "-q", VERSION)
            result = MODE.validate_contract(
                mode_arguments(
                    root,
                    mode="formal_release",
                    event_name="workflow_dispatch",
                    event_ref="refs/heads/main",
                    release_tag=VERSION,
                    candidate_release_id="",
                )
            )
            self.assertEqual(result["checkout_commit"], head)
            self.assertEqual(result["release_tag"], VERSION)

            release_event = MODE.validate_contract(
                mode_arguments(
                    root,
                    mode="formal_release",
                    event_name="release",
                    event_ref=f"refs/tags/{VERSION}",
                    event_ref_type="tag",
                    release_tag=VERSION,
                    candidate_release_id="",
                )
            )
            self.assertEqual(release_event["checkout_commit"], head)
            with self.assertRaises(MODE.ContractError):
                MODE.validate_contract(
                    mode_arguments(
                        root,
                        mode="formal_release",
                        event_name="release",
                        event_ref="refs/tags/6.2.1",
                        event_ref_type="tag",
                        release_tag=VERSION,
                        candidate_release_id="",
                    )
                )

            git(root, "tag", "-d", VERSION)
            git(root, "tag", VERSION)
            with self.assertRaises(MODE.ContractError):
                MODE.validate_contract(
                    mode_arguments(
                        root,
                        mode="formal_release",
                        event_name="workflow_dispatch",
                        release_tag=VERSION,
                        candidate_release_id="",
                    )
                )

    def test_candidate_and_formal_modes_require_exact_frozen_phase(self) -> None:
        for mode in ("draft_candidate", "formal_release"):
            for phase in ("PREPARING", "PUBLISHED", "VERIFIED"):
                with self.subTest(mode=mode, phase=phase), tempfile.TemporaryDirectory(
                    prefix="ys-mode-wrong-state-"
                ) as directory:
                    root = Path(directory) / "repository"
                    create_repository(root, "FORMAL")
                    state_path = root / "release-state.json"
                    state = json.loads(state_path.read_text(encoding="utf-8"))
                    state["phase"] = phase
                    state_path.write_text(json.dumps(state), encoding="utf-8")
                    git(root, "add", "release-state.json")
                    git(root, "commit", "-q", "-m", phase)

                    overrides = {}
                    if mode == "formal_release":
                        git(root, "tag", "-a", VERSION, "-m", "formal")
                        git(root, "checkout", "-q", VERSION)
                        overrides = {
                            "mode": "formal_release",
                            "release_tag": VERSION,
                            "candidate_release_id": "",
                        }
                    with self.assertRaises(MODE.ContractError):
                        MODE.validate_contract(mode_arguments(root, **overrides))

    def test_local_contract_rejects_distribution_url_drift(self) -> None:
        for label, filename in (
            ("SwiftPM", "Package.swift"),
            ("CocoaPods", "YSIFLYADLib.podspec"),
        ):
            with self.subTest(label=label), tempfile.TemporaryDirectory(
                prefix="ys-url-drift-"
            ) as directory:
                root = Path(directory)
                write_contract(root, "PENDING")
                path = root / filename
                path.write_text(
                    path.read_text(encoding="utf-8").replace(
                        "https://github.com/LJMcarryu/YSIFLYADLib_iOS/",
                        "https://example.invalid/LJMcarryu/YSIFLYADLib_iOS/",
                    ),
                    encoding="utf-8",
                )
                with self.assertRaises(MODE.ContractError):
                    MODE.read_local_contract(root)

    def test_repository_stages_635_over_allowed_lifecycle_and_keeps_history(self) -> None:
        contract = MODE.read_local_contract(ROOT)
        self.assertIn(
            (contract["version"], contract["state_version"], contract["phase"]),
            {
                (CLOSED_VERSION, CLOSED_VERSION, "CLOSED"),
                (VERSION, CLOSED_VERSION, "CLOSED"),
                (VERSION, VERSION, "FROZEN"),
                (VERSION, VERSION, "CLOSED"),
            },
        )
        MODE.validate_formal(contract)

        documents = {
            name: (ROOT / name).read_text(encoding="utf-8")
            for name in ("README.md", "CHANGELOG.md", "RELEASING.md")
        }
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            write_contract(fixture, "FORMAL")
            (fixture / "RELEASING.md").write_text("任意维护说明\n", encoding="utf-8")
            self.assertEqual(MODE.read_local_contract(fixture)["release_state"], "FORMAL")

        self.assertIn("## [6.2.2] - 2026-08-10", documents["CHANGELOG.md"])
        self.assertIn("## [6.3.1] - 2026-09-01", documents["CHANGELOG.md"])
        self.assertIn(
            "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2",
            documents["CHANGELOG.md"],
        )
        self.assertIn(
            "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.3",
            documents["CHANGELOG.md"],
        )
        self.assertIn("[更新记录](CHANGELOG.md)", documents["README.md"])
        self.assertIn(
            "757f133d00cbd248366392f1dbf460adbd35089588c8da57b1cf947adc7f813d",
            documents["RELEASING.md"],
        )
        self.assertNotEqual(
            contract["checksum"],
            "73a1e82ffee9c01d63f1e6a391c732e8837c422d23ab60846c92e8f2c167ad08",
        )
        for marker in (
            "`failOnWarning=true`",
            "`strict=true`",
            "`requireManual=true`",
            "接受名单为空",
        ):
            self.assertIn(marker, documents["RELEASING.md"])


class ReleaseDownloaderTests(unittest.TestCase):
    def setUp(self) -> None:
        self.contents = {
            f"YSIFLYADLib-{VERSION}.zip": b"combined",
            "YSIFLYADLib.xcframework.zip": b"spm",
            "checksums.txt": b"checksums",
        }

    def download_for_url(self, url: str, headers, timeout: int = 300) -> bytes:
        del timeout
        if "/releases/download/" in url:
            self.assertNotIn("Authorization", headers)
        for name, contents in self.contents.items():
            if url.endswith("/" + name):
                return contents
        asset_id = url.rsplit("/", 1)[-1]
        names = sorted(self.contents)
        if asset_id.isdigit() and 1 <= int(asset_id) <= len(names):
            return self.contents[names[int(asset_id) - 1]]
        raise AssertionError(url)

    def arguments(self, temporary: Path, mode: str) -> argparse.Namespace:
        temporary.mkdir(parents=True, exist_ok=True)
        release_state_path = temporary / "release-state.json"
        state = json.loads((ROOT / "release-state.json").read_text(encoding="utf-8"))
        state["version"] = VERSION
        state["phase"] = "FROZEN"
        state["binarySourceCommit"] = BINARY_COMMIT
        state["releaseMetadataCommit"] = METADATA_COMMIT
        state["artifactInventory"] = {
            "count": 3,
            "sha256": "b0962e8e1129f680024fef53365802aa6797e6c163f8b7be18e4e9cec1020cf4",
        }
        state["publication"] = None
        release_state_path.write_text(json.dumps(state), encoding="utf-8")
        formal = mode == "formal_release"
        event_path = temporary / "event.json"
        if formal:
            event_path.write_text(json.dumps({
                "action": "published",
                "repository": {"full_name": state["repository"]},
                "release": release_fixture("formal_release", self.contents),
            }), encoding="utf-8")
        return argparse.Namespace(
            mode=mode,
            repository="LJMcarryu/YSIFLYADLib_iOS",
            version=VERSION,
            expected_commit="c" * 40,
            candidate_release_id="12345" if mode == "draft_candidate" else "",
            formal_release_id="12345" if formal else "",
            event_name="release" if formal else "",
            event_path=event_path if formal else None,
            candidate_id=CANDIDATE_ID if mode == "draft_candidate" else "",
            target_branch=CANDIDATE_BRANCH if mode == "draft_candidate" else "",
            release_state=release_state_path,
            release_metadata_output=temporary / "release-metadata.json",
            destination=temporary / "assets",
        )

    def test_draft_download_requires_token_and_exact_draft_identity(self) -> None:
        with tempfile.TemporaryDirectory(prefix="ys-draft-download-") as directory:
            temporary = Path(directory)
            arguments = self.arguments(temporary, "draft_candidate")
            release = release_fixture("draft_candidate", self.contents)
            with (
                mock.patch.dict(os.environ, {"GITHUB_TOKEN": "secret"}, clear=True),
                mock.patch.object(
                    DOWNLOAD,
                    "request_json",
                    side_effect=[release, {"object": {"sha": "c" * 40}}],
                ),
                mock.patch.object(
                    DOWNLOAD, "download_bytes", side_effect=self.download_for_url
                ),
            ):
                hashes = DOWNLOAD.run(arguments)

            self.assertEqual(set(hashes), set(self.contents))
            self.assertEqual(
                json.loads(arguments.release_metadata_output.read_text(encoding="utf-8"))["id"],
                12345,
            )
            for name, contents in self.contents.items():
                self.assertEqual((arguments.destination / name).read_bytes(), contents)

            missing_token = self.arguments(temporary / "missing", "draft_candidate")
            with mock.patch.dict(os.environ, {}, clear=True), self.assertRaises(
                DOWNLOAD.DownloadError
            ):
                DOWNLOAD.run(missing_token)

    def test_formal_download_is_anonymous_and_reuses_verified_assets(self) -> None:
        with tempfile.TemporaryDirectory(prefix="ys-formal-download-") as directory:
            temporary = Path(directory)
            arguments = self.arguments(temporary, "formal_release")
            release = release_fixture("formal_release", self.contents)
            with (
                mock.patch.dict(os.environ, {}, clear=True),
                mock.patch.object(
                    DOWNLOAD, "download_bytes", side_effect=self.download_for_url
                ) as download,
            ):
                DOWNLOAD.run(arguments)
            self.assertEqual(download.call_count, len(self.contents))
            arguments.release_metadata_output.unlink()
            with (
                mock.patch.dict(os.environ, {}, clear=True),
                mock.patch.object(
                    DOWNLOAD,
                    "download_bytes",
                    side_effect=AssertionError("已校验缓存不得再次下载"),
                ),
            ):
                DOWNLOAD.run(arguments)

            leaked = self.arguments(temporary / "leaked", "formal_release")
            with (
                mock.patch.dict(os.environ, {"GITHUB_TOKEN": "control-only"}, clear=True),
                mock.patch.object(
                    DOWNLOAD, "download_bytes", side_effect=self.download_for_url
                ),
            ):
                DOWNLOAD.run(leaked)

    def test_asset_download_retries_timeout_and_uses_atomic_part(self) -> None:
        payload = b"asset"
        item = {
            "name": "asset.zip",
            "url": "https://api.github.com/repos/owner/repo/releases/assets/1",
            "browser_download_url": "https://github.com/owner/repo/releases/download/1.0.0/asset.zip",
            "size": len(payload),
            "digest": "sha256:" + hashlib.sha256(payload).hexdigest(),
        }
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory) / "asset.zip"
            with (
                mock.patch.object(
                    DOWNLOAD,
                    "download_bytes",
                    side_effect=[TimeoutError("TLS handshake timeout"), payload],
                ) as download,
                mock.patch.object(DOWNLOAD.time, "sleep") as sleep,
            ):
                actual = DOWNLOAD.download_asset(
                    item, destination, mode="formal_release", token=""
                )
            self.assertEqual(actual, hashlib.sha256(payload).hexdigest())
            self.assertEqual(download.call_count, 2)
            sleep.assert_called_once_with(1)
            self.assertEqual(destination.read_bytes(), payload)
            self.assertFalse(Path(f"{destination}.part").exists())

    def test_inventory_and_provenance_drift_fail_closed(self) -> None:
        release = release_fixture("draft_candidate", self.contents)
        documented = DOWNLOAD.provenance(release_body("draft_candidate"), VERSION, "draft_candidate")
        parameters = {
            "mode": "draft_candidate",
            "repository": "LJMcarryu/YSIFLYADLib_iOS",
            "version": VERSION,
            "candidate_release_id": "12345",
            "candidate_id": CANDIDATE_ID,
            "target_branch": CANDIDATE_BRANCH,
            "expected_commit": "c" * 40,
            "documented_provenance": documented,
            "resolved_target_commit": "c" * 40,
        }
        DOWNLOAD.validate_release(release, **parameters)
        exact_commit_release = copy.deepcopy(release)
        exact_commit_release["target_commitish"] = parameters["expected_commit"]
        DOWNLOAD.validate_release(
            exact_commit_release,
            **{**parameters, "resolved_target_commit": None},
        )

        for label, mutate in (
            ("非 draft", lambda value: value.__setitem__("draft", False)),
            ("错误 ID", lambda value: value.__setitem__("id", 999)),
            ("错误候选分支", lambda value: value.__setitem__("target_commitish", "dev")),
            ("多余资产", lambda value: value["assets"].append(copy.deepcopy(value["assets"][0]))),
            (
                "资产 URL 漂移",
                lambda value: value["assets"][0].__setitem__(
                    "browser_download_url",
                    value["assets"][0]["browser_download_url"] + ".old",
                ),
            ),
            ("正文漂移", lambda value: value.__setitem__("body", "missing provenance")),
        ):
            with self.subTest(label=label):
                mutated = copy.deepcopy(release)
                mutate(mutated)
                with self.assertRaises(DOWNLOAD.DownloadError):
                    DOWNLOAD.validate_release(mutated, **parameters)

    def test_draft_rejects_asset_with_different_untagged_slug(self) -> None:
        release = release_fixture("draft_candidate", self.contents)
        release["assets"][0]["browser_download_url"] = release["assets"][0][
            "browser_download_url"
        ].replace(DRAFT_SLUG, "untagged-deadbeef")
        documented = DOWNLOAD.provenance(
            release_body("draft_candidate"), VERSION, "draft_candidate"
        )

        with self.assertRaisesRegex(DOWNLOAD.DownloadError, "Release slug"):
            DOWNLOAD.validate_release(
                release,
                mode="draft_candidate",
                repository="LJMcarryu/YSIFLYADLib_iOS",
                version=VERSION,
                candidate_release_id="12345",
                candidate_id=CANDIDATE_ID,
                target_branch=CANDIDATE_BRANCH,
                expected_commit="c" * 40,
                documented_provenance=documented,
                resolved_target_commit="c" * 40,
            )

    def test_formal_release_rejects_untagged_html_url(self) -> None:
        release = release_fixture("formal_release", self.contents)
        release["html_url"] = (
            f"https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/{DRAFT_SLUG}"
        )
        documented = DOWNLOAD.provenance(
            release_body("formal_release"), VERSION, "formal_release"
        )

        with self.assertRaisesRegex(DOWNLOAD.DownloadError, "html_url"):
            DOWNLOAD.validate_release(
                release,
                mode="formal_release",
                repository="LJMcarryu/YSIFLYADLib_iOS",
                version=VERSION,
                candidate_release_id="",
                candidate_id="",
                target_branch="",
                expected_commit="c" * 40,
                documented_provenance=documented,
            )

    def test_cross_host_redirect_strips_authorization(self) -> None:
        request = urllib.request.Request(
            "https://api.github.com/repos/example/release/assets/1",
            headers={"Authorization": "Bearer secret", "Accept": "application/octet-stream"},
        )
        handler = DOWNLOAD.CrossHostCredentialSafeRedirect()
        redirected = handler.redirect_request(
            request,
            None,
            302,
            "Found",
            {},
            "https://objects.githubusercontent.com/signed-asset",
        )
        self.assertIsNotNone(redirected)
        headers = {key.lower(): value for key, value in redirected.header_items()}
        self.assertNotIn("authorization", headers)
        self.assertEqual(headers["accept"], "application/octet-stream")


class CocoaPodsFixtureTests(unittest.TestCase):
    def test_fixture_rewrites_only_binary_source_and_demo_podspec(self) -> None:
        with tempfile.TemporaryDirectory(prefix="ys-cocoapods-fixture-") as directory:
            temporary = Path(directory)
            root = temporary / "repository"
            release_dir = temporary / "release"
            output = temporary / "fixture"
            (root / "YSIFLYADLibSimple").mkdir(parents=True)
            release_dir.mkdir()
            (release_dir / f"YSIFLYADLib-{VERSION}.zip").write_bytes(b"zip")
            (root / "YSIFLYADLib.podspec").write_text(
                "Pod::Spec.new do |s|\n"
                "  s.name = 'YSIFLYADLib'\n"
                f"  s.version = '{VERSION}'\n"
                "  s.summary = 'fixture'\n"
                "  s.homepage = 'https://example.invalid'\n"
                "  s.author = { 'Test' => 'test@example.invalid' }\n"
                "  s.license = { :type => 'MIT' }\n"
                "  s.source = { :http => 'https://example.invalid/original.zip' }\n"
                "  s.ios.deployment_target = '11.0'\n"
                "end\n",
                encoding="utf-8",
            )
            (root / "YSIFLYADLibSimple/Podfile").write_text(
                "target 'YSIFLYADLibSimple' do\n"
                "  pod 'YSIFLYADLib', :podspec => 'https://example.invalid/spec'\n"
                "end\n",
                encoding="utf-8",
            )
            (root / "YSIFLYADLibSimple/project.pbxproj").write_text(
                "project\n", encoding="utf-8"
            )

            COCOAPODS.prepare(root, release_dir, output, VERSION)

            podspec = (output / "YSIFLYADLib.podspec").read_text(encoding="utf-8")
            podfile = (output / "YSIFLYADLibSimple/Podfile").read_text(
                encoding="utf-8"
            )
            self.assertIn(
                (release_dir / f"YSIFLYADLib-{VERSION}.zip").resolve().as_uri(),
                podspec,
            )
            self.assertIn(hashlib.sha256(b"zip").hexdigest(), podspec)
            self.assertIn(str(output / "YSIFLYADLib.podspec"), podfile)
            self.assertTrue((output / "YSIFLYADLibSimple/project.pbxproj").is_file())
            parsed = json.loads(
                subprocess.check_output(
                    ["pod", "ipc", "spec", str(output / "YSIFLYADLib.podspec")],
                    text=True,
                )
            )
            self.assertEqual(
                parsed["source"]["sha256"], hashlib.sha256(b"zip").hexdigest()
            )


class WorkflowStructureTests(unittest.TestCase):
    NATIVE_SOURCE = "YSIFLYADLibSimple/YSIFLYADLibSimple/biz/native/YSIFLYNativeViewController.m"
    NATIVE_GUIDE = "docs/接入指南/广告加载与展示.md"
    NATIVE_DOC_MARKERS = (
        "allowsExternalClickViews",
        "ysifly_nativeFeedAd:didRejectClickWithError:",
        "YSIFLYAdErrorCodeNativeFeedClickViewsInvalid",
        "ysifly_detachFromCurrentContainer",
    )

    def run_native_gate(self, root: Path) -> subprocess.CompletedProcess[str]:
        step, = [
            step for step in self.jobs["verify-repository"]["steps"]
            if step.get("name") == "校验 NativeFeed 托管 API 与 Demo 复用乱序防护"
        ]
        return subprocess.run(
            ["bash", "--noprofile", "--norc", "-eo", "pipefail", "-c", step["run"]],
            cwd=root, capture_output=True, text=True,
        )

    def write_native_fixture(self, root: Path) -> None:
        for relative in (self.NATIVE_SOURCE, self.NATIVE_GUIDE, "README.md"):
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes((ROOT / relative).read_bytes())

    def test_native_gate_runs_actual_workflow_shell(self) -> None:
        result = self.run_native_gate(ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_native_gate_requires_each_authoritative_guide_marker(self) -> None:
        for marker in self.NATIVE_DOC_MARKERS:
            with self.subTest(marker=marker), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.write_native_fixture(root)
                guide = root / self.NATIVE_GUIDE
                source = guide.read_text(encoding="utf-8")
                self.assertIn(marker, source)
                guide.write_text(source.replace(marker, "REMOVED_API"), encoding="utf-8")
                (root / "README.md").write_text("\n".join(self.NATIVE_DOC_MARKERS), encoding="utf-8")
                result = self.run_native_gate(root)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn(marker, result.stderr)

    def test_native_gate_keeps_source_history_rejection(self) -> None:
        for marker in ("YSIFLYNativeFeedDisplaySession", "YSIFLYNativeFeedAdBinding"):
            with self.subTest(marker=marker), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.write_native_fixture(root)
                path = root / self.NATIVE_SOURCE
                path.write_text(path.read_text(encoding="utf-8") + "\n" + marker, encoding="utf-8")
                result = self.run_native_gate(root)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn(marker, result.stderr)

    def test_native_gate_keeps_source_attach_requirement(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_native_fixture(root)
            path = root / self.NATIVE_SOURCE
            source = path.read_text(encoding="utf-8")
            self.assertIn("ysifly_attachWithViewBinder:", source)
            path.write_text(source.replace("ysifly_attachWithViewBinder:", "REMOVED_API"), encoding="utf-8")
            result = self.run_native_gate(root)
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("ysifly_attachWithViewBinder:", result.stderr)

    @classmethod
    def setUpClass(cls) -> None:
        command = [
            "ruby",
            "-ryaml",
            "-rjson",
            "-e",
            "puts JSON.generate(YAML.load_file(ARGV[0]))",
            str(WORKFLOW),
        ]
        result = subprocess.run(
            command,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        cls.workflow = json.loads(result.stdout)
        cls.jobs = cls.workflow["jobs"]
        cls.source = WORKFLOW.read_text(encoding="utf-8")
        cls._podspec_temp = tempfile.TemporaryDirectory(prefix="ys-podspec-json-")
        cls.addClassCleanup(cls._podspec_temp.cleanup)
        cls.podspec_json = Path(cls._podspec_temp.name) / "YSIFLYADLib.json"
        podspec = subprocess.run(
            ["pod", "ipc", "spec", str(ROOT / "YSIFLYADLib.podspec")],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        cls.podspec_json.write_text(podspec.stdout, encoding="utf-8")

    def test_yaml_and_all_embedded_bash_blocks_parse(self) -> None:
        for job_name, job in self.jobs.items():
            for index, step in enumerate(job.get("steps", [])):
                script = step.get("run")
                if not isinstance(script, str):
                    continue
                result = subprocess.run(
                    ["bash", "-n"],
                    input=script,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    check=False,
                )
                self.assertEqual(
                    result.returncode,
                    0,
                    f"{job_name} step[{index}] {step.get('name')}:\n{result.stdout}",
                )

    def test_all_inline_python_heredocs_compile(self) -> None:
        pattern = re.compile(
            r"python3 - <<'PY'\n(?P<body>.*?)\n\s*PY(?:\n|$)",
            re.DOTALL,
        )
        blocks = list(pattern.finditer(self.source))
        self.assertGreater(len(blocks), 0)
        for index, match in enumerate(blocks, start=1):
            lines = match.group("body").splitlines()
            indentation = min(
                len(line) - len(line.lstrip()) for line in lines if line.strip()
            )
            source = "\n".join(line[indentation:] for line in lines) + "\n"
            compile(source, f"ci.yml inline Python #{index}", "exec")

    def test_white_labeled_reject_callback_accepts_only_exact_selector(self) -> None:
        matches = re.findall(
            r"white_labeled_reject_callback = re\.compile\(\n\s*(r\"[^\"]+\")\n\s*\)",
            self.source,
        )
        self.assertEqual(len(matches), 1)
        callback = re.compile(ast.literal_eval(matches[0]))

        real_multiline_declaration = (
            "- (void)ysifly_nativeFeedAd:(IFLYNativeFeedAd *)ad\n"
            "    didRejectClickWithError:(IFLYAdError *)error;"
        )
        self.assertIsNotNone(callback.search(real_multiline_declaration))

        invalid_declarations = {
            "缺少回调段": (
                "- (void)ysifly_nativeFeedAd:(IFLYNativeFeedAd *)ad;"
            ),
            "缺少白标前缀": (
                "- (void)nativeFeedAd:(IFLYNativeFeedAd *)ad\n"
                "    didRejectClickWithError:(IFLYAdError *)error;"
            ),
            "错误回调段": (
                "- (void)ysifly_nativeFeedAd:(IFLYNativeFeedAd *)ad\n"
                "    didRejectClick:(IFLYAdError *)error;"
            ),
        }
        for label, declaration in invalid_declarations.items():
            with self.subTest(label=label):
                self.assertIsNone(callback.search(declaration))

    def run_resolver(
        self,
        *,
        event_name: str = "workflow_dispatch",
        event_ref: str | None = None,
        event_ref_name: str | None = None,
        release_event_tag: str = "",
        release_event_id: str = "",
        requested_mode: str = "repository",
        release_tag: str = "",
        formal_release_id: str = "",
        candidate_release_id: str = "",
        candidate_id: str = "",
        dispatch_nonce: str = "",
        control_plane_canary: bool = False,
        canary_tag: str = "",
        canary_release_id: str = "",
        canary_candidate_id: str = "",
    ) -> tuple[subprocess.CompletedProcess[str], dict[str, str]]:
        resolver = self.jobs["resolve-validation-mode"]["steps"][0]["run"]
        if event_ref is None:
            if control_plane_canary:
                branch = f"release-candidate/{canary_tag}-{canary_candidate_id}"
            elif requested_mode == "draft_candidate" and candidate_id:
                branch = f"release-candidate/{VERSION}-{candidate_id}"
            else:
                branch = "main"
            event_ref = f"refs/heads/{branch}"
            event_ref_name = branch
        elif event_ref_name is None:
            event_ref_name = event_ref.removeprefix("refs/heads/")
        with tempfile.TemporaryDirectory(prefix="ys-resolver-") as directory:
            output = Path(directory) / "github-output"
            environment = os.environ.copy()
            environment.update(
                {
                    "EVENT_NAME": event_name,
                    "EVENT_REF": event_ref,
                    "EVENT_REF_NAME": event_ref_name,
                    "RELEASE_EVENT_TAG": release_event_tag,
                    "RELEASE_EVENT_ID": release_event_id,
                    "REQUESTED_MODE": requested_mode,
                    "INPUT_RELEASE_TAG": release_tag,
                    "INPUT_FORMAL_RELEASE_ID": formal_release_id,
                    "INPUT_CANDIDATE_RELEASE_ID": candidate_release_id,
                    "INPUT_CANDIDATE_ID": candidate_id,
                    "INPUT_DISPATCH_NONCE": dispatch_nonce,
                    "CONTROL_PLANE_CANARY": str(control_plane_canary).lower(),
                    "CANARY_TAG": canary_tag,
                    "CANARY_RELEASE_ID": canary_release_id,
                    "CANARY_CANDIDATE_ID": canary_candidate_id,
                    "TARGET_VERSION": VERSION,
                    "GITHUB_OUTPUT": str(output),
                }
            )
            result = subprocess.run(
                ["bash"],
                input=resolver,
                env=environment,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                check=False,
            )
            values = {}
            if output.is_file():
                for line in output.read_text(encoding="utf-8").splitlines():
                    key, value = line.split("=", 1)
                    values[key] = value
            return result, values

    def test_only_draft_download_steps_inject_github_token(self) -> None:
        self.assertEqual(self.workflow["permissions"], {"contents": "read"})
        self.assertEqual(self.jobs["resolve-validation-mode"]["permissions"], {})
        token_steps = []
        for job_name, job in self.jobs.items():
            for step in job.get("steps", []):
                if "GITHUB_TOKEN" in (step.get("env") or {}):
                    token_steps.append((job_name, step))
        self.assertEqual(
            {job_name for job_name, _ in token_steps},
            {
                "control-plane-canary",
                "validate-release-assets",
                "consume-swiftpm-release",
                "consume-cocoapods-release",
            },
        )
        self.assertEqual(len(token_steps), 5)
        for job_name, step in token_steps:
            if step.get("name") == "无 Token 匿名下载已发布正式 Release 精确三资产":
                self.assertEqual(
                    step["env"]["GITHUB_TOKEN"],
                    "${{ github.event_name == 'workflow_dispatch' && github.token || '' }}",
                )
                self.assertIn("--formal-release-id", step["run"])
                continue
            if job_name == "control-plane-canary":
                self.assertNotIn("if", step)
            else:
                self.assertIn("draft_candidate", step["if"])
            self.assertEqual(
                step["env"]["GITHUB_TOKEN"],
                "${{ secrets.DRAFT_RELEASE_READ_TOKEN }}",
            )
        self.assertIn("--formal-release-id", self.source)

    def test_candidate_inputs_branch_and_exact_run_names_are_bound(self) -> None:
        inputs = self.workflow["true"]["workflow_dispatch"]["inputs"]
        for name in (
            "candidate_release_id", "candidate_id", "dispatch_nonce",
            "control_plane_canary", "canary_tag", "canary_release_id",
            "canary_candidate_id",
        ):
            self.assertIn(name, inputs)
        self.assertIn("draft-candidate:{0}:{1}:{2}", self.workflow["run-name"])
        self.assertIn("formal-release:{0}:{1}", self.workflow["run-name"])
        self.assertIn("control-plane-canary:{0}:{1}:{2}", self.workflow["run-name"])
        self.assertEqual(self.workflow["env"]["RELEASE_TARGET_VERSION"], VERSION)
        result, values = self.run_resolver(
            requested_mode="draft_candidate",
            candidate_release_id="12345",
            candidate_id=CANDIDATE_ID,
            dispatch_nonce=DISPATCH_NONCE,
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(values["checkout_ref"], CANDIDATE_BRANCH)
        self.assertEqual(values["candidate_branch"], CANDIDATE_BRANCH)

        wrong_version = CLOSED_VERSION if VERSION != CLOSED_VERSION else "0.0.0"
        wrong_version_branch = f"release-candidate/{wrong_version}-{CANDIDATE_ID}"
        result, _ = self.run_resolver(
            requested_mode="draft_candidate",
            candidate_release_id="12345",
            candidate_id=CANDIDATE_ID,
            dispatch_nonce=DISPATCH_NONCE,
            event_ref=f"refs/heads/{wrong_version_branch}",
            event_ref_name=wrong_version_branch,
        )
        self.assertNotEqual(result.returncode, 0, result.stdout)

        for name, value in (
            ("canary_tag", "6.3.2001"),
            ("canary_release_id", "98765"),
            ("canary_candidate_id", CANDIDATE_ID),
        ):
            result, _ = self.run_resolver(**{name: value})
            self.assertNotEqual(
                result.returncode,
                0,
                f"非 Canary 模式错误接受了 {name}",
            )

    def test_control_plane_canary_reuses_draft_downloader_without_heavy_builds(self) -> None:
        canary = self.jobs["control-plane-canary"]
        self.assertEqual(
            set(canary["needs"]), {"resolve-validation-mode", "verify-repository"}
        )
        self.assertEqual(canary["permissions"], {"contents": "read"})
        source = "\n".join(step.get("run", "") for step in canary["steps"])
        self.assertIn("DRAFT_RELEASE_READ_TOKEN", json.dumps(canary))
        self.assertIn("download_release_assets.py", source)
        self.assertIn('test "$CANARY_TAG" != "$state_version"', source)
        self.assertIn("release-candidate/${CANARY_TAG}-${CANARY_CANDIDATE_ID}", source)
        self.assertIn("release_control_plane_checks.py fixture", source)
        production = (ROOT / "scripts/release_control_plane_checks.py").read_text(
            encoding="utf-8"
        )
        self.assertIn("symlink_to", production)
        self.assertIn("resolve_pod_root", production)
        self.assertIn("didRejectClickWithError:", source)
        for forbidden in ("xcodebuild", "pod install", "swift build"):
            self.assertNotIn(forbidden, source)

        result, values = self.run_resolver(
            control_plane_canary=True,
            canary_tag="6.3.2001",
            canary_release_id="98765",
            canary_candidate_id=CANDIDATE_ID,
            dispatch_nonce=DISPATCH_NONCE,
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(
            values["checkout_ref"], f"release-candidate/6.3.2001-{CANDIDATE_ID}"
        )
        self.assertEqual(values["candidate_branch"], "")

    def test_simple_job_has_scheme_bound_name_and_integer_json_contract(self) -> None:
        simple = self.jobs["consume-cocoapods-release"]
        self.assertIn("YSIFLYADLibSimple", simple["name"])
        self.assertIn("simple_result_json", simple["outputs"])
        step = next(item for item in simple["steps"] if item.get("id") == "simple-result")
        self.assertEqual(
            step["env"]["RELEASE_ID"],
            "${{ needs.validate-release-assets.outputs.release_id }}",
        )
        assets = self.jobs["validate-release-assets"]
        self.assertEqual(
            assets["outputs"]["release_id"],
            "${{ steps.release-identity.outputs.release_id }}",
        )
        self.assertIn("--release-metadata-output", json.dumps(assets))
        source = step["run"]
        for marker in (
            '"schemaVersion": 1', '"channel": "ys"',
            '"simpleScheme": "YSIFLYADLibSimple"',
            '"artifactInventorySha256"', '"buildResult": "success"',
            '"runId"', 'int(os.environ["RELEASE_ID"])',
        ):
            self.assertIn(marker, source)

    def test_local_python_validation_cannot_dirty_candidate_worktree(self) -> None:
        ignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
        self.assertRegex(ignore, r"(?m)^__pycache__/$")
        self.assertRegex(ignore, r"(?m)^\*\.py\[cod\]$")

    def test_release_concurrency_timeouts_and_summary_are_fail_closed(self) -> None:
        concurrency = self.workflow["concurrency"]
        self.assertIs(concurrency["cancel-in-progress"], False)
        self.assertIn("candidate:{1}:{2}", concurrency["group"])
        self.assertIn("inputs.candidate_id", concurrency["group"])
        self.assertIn("formal:{1}", concurrency["group"])

        expected_timeouts = {
            "resolve-validation-mode": 5,
            "verify-repository": 30,
            "validate-release-assets": 55,
            "consume-swiftpm-release": 55,
            "consume-cocoapods-release": 55,
            "release-summary": 5,
        }
        for job_name, timeout in expected_timeouts.items():
            with self.subTest(job=job_name):
                self.assertEqual(self.jobs[job_name]["timeout-minutes"], timeout)

        summary = self.jobs["release-summary"]
        self.assertEqual(summary["if"], "${{ always() }}")
        self.assertEqual(
            set(summary["needs"]),
            {
                "resolve-validation-mode",
                "verify-repository",
                "validate-release-assets",
                "consume-swiftpm-release",
                "consume-cocoapods-release",
            },
        )
        self.assertEqual(summary["permissions"], {})
        self.assertEqual(len(summary["steps"]), 1)
        script = summary["steps"][0]["run"]
        self.assertIn("GITHUB_STEP_SUMMARY", script)
        self.assertIn("CHECKSUMS_SHA256", script)
        self.assertIn("failure|cancelled|timed_out|action_required", script)
        self.assertNotIn("GITHUB_TOKEN", json.dumps(summary))

    def test_releasing_declares_private_orchestrator_as_only_entry(self) -> None:
        releasing = (ROOT / "RELEASING.md").read_text(encoding="utf-8")
        self.assertIn("## 正式发布唯一入口", releasing)
        self.assertIn("scripts/release-orchestrator.py", releasing)
        self.assertIn("底层门禁或故障诊断入口", releasing)

    def test_candidate_uses_final_formal_manifest_checksum_and_provenance(self) -> None:
        repository_steps = self.jobs["verify-repository"]["steps"]
        contract = next(step for step in repository_steps if step.get("id") == "release-contract")
        self.assertIn("最终 FORMAL 清单", contract["name"])

        compare = next(
            step
            for step in repository_steps
            if step.get("name")
            == "Candidate/正式态校验 A/B 私有源码祖先关系与 B 变更范围"
        )
        self.assertIn("mode != 'repository'", compare["if"])

        asset_contract = next(
            step
            for step in self.jobs["validate-release-assets"]["steps"]
            if step.get("id") == "asset-contract"
        )
        self.assertIn("Draft/正式清单 checksum 必须等于本次下载资产", asset_contract["run"])
        self.assertNotIn("expected_pending", asset_contract["run"])

    def test_machine_and_document_contracts_are_blocking(self) -> None:
        machine = next(
            step for step in self.jobs["verify-repository"]["steps"]
            if step.get("name") == "阻断校验版本、checksum 与本地包机器契约"
        )
        self.assertNotIn("continue-on-error", machine)
        self.assertIn(".github/scripts/verify_repository_contract.py", machine["run"])
        self.assertIn("--scope machine", machine["run"])
        self.assertIn("--podspec-json", machine["run"])
        self.assertNotIn("python3 - +", machine["run"])
        documentation = next(
            step for step in self.jobs["verify-repository"]["steps"]
            if step.get("name") == "阻断校验 Markdown 发布状态契约"
        )
        self.assertNotIn("continue-on-error", documentation)
        self.assertIn("--scope docs", documentation["run"])
        self.assertEqual(self.source.count("continue-on-error: true"), 0)
        contract = next(
            step for step in self.jobs["verify-repository"]["steps"]
            if step.get("id") == "release-contract"
        )
        self.assertIn("validate_release_mode.py", contract["run"])
        compare = next(
            step for step in self.jobs["verify-repository"]["steps"]
            if step.get("name") == "Candidate/正式态校验 A/B 私有源码祖先关系与 B 变更范围"
        )
        self.assertIn('Path("release-state.json")', compare["run"])
        self.assertNotIn('Path("RELEASING.md")', compare["run"])

    def test_docs_drift_is_isolated_but_checksum_drift_fails_machine_scope(self) -> None:
        original_read = REPOSITORY_CONTRACT.read
        repository_version = MODE.read_local_contract(ROOT)["version"]
        checked_in_state = json.loads(original_read(ROOT, "release-state.json"))
        release_kind = (
            "draft_candidate"
            if checked_in_state["phase"] == "FROZEN"
            else "repository"
        )
        REPOSITORY_CONTRACT.verify_docs(ROOT, release_kind)

        def docs_drift(root: Path, relative: str) -> str:
            value = original_read(root, relative)
            if relative == "README.md":
                return value.replace(
                    "<!-- ifly-release-status:",
                    "<!-- removed-release-status:",
                    1,
                )
            return value

        with mock.patch.object(REPOSITORY_CONTRACT, "read", side_effect=docs_drift):
            REPOSITORY_CONTRACT.verify_machine(
                ROOT, release_kind, self.podspec_json
            )
            with self.assertRaises(REPOSITORY_CONTRACT.ContractError):
                REPOSITORY_CONTRACT.verify_docs(ROOT, release_kind)

        for invalid_checksum in (
            "not-a-checksum",
            "0" * 64,
            "2c2d14bc635ae4fe9784934ea93b039c03c2d244449fff74f3857fff7b35bbdd",
        ):
            def checksum_drift(root: Path, relative: str) -> str:
                value = original_read(root, relative)
                if relative == "Package.swift":
                    return re.sub(
                        r'checksum:\s*"[0-9a-f]{64}"',
                        f'checksum: "{invalid_checksum}"',
                        value,
                        count=1,
                    )
                return value

            with self.subTest(checksum=invalid_checksum), mock.patch.object(
                REPOSITORY_CONTRACT, "read", side_effect=checksum_drift
            ), self.assertRaises(REPOSITORY_CONTRACT.ContractError):
                REPOSITORY_CONTRACT.verify_machine(
                    ROOT, release_kind, self.podspec_json
                )

        def version_drift(root: Path, relative: str) -> str:
            value = original_read(root, relative)
            if relative == "YSIFLYADLib.podspec":
                return re.sub(
                    rf"(s\.version\s*=\s*['\"]){re.escape(repository_version)}",
                    r"\g<1>99.0.0",
                    value,
                    count=1,
                )
            return value

        with mock.patch.object(REPOSITORY_CONTRACT, "read", side_effect=version_drift):
            with self.assertRaises(REPOSITORY_CONTRACT.ContractError):
                REPOSITORY_CONTRACT.verify_machine(
                    ROOT, release_kind, self.podspec_json
                )

    def test_repository_contract_keeps_only_previous_or_current_closed_state(self) -> None:
        original_read = REPOSITORY_CONTRACT.read
        repository_version = MODE.read_local_contract(ROOT)["version"]
        closed = json.loads(original_read(ROOT, "release-state.json"))
        closed["phase"] = "CLOSED"

        def with_version(version: str):
            def read(root: Path, relative: str) -> str:
                if relative == "release-state.json":
                    return json.dumps({**closed, "version": version})
                value = original_read(root, relative)
                if relative in {
                    "Package.swift",
                    "YSIFLYADLib.podspec",
                    "YSIFLYADLibSimple/Podfile",
                }:
                    return value.replace(repository_version, version)
                return value

            return read

        for version in (CLOSED_VERSION, VERSION):
            with self.subTest(version=version), mock.patch.object(
                REPOSITORY_CONTRACT, "read", side_effect=with_version(version)
            ):
                REPOSITORY_CONTRACT.verify_machine(ROOT, "repository", self.podspec_json)

        if VERSION != CLOSED_VERSION:
            def target_state_with_closed_assets(
                root: Path, relative: str
            ) -> str:
                if relative == "release-state.json":
                    return json.dumps({**closed, "version": VERSION})
                value = original_read(root, relative)
                if relative in {
                    "Package.swift",
                    "YSIFLYADLib.podspec",
                    "YSIFLYADLibSimple/Podfile",
                }:
                    return value.replace(repository_version, CLOSED_VERSION)
                return value

            with mock.patch.object(
                REPOSITORY_CONTRACT,
                "read",
                side_effect=target_state_with_closed_assets,
            ), self.assertRaises(REPOSITORY_CONTRACT.ContractError):
                REPOSITORY_CONTRACT.verify_machine(
                    ROOT, "repository", self.podspec_json
                )

        for version in ("0.0.0", "99.0.0"):
            with self.subTest(version=version), mock.patch.object(
                REPOSITORY_CONTRACT, "read", side_effect=with_version(version)
            ), self.assertRaises(REPOSITORY_CONTRACT.ContractError):
                REPOSITORY_CONTRACT.verify_machine(ROOT, "repository", self.podspec_json)

    def test_release_contracts_accept_only_current_frozen_state(self) -> None:
        original_read = REPOSITORY_CONTRACT.read
        repository_version = MODE.read_local_contract(ROOT)["version"]
        frozen = json.loads(original_read(ROOT, "release-state.json"))
        frozen.update({
            "version": CANDIDATE_VERSION,
            "phase": "FROZEN",
            "publication": None,
        })

        def with_state(
            value: dict[str, object], version: str = CANDIDATE_VERSION
        ):
            def read(root: Path, relative: str) -> str:
                if relative == ".github/scripts/release-control.json":
                    return json.dumps({
                        **RELEASE_CONTROL,
                        "state": "CANDIDATE",
                        "targetVersion": CANDIDATE_VERSION,
                    })
                if relative == "release-state.json":
                    return json.dumps(value)
                content = original_read(root, relative)
                if relative in {
                    "Package.swift",
                    "YSIFLYADLib.podspec",
                    "YSIFLYADLibSimple/Podfile",
                    "README.md",
                    "CHANGELOG.md",
                    "RELEASING.md",
                    "YSIFLYADLibSimple/README.md",
                }:
                    return content.replace(repository_version, version)
                return content

            return read

        for release_kind in ("draft_candidate", "formal_release"):
            with self.subTest(release_kind=release_kind), mock.patch.object(
                REPOSITORY_CONTRACT, "read", side_effect=with_state(frozen)
            ):
                REPOSITORY_CONTRACT.verify_machine(
                    ROOT, release_kind, self.podspec_json
                )
                REPOSITORY_CONTRACT.verify_docs(ROOT, release_kind)

            for invalid in (
                {**frozen, "version": CLOSED_VERSION},
                *(
                    {**frozen, "phase": phase}
                    for phase in ("PREPARING", "PUBLISHED", "VERIFIED", "CLOSED")
                ),
            ):
                with self.subTest(
                    release_kind=release_kind, state=invalid
                ), mock.patch.object(
                    REPOSITORY_CONTRACT, "read", side_effect=with_state(invalid)
                ), self.assertRaises(REPOSITORY_CONTRACT.ContractError):
                    REPOSITORY_CONTRACT.verify_machine(
                        ROOT, release_kind, self.podspec_json
                    )

            with mock.patch.object(
                REPOSITORY_CONTRACT,
                "read",
                side_effect=with_state(frozen, CLOSED_VERSION),
            ), self.assertRaises(REPOSITORY_CONTRACT.ContractError):
                REPOSITORY_CONTRACT.verify_machine(
                    ROOT, release_kind, self.podspec_json
                )

    def test_podspec_comments_cannot_substitute_for_parsed_link_contract(self) -> None:
        podspec_source = (ROOT / "YSIFLYADLib.podspec").read_text(encoding="utf-8")
        for marker in ("AdSupport", "AppTrackingTransparency", "-ObjC"):
            self.assertIn(marker, podspec_source)
        checked_in_state = json.loads(
            (ROOT / "release-state.json").read_text(encoding="utf-8")
        )
        release_kind = (
            "draft_candidate"
            if checked_in_state["phase"] == "FROZEN"
            else "repository"
        )
        parsed = json.loads(self.podspec_json.read_text(encoding="utf-8"))
        mutations = (
            (
                "frameworks",
                lambda value: value.__setitem__("frameworks", []),
                "podspec JSON 缺少 AdSupport 强链接声明",
            ),
            (
                "weak_frameworks",
                lambda value: value.__setitem__("weak_frameworks", []),
                "podspec JSON 缺少 AppTrackingTransparency 弱链接声明",
            ),
            (
                "pod_target_xcconfig",
                lambda value: value.__setitem__(
                    "pod_target_xcconfig", {"OTHER_LDFLAGS": "$(inherited)"}
                ),
                "podspec JSON pod_target_xcconfig.OTHER_LDFLAGS 缺少 -ObjC",
            ),
            (
                "user_target_xcconfig",
                lambda value: value.__setitem__(
                    "user_target_xcconfig", {"OTHER_LDFLAGS": "$(inherited)"}
                ),
                "podspec JSON user_target_xcconfig.OTHER_LDFLAGS 缺少 -ObjC",
            ),
        )
        with tempfile.TemporaryDirectory(prefix="ys-bad-podspec-json-") as directory:
            bad_path = Path(directory) / "podspec.json"
            for label, mutate, expected_error in mutations:
                with self.subTest(field=label):
                    bad = copy.deepcopy(parsed)
                    mutate(bad)
                    bad_path.write_text(json.dumps(bad), encoding="utf-8")
                    with self.assertRaisesRegex(
                        REPOSITORY_CONTRACT.ContractError,
                        re.escape(expected_error),
                    ):
                        REPOSITORY_CONTRACT.verify_machine(
                            ROOT, release_kind, bad_path
                        )

    def test_asset_gate_fans_out_to_parallel_isolated_consumers(self) -> None:
        swift = self.jobs["consume-swiftpm-release"]
        pods = self.jobs["consume-cocoapods-release"]
        for job in (swift, pods):
            self.assertIn("validate-release-assets", job["needs"])
            self.assertIn("verify-repository", job["needs"])
        self.assertNotIn("consume-cocoapods-release", swift["needs"])
        self.assertNotIn("consume-swiftpm-release", pods["needs"])
        self.assertIn("正式首次 SwiftPM 消费前显式清空缓存", self.source)
        self.assertIn("正式首次 CocoaPods 消费前显式清空缓存", self.source)
        self.assertIn(
            "ys-release-assets-${{ needs.verify-repository.outputs.candidate_identity }}-"
            "${{ github.run_id }}-${{ github.run_attempt }}",
            self.source,
        )
        asset_gate = self.jobs["validate-release-assets"]
        upload = next(
            step
            for step in asset_gate["steps"]
            if step.get("uses") == "actions/upload-artifact@v4"
        )
        self.assertIn("formal_release", upload["if"])
        self.assertEqual(
            set(asset_gate["outputs"]),
            {"spm_sha256", "combined_sha256", "checksums_sha256", "release_id"},
        )
        for job in (swift, pods):
            download = next(
                step
                for step in job["steps"]
                if step.get("uses") == "actions/download-artifact@v4"
            )
            self.assertIn("formal_release", download["if"])
            self.assertTrue(
                any(
                    "draft_candidate" in step.get("if", "")
                    and "GITHUB_TOKEN" in step.get("env", {})
                    for step in job["steps"]
                )
            )
            self.assertIn("EXPECTED_SPM_SHA256", job["env"])

    def test_job_level_env_does_not_use_runner_context(self) -> None:
        for job_name, job in self.jobs.items():
            for key, value in (job.get("env") or {}).items():
                with self.subTest(job=job_name, key=key):
                    self.assertNotIn("${{ runner.", str(value))
        fixture = self.jobs["consume-cocoapods-release"]["env"][
            "COCOAPODS_FIXTURE"
        ]
        self.assertEqual(
            fixture,
            "${{ github.workspace }}/.candidate-cocoapods-fixture",
        )

    def test_control_scripts_are_pinned_to_workflow_commit_not_release_tag(self) -> None:
        non_canary_jobs = {
            name: job for name, job in self.jobs.items() if name != "control-plane-canary"
        }
        self.assertNotIn("python3 .github/scripts/", json.dumps(non_canary_jobs))
        expected_control_files = (
            ".github/scripts/validate_release_mode.py",
            ".github/scripts/download_release_assets.py",
            ".github/scripts/prepare_cocoapods_fixture.py",
            ".github/scripts/verify_repository_contract.py",
            ".github/fixtures/swiftpm-local/Package.swift",
        )
        for path in expected_control_files:
            self.assertIn(f'${{WORKFLOW_CONTROL_SHA}}:{path}', self.source)

        for job_name in (
            "verify-repository",
            "validate-release-assets",
            "consume-swiftpm-release",
            "consume-cocoapods-release",
        ):
            job = self.jobs[job_name]
            self.assertEqual(job["env"]["WORKFLOW_CONTROL_SHA"], "${{ github.workflow_sha }}")
            checkouts = [
                step
                for step in job["steps"]
                if step.get("uses") == "actions/checkout@v4"
            ]
            self.assertGreater(len(checkouts), 0)
            for checkout in checkouts:
                self.assertEqual(checkout["with"]["fetch-depth"], 0)

        verification_steps = self.jobs["verify-repository"]["steps"]
        self.assertEqual(
            verification_steps[0]["with"]["ref"], "${{ github.workflow_sha }}"
        )
        self.assertIn(
            "python3 -B -m unittest discover",
            verification_steps[1]["run"],
        )

        old_tag_files = subprocess.check_output(
            ["git", "-C", str(ROOT), "ls-tree", "-r", "--name-only", "6.2.2", ".github"],
            text=True,
        ).splitlines()
        self.assertNotIn(".github/scripts/validate_release_mode.py", old_tag_files)
        self.assertNotIn(".github/scripts/download_release_assets.py", old_tag_files)

    def test_release_tag_and_exact_id_infer_formal_and_conflicts_fail_closed(self) -> None:
        validation_input = self.workflow["true"]["workflow_dispatch"]["inputs"][
            "validation_mode"
        ]
        self.assertEqual(validation_input["default"], "repository")
        self.assertIs(validation_input["required"], False)
        self.assertIn("repository", validation_input["options"])

        for requested_mode in ("", "repository"):
            with self.subTest(requested_mode=requested_mode):
                result, values = self.run_resolver(
                    requested_mode=requested_mode,
                    release_tag=VERSION,
                    formal_release_id="12345",
                )
                self.assertEqual(result.returncode, 0, result.stdout)
                self.assertEqual(values["mode"], "formal_release")
                self.assertEqual(values["checkout_ref"], VERSION)
                self.assertEqual(values["release_tag"], VERSION)
                self.assertEqual(values["formal_release_id"], "12345")

        result, values = self.run_resolver(requested_mode="repository")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(values["mode"], "repository")
        self.assertEqual(values["checkout_ref"], "refs/heads/main")

        for label, parameters in (
            (
                "repository 混入 candidate",
                {"requested_mode": "repository", "candidate_release_id": "123"},
            ),
            (
                "draft 混入 release_tag",
                {
                    "requested_mode": "draft_candidate",
                    "release_tag": VERSION,
                    "candidate_release_id": "123",
                },
            ),
            (
                "formal 缺少 release_tag",
                {"requested_mode": "formal_release"},
            ),
        ):
            with self.subTest(label=label):
                result, _ = self.run_resolver(**parameters)
                self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_push_and_pull_request_resolve_to_repository_without_asset_access(self) -> None:
        resolver = self.jobs["resolve-validation-mode"]["steps"][0]["run"]
        result, values = self.run_resolver(
            event_name="push",
            event_ref="refs/heads/main",
            requested_mode="",
        )
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(values["mode"], "repository")
        asset_condition = self.jobs["validate-release-assets"]["if"]
        self.assertIn("mode != 'repository'", asset_condition)
        self.assertIn("draft candidate 只允许从", resolver)


if __name__ == "__main__":
    unittest.main()
