# 发布维护说明

## 6.4.4 冻结与发布记录

<!-- ifly-release-status: {"schemaVersion":1,"version":"6.4.4","releaseState":"FORMAL","distribution":"github-release","releaseUrl":"https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.4.4"} -->

`6.4.4` 的正式分发资料以同版本真实冻结 manifest 为准。当前正式版本：[`6.4.4`](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.4.4)；公开时间和消费验证结论以 `release-state.json.publication` 与同版本 GitHub Release 的实际状态为准。历史 Tag、Release 和资产保持不可变。


本文件只维护 YS 公开分发仓的发布状态和可机器校验的私有源码溯源，不包含 SDK 私有源码。

## 6.4.2 冻结与发布记录

历史记录见[历史发布记录](docs/需求设计/发布验收/历史发布记录.md#642-冻结与发布记录)。

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

## 6.4.1 冻结与发布记录

历史记录见[历史发布记录](docs/需求设计/发布验收/历史发布记录.md#641-冻结与发布记录)。

## 6.4.0 冻结与发布记录

历史记录见[历史发布记录](docs/需求设计/发布验收/历史发布记录.md#640-冻结与发布记录)。

## 6.3.5 发布状态

历史记录见[历史发布记录](docs/需求设计/发布验收/历史发布记录.md#635-发布状态)。

## 6.3.1 历史正式事实

历史记录见[历史发布记录](docs/需求设计/发布验收/历史发布记录.md#631-历史正式事实)。

## 6.2.4 历史正式事实

历史记录见[历史发布记录](docs/需求设计/发布验收/历史发布记录.md#624-历史正式事实)。

## 6.2.3 历史正式事实

历史记录见[历史发布记录](docs/需求设计/发布验收/历史发布记录.md#623-历史正式事实)。

## CI 凭据与 Release 正文

正式态 CI 需要仓库 Secret `IFLY_PRIVATE_SOURCE_TOKEN` 只读访问私有仓
`LJMcarryu/IFLYADLibDemo` 的 compare API。该 Token 只用于验证 A/B 祖先关系和变更路径，
不得传给本公开仓 Release 资产查询或下载。Secret 缺失时正式 tag/Release 必须失败。

正式态采用两提交模型：二进制从提交 A 构建；提交 B 必须是 A 的后代，且 A→B 只允许修改 `Package.swift`、`README.md`、`CONTEXT.md` 和 `docs/**`。当前 A/B 以目标版本 `release-state.json` 的 `binarySourceCommit` / `releaseMetadataCommit` 为准。GitHub Release 正文必须按本版真实状态使用两行 A/B 规范声明，且每个提交只出现一次；不能使用历史归档中的提交。

`workflow_dispatch` 的 `validation_mode` 分为三种。`releaseState=FORMAL` 是文档分发状态，不是机器阶段；
`release-state.json.phase` 另行记录 `FROZEN` / `CLOSED`。模式由控制合同绑定版本和阶段：

- `repository`（默认）：`release_tag` 与 `formal_release_id` 均为空时只跑仓库、清单、资源和 Demo 源码门禁，
  `release-state.json.phase` 必须为 `CLOSED` 且版本符合控制合同，不访问 Release。兼容旧的手动/API 调用时，
  必须同时提供目标版本 `release_tag` 与对应的正整数 `formal_release_id`，工作流才推导为 `formal_release`；只传其中一项或与 `candidate_release_id` 组合均拒绝执行。
- `draft_candidate`：只能从不可覆盖的
  `release-candidate/<version>-<candidateId>` 分支触发，并同时传同仓 draft Release 的十进制
  `candidate_release_id`、64 位小写 `candidate_id` 和 32 位小写 `dispatch_nonce`。checkout 必须
  等于触发事件的 `github.sha`；该提交的 `release-state.json.phase` 必须为 `FROZEN`，
  文档 `releaseState=FORMAL`，并已经包含最终真实 checksum
  和两个不同的真实 A/B 提交。draft 的 `tag_name` 必须等于清单版本，`target_commitish` 只能
  绑定该候选分支或触发时的精确提交，但不要求 tag 已存在、Release 已公开。Draft Release
  仍保持 `draft=true`、`published_at=null`，后续 publish 直接使用同一不可变候选提交，不再
  回填清单或切换提交。Draft run name 固定为
  `draft-candidate:<candidateId>:<releaseId>:<dispatchNonce>`。
- `formal_release`：手动调用必须同时提供目标版本 `release_tag` 与对应的正整数 `formal_release_id`，checkout 必须绑定该 annotated tag，且本地状态必须为
  `release-state.json.phase=FROZEN`，文档 `releaseState=FORMAL`。Release `published` 事件自动采用此模式，并从事件取得版本与 Release ID。

draft candidate 的 `GITHUB_TOKEN` 只注入三个各自独立的下载步骤：前置资产门禁、
SwiftPM 消费 runner 和 CocoaPods 消费 runner。前置 job 只输出三个 SHA-256，不把未公开
二进制上传为 Actions artifact；两个并行消费 job 各自重新下载，在无 Token 步骤中与前置
哈希逐一绑定后才构建。checkout、本地门禁、哈希校验、lint 和构建均不注入该 Token。
普通 push、PR、tag push 不会进入 draft 资产 job。正式元数据来自 Release `published` 事件，或手动复验时通过 `GITHUB_TOKEN` 按精确 Release ID 认证查询；二进制资产始终通过不带 `Authorization` 的公开 URL 匿名下载。
工作流默认权限只保留 `contents: read`，不 checkout 的模式解析 job 使用空权限。

发布模式的控制脚本和 SwiftPM 本地消费 fixture 固定取自本次
`github.workflow_sha`，被验证的 main/tag checkout 只提供发布清单、Demo 和资产契约。
因此后续的 CI 优化可以复验旧的正式 tag，不要求或修改该 tag 使其包含新增脚本。

正式 Release 固定且只能包含以下三个资产：

- `YSIFLYADLib-<目标版本>.zip`
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

NativeFeed 回归按目标版本计划、公开头与 API 变更确定；历史专项验收见[历史发布记录](docs/需求设计/发布验收/历史发布记录.md#635-nativefeed-专项验收)。

Apple Review 为主动可选扫描，策略以目标版本计划为准；未运行记录 `not-run`，不得表述为扫描或 Apple 审核通过，历史版本风险授权不沿用。

首次启用候选分支控制面前，必须把只包含 workflow、控制脚本和测试的 bootstrap 提交独立合入
远端 `main`，且该提交不得同时修改版本、`Package.swift` 或 `YSIFLYADLib.podspec`。默认分支先具备
新 inputs 和 run-name 后，编排器才能从候选分支可靠派发；每版的版本内容门禁仍随候选提交更新。
候选分支在发布完成后暂不删除，以便失败恢复和证据复验。

tag 必须是指向正式分发提交的 annotated tag，且不得覆盖既有 tag 或 Release。
