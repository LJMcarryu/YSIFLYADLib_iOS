# 6.2.2 发布维护说明

本文件只维护 YS 公开分发仓的发布状态和可机器校验的私有源码溯源，不包含 SDK 私有源码。

## 当前状态

- `releaseState`：`FORMAL`
- `binarySourceCommit`（SDK 二进制源码提交）：`a8ec925d3731d7d11734647aa02ca7d91d674965`
- `releaseMetadataCommit`（仅回填 checksum、扫描汇总和发布验收事实，不是 SDK 二进制源码提交）：`eff78263c2d3f65b029f4114de1a9ed00f3827f3`

`FORMAL` 表示二进制来源、签名资产和发布元数据已经固化，不等同于 GitHub 外部发布步骤已经执行。正式 Release 地址为：
<https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2>。

本版冻结资产摘要：

- `YSIFLYADLib.xcframework.zip`：`757f133d00cbd248366392f1dbf460adbd35089588c8da57b1cf947adc7f813d`
- `YSIFLYADLib-6.2.2.zip`：`25812612d0e88115ad0db5ebdbf81bd533afdf1ee7bd828d4ae93d78bca26411`
- `checksums.txt`：`6d98e0508571a9f25438ab4295e20db50df01f42e5e6480974f5a5c885535c7b`

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
