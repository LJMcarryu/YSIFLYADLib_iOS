from __future__ import annotations

import contextlib
import copy
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import release_state  # noqa: E402


CLOSED_ARTIFACTS = [
    {"name": "checksums.txt", "contentSha256": "1f4f08237327dabbb7c90be7c980f731d6d1925f189ae6904dc04a75c0076142"},
    {"name": "YSIFLYADLib-6.2.4.zip", "contentSha256": "bce3bd4ea143fdc06a4c9c648f305fe5534752eeed2d134c0bbc8709a17806ec"},
    {"name": "YSIFLYADLib.xcframework.zip", "contentSha256": "76082025635bd2e427c09c5d1427c253db93ab75f897ed7a6e11024f6bcf4c7e"},
]
CLOSED_STATE = {
    "schemaVersion": 1,
    "channel": "ys",
    "repository": "LJMcarryu/YSIFLYADLib_iOS",
    "version": "6.2.4",
    "phase": "CLOSED",
    "binarySourceCommit": "b0f745d582ce2bed5110702cff972be4153e5038",
    "releaseMetadataCommit": "7b08118b43a0c4441de4c76a64f34fa54b3fe889",
    "artifactInventory": {
        "count": 3,
        "sha256": "b0962e8e1129f680024fef53365802aa6797e6c163f8b7be18e4e9cec1020cf4",
    },
    "appleReview": {
        "requiredForRelease": False,
        "statusAtFreeze": "not-run",
        "evidenceIncluded": False,
    },
    "publication": {
        "releaseId": 371715388,
        "tagName": "6.2.4",
        "tagObjectSha": "1659ae3f8d0d12e9bd7830a919ea15be6655d6ae",
        "tagCommitSha": "43b6eadeb3431e5bceb0befd4610f9cb7313b3b6",
        "releaseUrl": "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.4",
        "publishedAt": "2026-08-17T11:54:50Z",
        "formalConsumerRunId": 32027223627,
        "formalConsumerRunUrl": (
            "https://github.com/LJMcarryu/YSIFLYADLib_iOS/actions/runs/32027223627"
        ),
        "conclusion": "success",
        "verifiedAt": "2026-08-17T12:00:10Z",
    },
}
FROZEN_ARTIFACTS = [
    {"name": "checksums.txt", "contentSha256": "4e742cea449d0289df852ada89b5da5bbd0e79f24bbb0d1a124314a08a2ce196"},
    {"name": "YSIFLYADLib-6.3.0.zip", "contentSha256": "d0fdc4d0077deaf53aa85efeefa8fae9fb96cf5db831dd4145ad9d8096c63e9e"},
    {"name": "YSIFLYADLib.xcframework.zip", "contentSha256": "73a1e82ffee9c01d63f1e6a391c732e8837c422d23ab60846c92e8f2c167ad08"},
]
FROZEN_INVENTORY = {
    "count": 3,
    "sha256": "3da306fb95a7d6a8b839c7638614595a7820f296a8239374297c7d820c3c26a0",
}
APPLE_REVIEW = {
    "requiredForRelease": False,
    "statusAtFreeze": "not-run",
    "evidenceIncluded": False,
}


class ReleaseStateTests(unittest.TestCase):
    def setUp(self) -> None:
        # CLOSED 生成与迁移单测必须使用不可变历史夹具，不能让候选分支中
        # 合法变为 6.3.0/FROZEN 的实时 release-state 污染历史事实。
        self.state = copy.deepcopy(CLOSED_STATE)
        self.closed_facts = {
            key: copy.deepcopy(value)
            for key, value in self.state.items()
            if key != "artifactInventory"
        }
        self.closed_facts["artifacts"] = copy.deepcopy(CLOSED_ARTIFACTS)
        self.frozen_facts = {
            "schemaVersion": 1,
            "channel": "ys",
            "repository": "LJMcarryu/YSIFLYADLib_iOS",
            "version": "6.3.0",
            "phase": "FROZEN",
            "binarySourceCommit": "38eb0715f889fe2d585641891923511c9cc3e43e",
            "releaseMetadataCommit": "0e667f9f1a2d615d3f7e15a552f093c903ff1a57",
            "artifacts": copy.deepcopy(FROZEN_ARTIFACTS),
            "appleReview": copy.deepcopy(APPLE_REVIEW),
        }

    @staticmethod
    def write_facts(directory: Path, facts: dict[str, object]) -> Path:
        path = directory / "facts.json"
        path.write_text(json.dumps(facts), encoding="utf-8")
        return path

    def test_closed_fixture_is_rebuilt_exactly_from_content_digests(self) -> None:
        generated = release_state.build_closed_state(self.closed_facts)
        self.assertEqual(generated, self.state)
        self.assertEqual(self.state["version"], "6.2.4")
        self.assertEqual(self.state["phase"], "CLOSED")
        self.assertEqual(
            release_state.canonical_json(generated),
            release_state.canonical_json(self.state),
        )

    def test_current_repository_state_is_independently_valid(self) -> None:
        current = json.loads(
            (ROOT / "release-state.json").read_text(encoding="utf-8")
        )
        self.assertEqual(
            release_state.validate_state(
                current,
                expected_channel="ys",
                expected_repository="LJMcarryu/YSIFLYADLib_iOS",
            ),
            current,
        )

    def test_orchestrated_630_frozen_facts_build_exact_inventory(self) -> None:
        frozen = release_state.build_frozen_state(self.frozen_facts)
        self.assertEqual(frozen["version"], "6.3.0")
        self.assertEqual(frozen["phase"], "FROZEN")
        self.assertIsNone(frozen["publication"])
        self.assertEqual(frozen["artifactInventory"], FROZEN_INVENTORY)

    def test_dry_run_prints_closed_state_without_writing(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "release-state.json"
            target.write_text("原内容\n", encoding="utf-8")
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                result = release_state.main([
                    str(target), "--facts",
                    str(self.write_facts(root, self.closed_facts)),
                ])
            self.assertEqual(result, 0)
            self.assertEqual(target.read_text(encoding="utf-8"), "原内容\n")
            self.assertEqual(json.loads(output.getvalue()), self.state)

    def test_write_atomically_generates_closed_state(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "release-state.json"
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                result = release_state.main([
                    str(target), "--facts",
                    str(self.write_facts(root, self.closed_facts)), "--write",
                    "--expected-channel", "ys",
                    "--expected-repository", "LJMcarryu/YSIFLYADLib_iOS",
                    "--expected-version", "6.2.4",
                ])
            self.assertEqual(result, 0)
            self.assertEqual(
                target.read_text(encoding="utf-8"),
                release_state.canonical_json(self.state),
            )

    def test_rejects_extra_facts_fields(self) -> None:
        for mutate in (
            lambda value: value.update({"unexpected": True}),
            lambda value: value["artifacts"][0].update({"size": 1}),
        ):
            value = copy.deepcopy(self.closed_facts)
            mutate(value)
            with self.assertRaises(release_state.ReleaseStateError):
                release_state.build_closed_state(value)

    def test_rejects_non_closed_failure_and_fake_apple_success(self) -> None:
        for mutate in (
            lambda value: value.update({"phase": "VERIFIED"}),
            lambda value: value["publication"].update({"conclusion": "failure"}),
            lambda value: value["appleReview"].update({"statusAtFreeze": "success"}),
            lambda value: value["publication"].update({"releaseId": "371715388"}),
        ):
            value = copy.deepcopy(self.closed_facts)
            mutate(value)
            with self.assertRaises(release_state.ReleaseStateError):
                release_state.build_closed_state(value)

    def test_failed_replace_preserves_original_and_removes_temporary_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "release-state.json"
            target.write_text("不可破坏的原状态\n", encoding="utf-8")
            with mock.patch.object(release_state.os, "replace", side_effect=OSError("失败")):
                with self.assertRaises(OSError):
                    release_state.atomic_write_state(target, self.state)
            self.assertEqual(target.read_text(encoding="utf-8"), "不可破坏的原状态\n")
            self.assertEqual(list(root.glob(".release-state.json.*.tmp")), [])

    def test_freeze_facts_reject_publication_field(self) -> None:
        facts = copy.deepcopy(self.frozen_facts)
        facts["publication"] = None
        with self.assertRaises(release_state.ReleaseStateError):
            release_state.build_frozen_state(facts)

    def test_phase_specific_publication_and_transition_contract(self) -> None:
        frozen = release_state.build_frozen_state(self.frozen_facts)
        release_state.validate_state_transition(self.state, frozen)

        preparing = copy.deepcopy(frozen)
        preparing["phase"] = "PREPARING"
        release_state.validate_state_transition(preparing, frozen)

        closed = copy.deepcopy(frozen)
        closed["phase"] = "CLOSED"
        closed["publication"] = {
            "releaseId": 1,
            "tagName": "6.3.0",
            "tagObjectSha": "c" * 40,
            "tagCommitSha": "d" * 40,
            "releaseUrl": "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.0",
            "publishedAt": "2026-08-25T00:00:00Z",
            "formalConsumerRunId": 2,
            "formalConsumerRunUrl": "https://github.com/LJMcarryu/YSIFLYADLib_iOS/actions/runs/2",
            "conclusion": "success",
            "verifiedAt": "2026-08-25T00:01:00Z",
        }
        release_state.validate_state_transition(frozen, closed)

        invalid_publication = copy.deepcopy(frozen)
        invalid_publication["publication"] = {}
        with self.assertRaises(release_state.ReleaseStateError):
            release_state.validate_state(invalid_publication)

        same_version_frozen = copy.deepcopy(frozen)
        same_version_frozen["version"] = "6.2.4"
        with self.assertRaises(release_state.ReleaseStateError):
            release_state.validate_state_transition(self.state, same_version_frozen)

        with self.assertRaises(release_state.ReleaseStateError):
            release_state.validate_state_transition(self.state, closed)


if __name__ == "__main__":
    unittest.main()
