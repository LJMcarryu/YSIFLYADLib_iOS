# 6.2.2 发布维护说明

本文件只维护 YS 公开分发仓的发布状态和可机器校验的私有源码溯源，不包含 SDK 私有源码。

## 当前状态

- `releaseState`：`FORMAL`
- `binarySourceCommit`（SDK 二进制源码提交）：`a8ec925d3731d7d11734647aa02ca7d91d674965`
- `releaseMetadataCommit`（仅回填 checksum、扫描汇总和发布验收事实，不是 SDK 二进制源码提交）：`eff78263c2d3f65b029f4114de1a9ed00f3827f3`
- 公开分发 tag 提交（annotated tag peeled commit）：`b1bbaa5319335e027c560ab357c86cc6a732003e`

`FORMAL` 表示二进制来源、签名资产和发布元数据已经固化。`6.2.2` 已于 2026 年 8 月 10 日
通过 <https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2> 正式公开，
Release 非草稿、非预发布，资产库存严格为以下 3 项。

本版冻结资产摘要：

- `YSIFLYADLib.xcframework.zip`：`757f133d00cbd248366392f1dbf460adbd35089588c8da57b1cf947adc7f813d`
- `YSIFLYADLib-6.2.2.zip`：`25812612d0e88115ad0db5ebdbf81bd533afdf1ee7bd828d4ae93d78bca26411`
- `checksums.txt`：`6d98e0508571a9f25438ab4295e20db50df01f42e5e6480974f5a5c885535c7b`

[published CI 31347052226](https://github.com/LJMcarryu/YSIFLYADLib_iOS/actions/runs/31347052226)
结论为 `success`：使用不带 GitHub 凭据的公开 URL 匿名查询并下载全部 3 项资产，完成
SHA-256、SwiftPM checksum、双包同源和公开 API 校验，并实际构建 SwiftPM 产品、最小消费端和
CocoaPods Demo，同时通过完整 `pod spec lint`。该分发验收不代表最终宿主合规、
`Validate App` 或 Apple 审核通过。

本版按已确认范围原样归档 `SRC-004`、`SRC-008`、`SRC-009`、`SRC-011`、`NET-001`、
`RRA-003`、`TRACK-001`、`TRACK-002`、`ADS-011`、`EXPORT-001` 启发式残余风险，并以
`failOn=high`、`failOnWarning=false`、`strict=false`、`requireManual=false` 发布。该确认不适用于最终宿主。

`releaseMetadataCommit` 是 `binarySourceCommit` 的后代；两者之间只允许修改
`Package.swift`、`README.md`、`CONTEXT.md` 和 `docs/**`，不能改变 SDK 二进制输入。

## CI 凭据与 Release 正文

正式态 CI 需要仓库 Secret `IFLY_PRIVATE_SOURCE_TOKEN` 只读访问私有仓
`LJMcarryu/IFLYADLibDemo` 的 compare API。该 Token 只用于验证 A/B 祖先关系和变更路径，
不得传给本公开仓 Release 资产查询或下载。Secret 缺失时正式 tag/Release 必须失败。

GitHub Release 正文必须从“当前状态”逐字复制两行 A/B 规范声明，且每个提交只出现一次。

正式 Release 固定且只能包含以下三个资产：

- `YSIFLYADLib-6.2.2.zip`
- `YSIFLYADLib.xcframework.zip`
- `checksums.txt`

完整 `pod spec lint` 以及三资产下载和实际消费只在 Release `published` 事件，或手动传入
`release_tag` 时执行。普通 main、PR 和 tag push 只执行 `pod ipc spec` 等本地门禁，不能依赖
尚未对外可见的 Release 资产。CI 使用不带 `Authorization`、`GH_TOKEN` 或 `github.token`
的公开 URL 匿名下载全部三项，再执行 SHA-256、SwiftPM checksum、双包同源、公开 API 和真实消费构建复验。

tag 必须是指向正式分发提交的 annotated tag，且不得覆盖既有 tag 或 Release。
