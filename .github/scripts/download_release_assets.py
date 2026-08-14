#!/usr/bin/env python3
"""严格下载同仓 draft candidate 或正式公开 Release 的三项资产。"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import urllib.request
from urllib.parse import quote, urlsplit
from pathlib import Path
from typing import Any, Mapping


TOKEN_NAMES = ("GH_TOKEN", "GITHUB_TOKEN", "GITHUB_AUTH_TOKEN", "ACTIONS_RUNTIME_TOKEN")
SHA40 = re.compile(r"^[0-9a-f]{40}$")
VERSION = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
CANDIDATE = re.compile(r"^[0-9a-f]{64}$")
CANDIDATE_LINE = re.compile(
    r"^- `candidateId`：`([0-9a-f]{64})`\s*$", re.MULTILINE
)


class DownloadError(RuntimeError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise DownloadError(message)


class CrossHostCredentialSafeRedirect(urllib.request.HTTPRedirectHandler):
    """跟随 GitHub 资产重定向，但绝不把 API Authorization 带到对象存储。"""

    def redirect_request(self, request, file_pointer, code, message, headers, new_url):
        redirected = super().redirect_request(
            request, file_pointer, code, message, headers, new_url
        )
        if redirected is not None and (
            urlsplit(request.full_url).netloc != urlsplit(new_url).netloc
        ):
            redirected.remove_header("Authorization")
        return redirected


def open_url(request: urllib.request.Request, timeout: int):
    opener = urllib.request.build_opener(CrossHostCredentialSafeRedirect())
    return opener.open(request, timeout=timeout)


def request_json(url: str, headers: Mapping[str, str]) -> dict[str, Any]:
    request = urllib.request.Request(url, headers=dict(headers))
    with open_url(request, timeout=180) as response:
        value = json.load(response)
    require(isinstance(value, dict), "Release API 响应必须是字典")
    return value


def provenance(document: str, version: str, mode: str) -> tuple[str, str]:
    binary = re.findall(
        r"^- `binarySourceCommit`（SDK 二进制源码提交）：`([^`]+)`$",
        document,
        re.MULTILINE,
    )
    metadata = re.findall(
        r"^- `releaseMetadataCommit`（仅回填 checksum、扫描汇总和发布验收事实，"
        r"不是 SDK 二进制源码提交）：`([^`]+)`$",
        document,
        re.MULTILINE,
    )
    require(len(binary) == len(metadata) == 1, "A/B provenance 声明必须各一条")
    require(mode in {"draft_candidate", "formal_release"}, f"未知发布模式: {mode}")
    require(VERSION.fullmatch(version) is not None, f"版本格式非法: {version}")
    require(SHA40.fullmatch(binary[0]) is not None, "最终 FORMAL A 非 40 位提交")
    require(SHA40.fullmatch(metadata[0]) is not None, "最终 FORMAL B 非 40 位提交")
    require(binary[0] != metadata[0], "最终 FORMAL A/B 必须不同")
    return binary[0], metadata[0]


def expected_asset_names(version: str) -> list[str]:
    return sorted(
        (
            f"YSIFLYADLib-{version}.zip",
            "YSIFLYADLib.xcframework.zip",
            "checksums.txt",
        )
    )


def validate_release(
    release: Mapping[str, Any],
    *,
    mode: str,
    repository: str,
    version: str,
    candidate_release_id: str,
    candidate_id: str,
    target_branch: str,
    expected_commit: str,
    documented_provenance: tuple[str, str],
    resolved_target_commit: str | None = None,
) -> dict[str, Mapping[str, Any]]:
    require(release.get("tag_name") == version, "Release tag_name 与本地版本不一致")
    require(release.get("prerelease") is False, "Release 不得为 prerelease")
    if mode == "draft_candidate":
        require(release.get("draft") is True, "candidate Release 必须保持 draft")
        require(str(release.get("id")) == candidate_release_id, "draft Release ID 漂移")
        require(release.get("published_at") is None, "draft candidate 不得已有 published_at")
        target = release.get("target_commitish")
        require(target in {target_branch, expected_commit}, "draft target_commitish 必须绑定候选分支或精确提交")
        if target == target_branch:
            require(
                resolved_target_commit == expected_commit,
                "draft 候选分支当前提交与触发 checkout 不一致",
            )
    else:
        require(release.get("draft") is False, "正式 Release 不得为 draft")
        require(release.get("published_at"), "正式 Release 缺少 published_at")

    html_url = release.get("html_url")
    expected_html_prefix = f"https://github.com/{repository}/releases/"
    if mode == "formal_release":
        require(
            html_url == expected_html_prefix + f"tag/{version}",
            "正式 Release html_url 与当前仓库/tag 不一致",
        )
        download_slug = version
    else:
        require(isinstance(html_url, str), "draft Release html_url 缺失")
        match = re.fullmatch(
            re.escape(expected_html_prefix + "tag/") + r"(untagged-[0-9a-f]+)",
            html_url,
        )
        require(
            match is not None,
            "draft Release html_url 必须是同仓 HTTPS untagged URL",
        )
        download_slug = match.group(1)
    release_body = release.get("body") or ""
    require(isinstance(release_body, str), "Release body 必须是字符串")
    if mode == "draft_candidate":
        require(CANDIDATE.fullmatch(candidate_id) is not None, "candidate_id 非 64 位小写十六进制")
        require(
            CANDIDATE_LINE.findall(release_body) == [candidate_id]
            and release_body.count("`candidateId`") == 1,
            "Draft Release body 必须唯一声明输入 candidateId",
        )
    body_provenance = provenance(release_body, version, mode)
    require(body_provenance == documented_provenance, "Release 正文 A/B 与 RELEASING.md 不一致")
    for value in body_provenance:
        require(release_body.count(value) == 1, "Release 正文每个 provenance 提交只能出现一次")

    assets_value = release.get("assets")
    require(isinstance(assets_value, list), "Release assets 必须是数组")
    require(all(isinstance(asset, dict) for asset in assets_value), "Release asset 必须是字典")
    names = [asset.get("name") for asset in assets_value]
    require(all(isinstance(name, str) for name in names), "Release asset name 必须是字符串")
    expected = expected_asset_names(version)
    require(sorted(names) == expected and len(names) == len(set(names)), f"资产库存错误: {names}")
    assets: dict[str, Mapping[str, Any]] = {}
    api_prefix = f"https://api.github.com/repos/{repository}/releases/assets/"
    browser_prefix = (
        f"https://github.com/{repository}/releases/download/{download_slug}/"
    )
    for asset in assets_value:
        require(isinstance(asset, dict), "Release asset 必须是字典")
        name = asset["name"]
        require(asset.get("state") == "uploaded", f"资产尚未 uploaded: {name}")
        require(
            isinstance(asset.get("size"), int)
            and not isinstance(asset.get("size"), bool)
            and asset["size"] > 0,
            f"资产 size 非正整数: {name}",
        )
        require(
            isinstance(asset.get("url"), str)
            and re.fullmatch(re.escape(api_prefix) + r"[1-9][0-9]*", asset["url"])
            is not None,
            f"资产 API URL 不属于当前仓库: {name}",
        )
        require(
            isinstance(asset.get("browser_download_url"), str)
            and asset["browser_download_url"] == browser_prefix + name,
            f"资产 browser_download_url 未绑定当前 Release slug: {name}",
        )
        assets[name] = asset
    return assets


def download_bytes(url: str, headers: Mapping[str, str], timeout: int = 300) -> bytes:
    request = urllib.request.Request(url, headers=dict(headers))
    with open_url(request, timeout=timeout) as response:
        return response.read()


def download_asset(
    asset: Mapping[str, Any],
    destination: Path,
    *,
    mode: str,
    token: str,
) -> str:
    if mode == "draft_candidate":
        url = str(asset["url"])
        headers = {
            "Accept": "application/octet-stream",
            "Authorization": f"Bearer {token}",
            "User-Agent": "YSIFLYADLib-draft-candidate-gate",
            "X-GitHub-Api-Version": "2022-11-28",
        }
    else:
        url = str(asset["browser_download_url"])
        headers = {"User-Agent": "YSIFLYADLib-anonymous-release-gate"}
    contents = download_bytes(url, headers)
    require(len(contents) == asset["size"], f"下载大小与 API 不一致: {asset['name']}")
    digest = hashlib.sha256(contents).hexdigest()
    api_digest = asset.get("digest")
    if api_digest is not None:
        require(api_digest == f"sha256:{digest}", f"API digest 不一致: {asset['name']}")
    temporary = destination.with_name(destination.name + ".tmp")
    temporary.write_bytes(contents)
    temporary.replace(destination)
    return digest


def ensure_destination(path: Path) -> None:
    require(not path.is_symlink(), "下载目录不得是符号链接")
    path.mkdir(parents=True, exist_ok=True)
    require(not any(path.iterdir()), "下载目录必须为空，防止复用旧资产或缓存")


def run(arguments: argparse.Namespace) -> dict[str, str]:
    mode = arguments.mode
    repository = arguments.repository
    version = arguments.version
    require(re.fullmatch(r"[^/\s]+/[^/\s]+", repository) is not None, "仓库名必须为 owner/name")
    require(VERSION.fullmatch(version) is not None, "版本必须为 x.y.z")
    require(SHA40.fullmatch(arguments.expected_commit) is not None, "expected commit 非 40 位 SHA")
    documented = provenance(arguments.releasing.read_text(encoding="utf-8"), version, mode)

    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if mode == "draft_candidate":
        require(
            re.fullmatch(r"[1-9][0-9]*", arguments.candidate_release_id) is not None,
            "candidate_release_id 非十进制正整数",
        )
        require(CANDIDATE.fullmatch(arguments.candidate_id) is not None, "candidate_id 非 64 位小写十六进制")
        expected_branch = f"release-candidate/{version}-{arguments.candidate_id}"
        require(arguments.target_branch == expected_branch, "target_branch 与版本/candidate_id 不一致")
        require(token, "draft candidate 下载步骤必须显式注入 GITHUB_TOKEN")
        api_url = (
            f"https://api.github.com/repos/{repository}/releases/"
            f"{arguments.candidate_release_id}"
        )
        api_headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "User-Agent": "YSIFLYADLib-draft-candidate-gate",
            "X-GitHub-Api-Version": "2022-11-28",
        }
    else:
        leaked = [name for name in TOKEN_NAMES if os.environ.get(name)]
        require(not leaked, f"正式匿名复验环境不得包含凭据变量: {leaked}")
        require(not arguments.candidate_release_id, "正式复验不得提供 candidate_release_id")
        require(not arguments.candidate_id, "正式复验不得提供 candidate_id")
        require(not arguments.target_branch, "正式复验不得提供 target_branch")
        api_url = f"https://api.github.com/repos/{repository}/releases/tags/{version}"
        api_headers = {
            "Accept": "application/vnd.github+json",
            "User-Agent": "YSIFLYADLib-anonymous-release-gate",
            "X-GitHub-Api-Version": "2022-11-28",
        }

    release = request_json(api_url, api_headers)
    resolved_target_commit = None
    if mode == "draft_candidate" and release.get("target_commitish") == arguments.target_branch:
        ref_url = (
            f"https://api.github.com/repos/{repository}/git/ref/heads/"
            f"{quote(arguments.target_branch, safe='')}"
        )
        reference = request_json(ref_url, api_headers)
        resolved_target_commit = reference.get("object", {}).get("sha")
    assets = validate_release(
        release,
        mode=mode,
        repository=repository,
        version=version,
        candidate_release_id=arguments.candidate_release_id,
        candidate_id=arguments.candidate_id,
        target_branch=arguments.target_branch,
        expected_commit=arguments.expected_commit,
        documented_provenance=documented,
        resolved_target_commit=resolved_target_commit,
    )
    destination = arguments.destination.resolve()
    ensure_destination(destination)
    hashes = {}
    for name in expected_asset_names(version):
        hashes[name] = download_asset(
            assets[name], destination / name, mode=mode, token=token
        )

    if mode == "formal_release":
        for name in expected_asset_names(version):
            retry = download_bytes(
                str(assets[name]["browser_download_url"]),
                {"User-Agent": "YSIFLYADLib-anonymous-release-retry"},
            )
            require(
                hashlib.sha256(retry).hexdigest() == hashes[name],
                f"第二次匿名下载内容不一致: {name}",
            )
    return hashes


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    result.add_argument("--mode", required=True, choices=("draft_candidate", "formal_release"))
    result.add_argument("--repository", required=True)
    result.add_argument("--version", required=True)
    result.add_argument("--expected-commit", required=True)
    result.add_argument("--candidate-release-id", default="")
    result.add_argument("--candidate-id", default="")
    result.add_argument("--target-branch", default="")
    result.add_argument("--releasing", type=Path, default=Path("RELEASING.md"))
    result.add_argument("--destination", required=True, type=Path)
    return result


def main() -> int:
    try:
        hashes = run(parser().parse_args())
    except (DownloadError, OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        return 1
    print(json.dumps(hashes, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
