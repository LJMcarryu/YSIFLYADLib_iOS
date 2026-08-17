#!/usr/bin/env python3
"""校验 YS 发布工作流模式、checkout 身份和本地发布契约。"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


SHA40 = re.compile(r"^[0-9a-f]{40}$")
SHA32 = re.compile(r"^[0-9a-f]{32}$")
SHA64 = re.compile(r"^[0-9a-f]{64}$")
VERSION = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
MODES = ("repository", "draft_candidate", "formal_release")


class ContractError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def git(root: Path, *arguments: str) -> str:
    return subprocess.run(
        ["git", "-C", str(root), *arguments],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ).stdout.strip()


def single_match(pattern: str, contents: str, label: str) -> str:
    matches = re.findall(pattern, contents, re.MULTILINE)
    require(len(matches) == 1, f"{label} 声明数量必须为 1，实际 {matches}")
    return matches[0]


def pending_values(version: str) -> dict[str, str]:
    marker = version.replace(".", "_")
    return {
        "checksum": f"__YSIFLYADLIB_{marker}_SWIFTPM_CHECKSUM_PENDING__",
        "binary": f"__YSIFLYADLIB_{marker}_BINARY_SOURCE_COMMIT_PENDING__",
        "metadata": f"__YSIFLYADLIB_{marker}_RELEASE_METADATA_COMMIT_PENDING__",
    }


def read_local_contract(root: Path) -> dict[str, str]:
    package = (root / "Package.swift").read_text(encoding="utf-8")
    podspec = (root / "YSIFLYADLib.podspec").read_text(encoding="utf-8")
    sys.path.insert(0, str(root / "scripts"))
    from release_state import validate_state

    state = validate_state(
        json.loads((root / "release-state.json").read_text(encoding="utf-8")),
        expected_channel="ys",
        expected_repository="LJMcarryu/YSIFLYADLib_iOS",
    )
    version = single_match(
        r"s\.version\s*=\s*['\"]([^'\"]+)", podspec, "podspec version"
    )
    require(VERSION.fullmatch(version) is not None, f"版本格式非法: {version!r}")
    expected_package_url = (
        "https://github.com/LJMcarryu/YSIFLYADLib_iOS/"
        f"releases/download/{version}/YSIFLYADLib.xcframework.zip"
    )
    package_urls = re.findall(
        r'url:\s*"([^"]*YSIFLYADLib\.xcframework\.zip)"', package
    )
    require(
        package_urls == [expected_package_url],
        f"Package.swift 二进制 URL 不精确: {package_urls}",
    )
    expected_pod_url = (
        "https://github.com/LJMcarryu/YSIFLYADLib_iOS/"
        f"releases/download/{version}/YSIFLYADLib-{version}.zip"
    )
    pod_urls = re.findall(
        r"s\.source\s*=\s*\{\s*:http\s*=>\s*['\"]([^'\"]+)['\"]",
        podspec,
    )
    require(
        pod_urls == [expected_pod_url],
        f"podspec 二进制 URL 不精确: {pod_urls}",
    )
    return {
        "version": version,
        "state_version": state["version"],
        "checksum": single_match(
            r'checksum:\s*"([^"]+)"', package, "Package.swift checksum"
        ),
        "release_state": "PENDING" if state["phase"] == "PREPARING" else "FORMAL",
        "phase": state["phase"],
        "binary_source_commit": state["binarySourceCommit"],
        "release_metadata_commit": state["releaseMetadataCommit"],
    }


def validate_pending(contract: dict[str, str]) -> None:
    expected = pending_values(contract["version"])
    require(contract["phase"] == "PREPARING", "准备态必须来自 release-state PREPARING")
    require(contract["checksum"] == expected["checksum"], "PENDING checksum 不精确")
    require(
        SHA40.fullmatch(contract["binary_source_commit"]) is not None,
        "release-state binarySourceCommit 非 40 位 SHA",
    )
    require(
        SHA40.fullmatch(contract["release_metadata_commit"]) is not None
        and contract["release_metadata_commit"] != contract["binary_source_commit"],
        "release-state A/B 必须是两个不同的 40 位 SHA",
    )


def validate_formal(contract: dict[str, str]) -> None:
    require(
        contract["phase"] in {"FROZEN", "PUBLISHED", "VERIFIED", "CLOSED"},
        "draft candidate 与正式复验必须来自 release-state FROZEN 或后续阶段",
    )
    require(
        SHA64.fullmatch(contract["checksum"]) is not None,
        "最终 FORMAL checksum 非 SHA-256",
    )
    binary = contract["binary_source_commit"]
    metadata = contract["release_metadata_commit"]
    require(
        SHA40.fullmatch(binary) is not None,
        "最终 FORMAL binarySourceCommit 非 40 位 SHA",
    )
    require(
        SHA40.fullmatch(metadata) is not None,
        "最终 FORMAL releaseMetadataCommit 非 40 位 SHA",
    )
    require(binary != metadata, "最终 FORMAL A/B provenance 必须是两个不同提交")


def version_tuple(value: str) -> tuple[int, int, int]:
    require(VERSION.fullmatch(value) is not None, f"版本格式非法: {value!r}")
    return tuple(int(part) for part in value.split("."))  # type: ignore[return-value]


def validate_contract(arguments: argparse.Namespace) -> dict[str, str]:
    root = arguments.root.resolve()
    contract = read_local_contract(root)
    head = git(root, "rev-parse", "HEAD")
    require(SHA40.fullmatch(head) is not None, f"checkout commit 非 40 位 SHA: {head}")
    require(not git(root, "status", "--porcelain"), "发布验证 checkout 必须干净")

    mode = arguments.mode
    require(mode in MODES, f"未知验证模式: {mode}")
    require(
        re.fullmatch(r"[^/\s]+/[^/\s]+", arguments.repository) is not None,
        "仓库名必须为 owner/name",
    )
    if mode != "repository":
        require(
            arguments.repository == "LJMcarryu/YSIFLYADLib_iOS",
            "Release 资产验证只允许官方同仓运行",
        )
    release_tag = arguments.release_tag.strip()
    candidate_release_id = arguments.candidate_release_id.strip()
    candidate_id = arguments.candidate_id.strip()
    candidate_branch = arguments.candidate_branch.strip()
    dispatch_nonce = arguments.dispatch_nonce.strip()

    if mode == "draft_candidate":
        require(arguments.event_name == "workflow_dispatch", "draft candidate 仅允许手动触发")
        require(arguments.event_ref_type == "branch", "draft candidate 触发 ref 必须是分支")
        require(not release_tag, "draft candidate 不得同时提供 release_tag")
        require(
            re.fullmatch(r"[1-9][0-9]*", candidate_release_id) is not None,
            "draft candidate 必须提供十进制 candidate_release_id",
        )
        require(SHA64.fullmatch(candidate_id) is not None, "candidate_id 必须是 64 位小写十六进制")
        require(SHA32.fullmatch(dispatch_nonce) is not None, "dispatch_nonce 必须是 32 位小写十六进制")
        expected_branch = f"release-candidate/{contract['version']}-{candidate_id}"
        require(candidate_branch == expected_branch, "候选分支输入与版本/candidate_id 不一致")
        require(
            arguments.event_ref == f"refs/heads/{expected_branch}",
            f"draft candidate 只允许从 {expected_branch} 触发",
        )
        require(arguments.event_ref_name == expected_branch, "github.ref_name 与候选分支不一致")
        require(SHA40.fullmatch(arguments.event_sha) is not None, "github.sha 非 40 位小写 SHA")
        require(
            contract["state_version"] == contract["version"],
            "draft candidate release-state 版本与分发清单不一致",
        )
        require(
            contract["phase"] == "FROZEN",
            "draft candidate 只允许 release-state FROZEN",
        )
        validate_formal(contract)
        require(head == arguments.event_sha, f"candidate checkout={head}，event sha={arguments.event_sha}")
        checkout_ref = expected_branch
        release_locator = "\0".join(
            (candidate_release_id, candidate_id, dispatch_nonce, expected_branch)
        )
    elif mode == "formal_release":
        require(
            arguments.event_name in {"release", "workflow_dispatch"},
            "正式 Release 复验仅允许 release published 或手动触发",
        )
        require(not candidate_release_id, "正式复验不得提供 candidate_release_id")
        require(not candidate_id, "正式复验不得提供 candidate_id")
        require(not candidate_branch, "正式复验不得提供 candidate_branch")
        require(not dispatch_nonce, "正式复验不得提供 dispatch_nonce")
        require(VERSION.fullmatch(release_tag) is not None, "正式复验必须提供 x.y.z release_tag")
        if arguments.event_name == "release":
            require(arguments.event_ref_type == "tag", "release published 的 ref 必须是 tag")
            require(
                arguments.event_ref == f"refs/tags/{release_tag}",
                "release published 事件 ref 与 release_tag 不一致",
            )
        require(release_tag == contract["version"], "release_tag 与本地版本不一致")
        require(
            contract["state_version"] == contract["version"],
            "正式复验 release-state 版本与分发清单不一致",
        )
        require(
            contract["phase"] == "FROZEN",
            "正式复验只允许 release-state FROZEN",
        )
        validate_formal(contract)
        tag_ref = f"refs/tags/{release_tag}"
        require(git(root, "cat-file", "-t", tag_ref) == "tag", "正式 tag 必须是 annotated tag")
        tag_commit = git(root, "rev-parse", f"{tag_ref}^{{}}")
        require(head == tag_commit, f"checkout={head}，annotated tag commit={tag_commit}")
        checkout_ref = release_tag
        release_locator = release_tag
    else:
        require(not release_tag, "repository 模式不得提供 release_tag")
        require(
            not candidate_release_id,
            "repository 模式不得提供 candidate_release_id",
        )
        require(not candidate_id, "repository 模式不得提供 candidate_id")
        require(not candidate_branch, "repository 模式不得提供 candidate_branch")
        require(not dispatch_nonce, "repository 模式不得提供 dispatch_nonce")
        if contract["phase"] == "CLOSED" and (
            contract["state_version"] != contract["version"]
        ):
            require(
                version_tuple(contract["state_version"])
                < version_tuple(contract["version"]),
                "main 上一 CLOSED 版本必须低于当前分发基线",
            )
            validate_formal(contract)
        elif contract["release_state"] == "PENDING":
            require(
                contract["state_version"] == contract["version"],
                "PREPARING release-state 版本与分发清单不一致",
            )
            validate_pending(contract)
        else:
            require(
                contract["state_version"] == contract["version"],
                "FORMAL release-state 版本与分发清单不一致",
            )
            validate_formal(contract)
        checkout_ref = arguments.event_ref
        release_locator = ""

    identity_material = "\0".join(
        (
            arguments.repository,
            mode,
            contract["version"],
            release_locator,
            head,
        )
    )
    identity = hashlib.sha256(identity_material.encode("utf-8")).hexdigest()
    return {
        "mode": mode,
        "version": contract["version"],
        "release_state": contract["release_state"],
        "release_tag": release_tag,
        "candidate_release_id": candidate_release_id,
        "candidate_id": candidate_id,
        "candidate_branch": candidate_branch,
        "dispatch_nonce": dispatch_nonce,
        "checkout_ref": checkout_ref,
        "checkout_commit": head,
        "candidate_identity": identity,
    }


def write_github_output(path: Path, values: dict[str, str]) -> None:
    with path.open("a", encoding="utf-8") as output:
        for key, value in values.items():
            require("\n" not in value and "\r" not in value, f"输出 {key} 含换行")
            output.write(f"{key}={value}\n")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    result.add_argument("--root", type=Path, default=Path.cwd())
    result.add_argument("--mode", required=True, choices=MODES)
    result.add_argument("--event-name", required=True)
    result.add_argument("--event-ref", required=True)
    result.add_argument("--event-ref-name", default="")
    result.add_argument("--event-ref-type", default="")
    result.add_argument("--event-sha", default="")
    result.add_argument("--repository", required=True)
    result.add_argument("--release-tag", default="")
    result.add_argument("--candidate-release-id", default="")
    result.add_argument("--candidate-id", default="")
    result.add_argument("--candidate-branch", default="")
    result.add_argument("--dispatch-nonce", default="")
    result.add_argument("--github-output", type=Path)
    return result


def main() -> int:
    arguments = parser().parse_args()
    try:
        values = validate_contract(arguments)
        if arguments.github_output is not None:
            write_github_output(arguments.github_output, values)
    except (ContractError, OSError, subprocess.CalledProcessError) as exc:
        print(f"FAIL {exc}")
        return 1
    print(json.dumps(values, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
