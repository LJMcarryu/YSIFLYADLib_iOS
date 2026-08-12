#!/usr/bin/env python3
"""把已验证的合并 zip 接入临时 podspec 与 Demo，避免消费阶段再次访问 Release。"""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import sys
from pathlib import Path


class FixtureError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise FixtureError(message)


def prepare(root: Path, release_dir: Path, output: Path, version: str) -> None:
    root = root.resolve()
    release_dir = release_dir.resolve()
    output = output.resolve()
    require(re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version) is not None, "版本非法")
    require(not output.is_symlink(), "fixture 输出目录不得是符号链接")
    output.mkdir(parents=True, exist_ok=True)
    require(not any(output.iterdir()), "fixture 输出目录必须为空")

    combined = release_dir / f"YSIFLYADLib-{version}.zip"
    require(combined.is_file() and not combined.is_symlink(), f"缺少已验证合并 zip: {combined}")
    podspec_source = root / "YSIFLYADLib.podspec"
    demo_source = root / "YSIFLYADLibSimple"
    require(podspec_source.is_file(), "缺少 YSIFLYADLib.podspec")
    require(demo_source.is_dir(), "缺少 YSIFLYADLibSimple")

    podspec = podspec_source.read_text(encoding="utf-8")
    digest = hashlib.sha256()
    with combined.open("rb") as archive:
        for chunk in iter(lambda: archive.read(1024 * 1024), b""):
            digest.update(chunk)
    local_source = (
        f"  s.source   = {{ :http => '{combined.as_uri()}', "
        f":sha256 => '{digest.hexdigest()}' }}"
    )
    podspec, source_count = re.subn(
        r"(?m)^\s*s\.source\s*=\s*\{\s*:http\s*=>\s*['\"][^'\"]+['\"]\s*\}\s*$",
        local_source,
        podspec,
    )
    require(source_count == 1, f"podspec s.source 替换数量错误: {source_count}")
    local_podspec = output / "YSIFLYADLib.podspec"
    local_podspec.write_text(podspec, encoding="utf-8")

    local_demo = output / "YSIFLYADLibSimple"
    shutil.copytree(demo_source, local_demo)
    podfile = local_demo / "Podfile"
    podfile_text = podfile.read_text(encoding="utf-8")
    replacement = f"  pod 'YSIFLYADLib', :podspec => '{local_podspec}'"
    podfile_text, pod_count = re.subn(
        r"(?m)^\s*pod\s+['\"]YSIFLYADLib['\"]\s*,\s*:podspec\s*=>\s*['\"][^'\"]+['\"]\s*$",
        replacement,
        podfile_text,
    )
    require(pod_count == 1, f"Demo Podfile 依赖替换数量错误: {pod_count}")
    podfile.write_text(podfile_text, encoding="utf-8")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    result.add_argument("--root", type=Path, default=Path.cwd())
    result.add_argument("--release-dir", type=Path, required=True)
    result.add_argument("--output", type=Path, required=True)
    result.add_argument("--version", required=True)
    return result


def main() -> int:
    arguments = parser().parse_args()
    try:
        prepare(arguments.root, arguments.release_dir, arguments.output, arguments.version)
    except (FixtureError, OSError) as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        return 1
    print(arguments.output.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
