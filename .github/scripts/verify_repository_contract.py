#!/usr/bin/env python3
"""分别校验 YS 机器分发契约与阻断式 Markdown 发布契约。"""

from __future__ import annotations

import argparse
import json
import re
import shlex
import sys
from pathlib import Path


VERSION = "6.2.4"
PREVIOUS_VERSION = "6.2.3"
REPOSITORY = "LJMcarryu/YSIFLYADLib_iOS"
HISTORICAL = {
    "d65b715b1fa5eaf1ae38c3a94f3eaf7e2289958f2b678aa0dccec1f66873627a",
    "757f133d00cbd248366392f1dbf460adbd35089588c8da57b1cf947adc7f813d",
    "84c77f4b9930f892086e08ec9f4185af474eab72a403905f4c5d9257936667a2",
}
RELEASE_STATUS_RE = re.compile(
    r"<!--\s*ifly-release-status:\s*(\{[^\r\n]*\})\s*-->"
)


class ContractError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def read(root: Path, relative: str) -> str:
    return (root / relative).read_text(encoding="utf-8")


def verify_release_status(label: str, document: str) -> None:
    markers = RELEASE_STATUS_RE.findall(document)
    require(len(markers) == 1, f"{label} 发布状态标记数量错误: {len(markers)}")
    try:
        marker = json.loads(markers[0])
    except json.JSONDecodeError as error:
        raise ContractError(f"{label} 发布状态标记不是合法 JSON") from error
    expected = {
        "schemaVersion": 1,
        "version": VERSION,
        "releaseState": "FORMAL",
        "distribution": "github-release",
        "releaseUrl": f"https://github.com/{REPOSITORY}/releases/tag/{VERSION}",
    }
    require(marker == expected, f"{label} 发布状态标记漂移: {marker}")


def state(root: Path, release_kind: str) -> dict[str, object]:
    value = json.loads(read(root, "release-state.json"))
    require(value.get("channel") == "ys", "release-state 渠道不匹配")
    phase = value.get("phase")
    state_version = value.get("version")
    if release_kind in {"draft_candidate", "formal_release"}:
        require(state_version == VERSION, "release-state 版本不匹配")
        require(phase == "FROZEN", f"{release_kind} 只允许 release-state FROZEN")
    elif release_kind == "repository" and phase == "CLOSED":
        require(
            state_version in {PREVIOUS_VERSION, VERSION},
            "main 只允许保留上一正式版或当前版 CLOSED 状态",
        )
    else:
        require(state_version == VERSION, "release-state 版本不匹配")
    return value


def one(pattern: str, text: str, label: str) -> str:
    values = re.findall(pattern, text, re.M)
    require(len(values) == 1, f"{label} 声明数量错误: {values}")
    return values[0]


def verify_machine(
    root: Path, release_kind: str, podspec_json_path: Path
) -> None:
    require(release_kind in {"repository", "draft_candidate", "formal_release"},
            "非法验证模式")
    machine = state(root, release_kind)
    package = read(root, "Package.swift")
    podspec = read(root, "YSIFLYADLib.podspec")
    podfile = read(root, "YSIFLYADLibSimple/Podfile")
    podspec_json = json.loads(podspec_json_path.read_text(encoding="utf-8"))
    version = one(r"s\.version\s*=\s*['\"]([^'\"]+)", podspec, "podspec version")
    require(version == VERSION, f"podspec 版本错误: {version}")
    package_url = one(r'url:\s*"([^"]*YSIFLYADLib\.xcframework\.zip)"',
                      package, "SwiftPM URL")
    pod_url = one(r"s\.source\s*=\s*\{\s*:http\s*=>\s*['\"]([^'\"]+)",
                  podspec, "podspec URL")
    require(
        package_url == f"https://github.com/{REPOSITORY}/releases/download/"
        f"{VERSION}/YSIFLYADLib.xcframework.zip",
        "SwiftPM URL 版本或仓库错误",
    )
    require(
        pod_url == f"https://github.com/{REPOSITORY}/releases/download/"
        f"{VERSION}/YSIFLYADLib-{VERSION}.zip",
        "podspec URL 版本或仓库错误",
    )
    demo_url = one(r":podspec\s*=>\s*'([^']+)'", podfile, "Demo podspec URL")
    require(
        demo_url == f"https://raw.githubusercontent.com/{REPOSITORY}/"
        f"{VERSION}/YSIFLYADLib.podspec",
        "Demo podspec URL 版本错误",
    )
    checksum = one(r'checksum:\s*"([^"]+)"', package, "SwiftPM checksum")
    require(re.fullmatch(r"[0-9a-f]{64}", checksum) is not None,
            "6.2.4 分发基线 checksum 非 64 位小写 SHA-256")
    require(checksum != "0" * 64 and checksum not in HISTORICAL,
            "6.2.4 分发基线 checksum 为零或沿用历史值")
    for marker in (
        '.library(name: "YSIFLYADLib", targets: ["YSIFLYADLib", "YSIFLYADLibResources"])',
        '.copy("YSAdvSDK.bundle")',
    ):
        require(marker in package, f"Package.swift 缺少包契约: {marker}")
    frameworks = podspec_json.get("frameworks", [])
    weak_frameworks = podspec_json.get("weak_frameworks", [])
    if isinstance(frameworks, str):
        frameworks = [frameworks]
    if isinstance(weak_frameworks, str):
        weak_frameworks = [weak_frameworks]
    require("AdSupport" in frameworks, "podspec JSON 缺少 AdSupport 强链接声明")
    require(
        "AppTrackingTransparency" in weak_frameworks,
        "podspec JSON 缺少 AppTrackingTransparency 弱链接声明",
    )
    for key in ("pod_target_xcconfig", "user_target_xcconfig"):
        config = podspec_json.get(key, {})
        require(isinstance(config, dict), f"podspec JSON {key} 非对象")
        flags = config.get("OTHER_LDFLAGS", "")
        require(
            isinstance(flags, str) and "-ObjC" in shlex.split(flags),
            f"podspec JSON {key}.OTHER_LDFLAGS 缺少 -ObjC",
        )
    require((root / "spm/YSIFLYADLibResources/YSIFLYADLibResources.swift").is_file(),
            "缺少 SwiftPM 资源锚点")
    require((root / "spm/YSIFLYADLibResources/YSAdvSDK.bundle/PrivacyInfo.xcprivacy").is_file(),
            "缺少 SwiftPM PrivacyInfo.xcprivacy")


def verify_docs(root: Path, release_kind: str) -> None:
    machine = state(root, release_kind)
    documents = {
        name: read(root, name)
        for name in ("README.md", "CHANGELOG.md", "RELEASING.md")
    }
    demo = read(root, "YSIFLYADLibSimple/README.md")
    for label, document in documents.items():
        verify_release_status(label, document)
    require(VERSION in demo, "Demo 缺少当前版本展示")
    if release_kind == "repository" and machine.get("version") == PREVIOUS_VERSION:
        require("待发布" in documents["CHANGELOG.md"], "CHANGELOG 缺少待发布展示")
        require("发布准备" in documents["RELEASING.md"], "RELEASING 缺少发布准备展示")
        require("发布准备" in demo, "Demo 缺少发布准备展示")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--scope", choices=("machine", "docs"), required=True)
    parser.add_argument("--podspec-json", type=Path)
    parser.add_argument(
        "--release-kind",
        choices=("repository", "draft_candidate", "formal_release"),
        default="repository",
    )
    args = parser.parse_args()
    try:
        if args.scope == "machine":
            if args.podspec_json is None:
                parser.error("--scope machine 必须提供 --podspec-json")
            verify_machine(
                args.root.resolve(), args.release_kind, args.podspec_json.resolve()
            )
        else:
            verify_docs(args.root.resolve(), args.release_kind)
    except (ContractError, OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    print(f"OK {args.scope} contract")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
