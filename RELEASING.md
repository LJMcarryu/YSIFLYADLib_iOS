# 6.2.3 发布维护说明

本文件只维护 YS 公开分发仓的发布状态和可机器校验的私有源码溯源，不包含 SDK 私有源码。

## 正式发布唯一入口

新版本正式发布只能从内部私有源码仓根目录的 `scripts/release-orchestrator.py` 发起，并按
`prepare → preflight → publish → verify → closeout` 顺序完成。先用默认只读计划确认候选身份，
只有在版本、Xcode、签名和冻结条件满足时才可为对应阶段显式传入 `--execute`。不得从本公开仓
手工创建或移动 tag、发布 Release，也不得直接派发 candidate 工作流来替代编排器 receipt。

本仓 `.github/scripts/**`、CI 内嵌校验、包管理器消费命令和 GitHub Actions
`workflow_dispatch` 都只作为底层门禁或故障诊断入口。CI 对同一候选的复验顺序排队且不取消
既有 run；候选与正式 Release 使用不同并发组。重型验证 job 最长运行 55 分钟，结束后由无
Token、只读的 summary job 汇总 Candidate、Release、checkout commit、三资产 SHA-256 和全部
job 结论；summary 对上游失败继续失败关闭。

## 当前状态

- `releaseState`：`FORMAL`
- `binarySourceCommit`（SDK 二进制源码提交）：`c90c8e969b05d4d55b522cb162ab0f2e37aacc52`
- `releaseMetadataCommit`（仅回填 checksum、扫描汇总和发布验收事实，不是 SDK 二进制源码提交）：`b340fe7cccc27af37fc6223042f9638e507a4b63`

正式签名资产、checksum 和 A/B 已完成本地冻结校验；公开 tag、Release 和匿名消费验证仍须由编排器完成，
当前不得作为正式发布证据。以下为 `6.2.2` 历史正式事实：该版本已于 2026 年 8 月 10 日通过
<https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2> 正式公开，Release 非草稿、
非预发布，资产库存严格为以下 3 项。

`6.2.2` 冻结资产摘要：

- `YSIFLYADLib.xcframework.zip`：`757f133d00cbd248366392f1dbf460adbd35089588c8da57b1cf947adc7f813d`
- `YSIFLYADLib-6.2.2.zip`：`25812612d0e88115ad0db5ebdbf81bd533afdf1ee7bd828d4ae93d78bca26411`
- `checksums.txt`：`6d98e0508571a9f25438ab4295e20db50df01f42e5e6480974f5a5c885535c7b`

[published CI 31347052226](https://github.com/LJMcarryu/YSIFLYADLib_iOS/actions/runs/31347052226)
结论为 `success`：使用不带 GitHub 凭据的公开 URL 匿名查询并下载全部 3 项资产，完成
SHA-256、SwiftPM checksum、双包同源和公开 API 校验，并实际构建 SwiftPM 产品、最小消费端和
CocoaPods Demo，同时通过完整 `pod spec lint`。该分发验收不代表最终宿主合规、
`Validate App` 或 Apple 审核通过。

`6.2.2` 按当版已确认范围原样归档 `SRC-004`、`SRC-008`、`SRC-009`、`SRC-011`、`NET-001`、
`RRA-003`、`TRACK-001`、`TRACK-002`、`ADS-011`、`EXPORT-001` 启发式残余风险，并以
`failOn=high`、`failOnWarning=false`、`strict=false`、`requireManual=false` 发布。该确认不适用于
`6.2.3` 或最终宿主；`6.2.3` 不沿用历史风险授权。`6.2.3` 主动扫描策略固定为
`failOn=high`、`failOnWarning=true`、`strict=true`、`requireManual=true` 且接受名单为空；扫描状态
不改写正式发布状态，也不得把未扫描表述为通过。

`releaseState=FORMAL` 表示正式签名资产、checksum 和 A/B 元数据已经冻结；公开可用性以同版本 GitHub Release 和发布后 CI 为准。

正式态回填后，`releaseMetadataCommit` 必须是 `binarySourceCommit` 的后代；两者之间只允许修改
`Package.swift`、`README.md`、`CONTEXT.md` 和 `docs/**`，不能改变 SDK 二进制输入。

## CI 凭据与 Release 正文

正式态 CI 需要仓库 Secret `IFLY_PRIVATE_SOURCE_TOKEN` 只读访问私有仓
`LJMcarryu/IFLYADLibDemo` 的 compare API。该 Token 只用于验证 A/B 祖先关系和变更路径，
不得传给本公开仓 Release 资产查询或下载。Secret 缺失时正式 tag/Release 必须失败。

GitHub Release 正文必须从“当前状态”逐字复制两行 A/B 规范声明，且每个提交只出现一次。

`workflow_dispatch` 的 `validation_mode` 分为三种：

- `repository`（默认）：`release_tag` 为空时只跑仓库、清单、资源和 Demo 源码门禁，
  不访问 Release。为兼容旧的手动/API 调用，如果只传非空 `release_tag`，工作流自动
  推导为 `formal_release`；与 `candidate_release_id` 组合则拒绝执行。
- `draft_candidate`：只能从不可覆盖的
  `release-candidate/<version>-<candidateId>` 分支触发，并同时传同仓 draft Release 的十进制
  `candidate_release_id`、64 位小写 `candidate_id` 和 32 位小写 `dispatch_nonce`。checkout 必须
  等于触发事件的 `github.sha`；该提交必须已经包含最终真实 checksum、`releaseState=FORMAL`
  和两个不同的真实 A/B 提交。draft 的 `tag_name` 必须等于清单版本，`target_commitish` 只能
  绑定该候选分支或触发时的精确提交，但不要求 tag 已存在、Release 已公开。Draft Release
  仍保持 `draft=true`、`published_at=null`，后续 publish 直接使用同一不可变候选提交，不再
  回填清单或切换提交。Draft run name 固定为
  `draft-candidate:<candidateId>:<releaseId>:<dispatchNonce>`。
- `formal_release`：必须传 `release_tag`，checkout 必须绑定该 annotated tag，且本地状态必须为
  `FORMAL`。Release `published` 事件自动采用此模式。

draft candidate 的 `GITHUB_TOKEN` 只注入三个各自独立的下载步骤：前置资产门禁、
SwiftPM 消费 runner 和 CocoaPods 消费 runner。前置 job 只输出三个 SHA-256，不把未公开
二进制上传为 Actions artifact；两个并行消费 job 各自重新下载，在无 Token 步骤中与前置
哈希逐一绑定后才构建。checkout、本地门禁、哈希校验、lint 和构建均不注入该 Token。
普通 push、PR、tag push 不会进入 draft 资产 job。正式复验继续在显式移除
`GH_TOKEN`、`GITHUB_TOKEN`、`GITHUB_AUTH_TOKEN` 和 `ACTIONS_RUNTIME_TOKEN` 后匿名查询并下载公开资产。
工作流默认权限只保留 `contents: read`，不 checkout 的模式解析 job 使用空权限。

发布模式的控制脚本和 SwiftPM 本地消费 fixture 固定取自本次
`github.workflow_sha`，被验证的 main/tag checkout 只提供发布清单、Demo 和资产契约。
因此后续的 CI 优化可以复验旧的正式 tag，不要求或修改该 tag 使其包含新增脚本。

正式 Release 固定且只能包含以下三个资产：

- `YSIFLYADLib-6.2.3.zip`
- `YSIFLYADLib.xcframework.zip`
- `checksums.txt`

draft candidate 或正式 Release 的三资产先在单独 job 完成身份、精确库存、SHA-256、SwiftPM
checksum、双包同源、签名、架构、版本、公开 API 与 provenance 门禁。正式公开资产通过后固化为
当前 run 专属的短期 Actions artifact；draft 只传递哈希输出。SwiftPM 消费与 CocoaPods/Demo
（含 `pod spec lint`）在两个独立 runner 上并行执行，共同依赖该前置门禁。
正式模式在首次匿名下载及两个消费 job 中分别显式
清除 Release 目录、SwiftPM/CocoaPods 缓存和 DerivedData；draft Token job、两个消费 job 和
不同 workflow run 不能共享可预热的包管理器缓存。
两份原始分发清单的 GitHub Release URL 必须与仓库、版本和资产名完全一致；
CocoaPods 消费 job 生成的临时 podspec 使用已验证 zip 的 `file://` URL 和实时 SHA-256，
避免 lint 或 Demo 在资产门禁之后换用另一份下载。

普通 main、PR 和 tag push 只执行 `pod ipc spec` 等本地门禁，不能依赖尚未对外可见的 Release
资产。正式模式使用不带 `Authorization` 或 GitHub 凭据的公开 URL 下载全部三项，再执行完整复验。

`6.2.3` 还必须验证 NativeFeed 外部 CTA 默认关闭、同 window/scene 与视图归属门禁、运行时
71503 白标 delegate 拒绝回调，以及 `ysifly_detachFromCurrentContainer`；公开头、二进制 selector
和文档必须保持一致。

首次启用候选分支控制面前，必须把只包含 workflow、控制脚本和测试的 bootstrap 提交独立合入
远端 `main`，且该提交不得同时修改版本、`Package.swift` 或 `YSIFLYADLib.podspec`。默认分支先具备
新 inputs 和 run-name 后，编排器才能从候选分支可靠派发；每版的版本内容门禁仍随候选提交更新。
候选分支在发布完成后暂不删除，以便失败恢复和证据复验。

tag 必须是指向正式分发提交的 annotated tag，且不得覆盖既有 tag 或 Release。
