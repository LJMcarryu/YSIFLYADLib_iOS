# 更新日志

本日志按 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 格式维护。
`6.1.0` 包含经产品批准的不兼容公开契约变更，升级时不能仅根据次版本号判断兼容性。

`YSIFLYADLib` 为 YS 媒体定制白标分发仓（model B 单包整变体），由 IFLYADLib 私有 dev 仓经 `scripts/rebrand.sh --brand ys` + `build-xcframework.sh --brand ys --variant YSNoReward` 产出。变体 = Full 关闭 `REWARD`、保留 `VIDEO`：开屏 / Banner / 插屏 / 信息流（含视频），无激励视频。

## [6.2.3] - 2026-08-14

- `releaseState`：`FORMAL`
- `binarySourceCommit`（SDK 二进制源码提交）：`c84a0461e6a857cf8ae096c579d77e99a3f83bb9`
- `releaseMetadataCommit`（仅回填 checksum、扫描汇总和发布验收事实，不是 SDK 二进制源码提交）：`56cf6833e7538025d5e38fa8d6ad976fc9cd8862`
- `releaseState=FORMAL` 表示正式签名资产、checksum 和 A/B 元数据已经冻结；公开可用性以同版本 GitHub Release 和发布后 CI 为准。
- `6.2.3` 不沿用历史风险授权；主动扫描策略固定为 `failOn=high`、`failOnWarning=true`、`strict=true`、`requireManual=true` 且接受名单为空，不得套用 `6.2.2` 的扫描阈值或接受名单。
- NativeFeed Binder 新增 `allowsExternalClickViews`（默认 `NO`）。显式开启后仅接受同 window/scene 且归属可判定的同 Cell 或窄范围兄弟视图；共享、固定悬浮、离屏仍可点击或归属不明时失败关闭，并通过 `ysifly_nativeFeedAd:didRejectClickWithError:` 返回 `YSIFLYAdErrorCodeNativeFeedClickViewsInvalid`（71503）。
- 新增 `ysifly_detachFromCurrentContainer` 固定单容器便利入口；`6.2.2` 的 Ad 级 attach 与容器级 detach 仍是通用主路径。

## [6.2.2] - 2026-08-10

### 发布事实

- 正式签名资产由唯一源码提交构建并完成本地发布门禁，SwiftPM checksum 为 `757f133d00cbd248366392f1dbf460adbd35089588c8da57b1cf947adc7f813d`。
- [GitHub Release 6.2.2](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2) 已正式公开，annotated tag 解引用后的提交为 `b1bbaa5319335e027c560ab357c86cc6a732003e`，资产库存严格为 3 项。[published CI](https://github.com/LJMcarryu/YSIFLYADLib_iOS/actions/runs/31347052226) 成功完成无凭据匿名下载、SHA-256 与双包同源校验、SwiftPM/CocoaPods 实际消费构建和完整 `pod spec lint`；该分发验收不代表最终宿主合规、`Validate App` 或 Apple 审核通过。
- `6.2.2` 按当版确认范围保留并原样归档 `SRC-004`、`SRC-008`、`SRC-009`、`SRC-011`、`NET-001`、`RRA-003`、`TRACK-001`、`TRACK-002`、`ADS-011`、`EXPORT-001` 启发式残余风险，以 `failOn=high`、`failOnWarning=false`、`strict=false`、`requireManual=false` 发布；该确认不适用于 `6.2.3` 或最终宿主。
- `6.2.2` 二进制源码提交为 `a8ec925d3731d7d11734647aa02ca7d91d674965`，发布元数据提交为 `eff78263c2d3f65b029f4114de1a9ed00f3827f3`。

### 变更

- NativeFeed 统一改为 SDK 托管挂载。媒体数据项只持 `YSIFLYNativeFeedAd`；Cell 不再持有 `YSIFLYNativeFeedDisplaySession`、`YSIFLYNativeFeedAdBinding`、绑定集合或首次/复用状态。
- 展示时统一调用 Ad 级 `ysifly_attachWithViewBinder:error:`；Cell 离屏、复用或切换普通内容时调用容器级 `ysifly_detachAdFromContainerView:`。SDK 内部处理同 Ad 串行迁移、同容器幂等、新 Ad 原子接管和迟到回调隔离。
- detach 只反注册视图，不结束逻辑广告条目；数据层继续持有同一 Ad 时，条目回屏可恢复原广告。曝光前重新累计连续可见 500ms，已曝光条目不重复曝光，点击与视频节点监测继续按逻辑广告去重。
- 条目永久结束时，媒体置空 delegate 并释放最后一个 Ad 强引用即可触发终态清理；`ysifly_destroy` 保留为仍持有 Ad 时可选的主动提前取消/终止入口，不再是正常列表生命周期必调项。

### 不兼容调整

- `YSIFLYNativeFeedDisplaySession`、`YSIFLYNativeFeedAdBinding`、`ysifly_beginDisplaySessionWithError:`、`ysifly_endDisplaySession`、`ysifly_bindAdWithViewBinder:error:`、`ysifly_unbindAd` 和 Binding `ysifly_detach` 退出公开 API。升级方须删除这些类型和调用，改为 Ad attach 与容器 detach。

### 分发边界

- 继续保持 YS 三资产契约：`YSIFLYADLib-6.2.2.zip`、`YSIFLYADLib.xcframework.zip`、`checksums.txt`；能力仍为开屏 / Banner / 插屏 / 自渲染信息流（含视频、无激励），最低支持 iOS 11.0。
- 正式资产已从 `binarySourceCommit` 构建并签名；`releaseMetadataCommit` 仅修改 `Package.swift`、`README.md`、`CONTEXT.md` 或 `docs/**` 下的发布元数据，没有改变二进制输入。公开仓必须使用冻结资产，不得以本地重打包产物替换。

## [6.2.1] - 2026-08-07

### 新增

- NativeFeed 新增可恢复列表展示契约：`YSIFLYNativeFeedDisplaySession` 表示稳定逻辑广告条目，`YSIFLYNativeFeedAdBinding` 表示一次可见 Cell 绑定；对应公开方法为 `ysifly_beginDisplaySessionWithError:`、`ysifly_attachWithViewBinder:error:`、`ysifly_detach` 和 `ysifly_endDisplaySession`。
- 同一 DisplaySession 在曝光前后均可于 Cell detach 后重新 attach 到新 Cell。曝光前重新累计连续可见时长；已曝光会话恢复原广告，但曝光回调、曝光监测、点击监测 URL 和视频节点监测仍按广告会话去重。

### 变更

- 明确列表所有权：稳定 ID 的数据模型长期持有 `Ad + DisplaySession`，复用 Cell 只持当前 `Binding`；迟到的旧 Cell detach 通过绑定代次隔离，不会误清后来挂载的新 Cell。一次性 `ysifly_bindAdWithViewBinder:error:` / `ysifly_unbindAd` 语义保持不变，不得与 DisplaySession 混用。
- 明确有效期边界：TTL 或视频 `end_time` 在活动 Binding 期间到期只会令会话不可再次挂载，不会中途强拆当前 Cell；当前 Binding 正常 detach 后，下一次 attach 返回 `YSIFLYAdErrorCodeNativeFeedAdExpired`（`71506`），媒体再结束会话、淘汰模型并请求新广告。
- NativeFeed 示例改为可滚动的 `UITableView` 复用场景，覆盖稳定条目持有、异步素材 generation 校验、UIKit 新旧 Cell 回调乱序、曝光前后恢复和过期替换流程。

### 发布说明

- 正式资产由私有源码提交 `3fcc0007b47a66d82f3134fab2a1eac58b35c94d` 使用 Xcode 26.2 构建；`Package.swift` 已回填正式签名 zip 的 checksum。二进制分发完成不代表最终宿主 App 的真机、监测入库、隐私披露或审核合规证据已经闭环。

## [6.2.0] - 2026-08-06

### 新增

- NativeFeed 公开头新增白标方法 `ysifly_reportMediaShakeTriggeredWithError:`，并同步公开 `71512`～`71515` 错误码。该方法用于统一不同分发变体的公开契约；YS `YSNoReward` 变体未启用优酷媒体摇一摇采样能力，调用固定返回 `YSIFLYAdErrorCodeNativeFeedMediaShakeUnavailable`（`71512`），不改变 YS 既有广告能力边界。

### 变更

- 外部 URL 跳转不再使用 `canOpenURL:` 预检，统一直接调用 `openURL:options:completionHandler:` 并以系统完成回调判定成功；DeepLink 失败继续回退 landing page，非法 HTTP URL、携带凭据的 URL 和危险 scheme 仍在打开前拒绝。
- `jumpDirectly` 保留为源码兼容字段，但已成为 no-op；不再影响 DeepLink 跳转路径。
- iOS 14 及以上的系统 IDFA 与媒体显式 IDFA 统一受 ATT `Authorized` 门控；IDFA 写入普通请求和 S2S 请求载荷时遵循同一规则。未授权时显式 IDFA 会被丢弃且不缓存，授权后须重新设置；撤权或回到前台发现未授权时清除缓存。
- CocoaPods 清单显式链接 `AdSupport`、弱链接 `AppTrackingTransparency`，使 ATT 类型安全调用与 iOS 11～13 启动兼容同时成立。
- 继续保持静态 XCFramework、外置 `YSAdvSDK.bundle`、开屏 / Banner / 插屏 / 自渲染信息流（含视频、无激励）交付边界。

## [6.1.0] - 2026-07-31

### 不兼容变更

- 广告响应数据改为严格白名单：开屏、Banner、插屏与 NativeFeed 的通用竞价信息仅通过 `bidInfo.price` / `bidInfo.dealId` 暴露；移除广告对象 `ecpm`，`creativeId` 只保留在 NativeFeed 的 `adData`。
- NativeFeed 移除 `rawAdData`、`sponsored`、`actionText` 等旧字段，新增服务端 `ctatext` 对应的 `ctaText` 和下载类应用名称 `appName`。
- `templateId` 不再透传服务端原始值，改为与 `materialType` 相同的归一枚举：`Unknown=0`、`SingleImage=1`、`Video=2`、`MultipleImages=3`。素材优先级为 `video → img1+img2 → img/icon → Unknown`，多图由固定三图改为两至三图。
- `interactionType` 归一为 `Unknown`、`Exposure`、`Redirect`、`Download`；仅曝光和未知广告绑定时必须显式传空 `clickViews`，不能用 `nil` 触发整容器点击兜底。

### 变更

- 自渲染信息流不再由 SDK 自动向媒体容器添加摇一摇提示 UI；点击、摇一摇/扭一扭触发、曝光与监测能力不变。
- 完善播放器容器管理、尺寸同步、解绑和视图复用清理；Demo 补齐单图/多图/视频分支、`appName` / `ctaText` 渲染、竞价字段、仅曝光绑定和视频生命周期示例。
- SwiftPM 新增 `YSIFLYADLibResources` 包装 target，随 package 自动投递外置 `YSAdvSDK.bundle` 与 `PrivacyInfo.xcprivacy`；CocoaPods 和手动集成的合并 zip 结构不变。
- 继续保持 YS 定制能力边界：开屏 / Banner / 插屏 / 自渲染信息流（含视频），无激励视频；静态 XCFramework 同时提供真机 `arm64` 和模拟器 `arm64/x86_64` 切片，最低支持 iOS 11。

## [6.0.14] - 2026-07-20

### 新增
- 插屏视频素材同时包含图片时，视频播放结束后展示图片完播页；开屏仍按原语义在视频结束后关闭，不增加完播页。
- 请求链路补齐客户端竞价时间戳、曝光宏和设备调试状态字段。

### 变更
- SDK、Podspec、Swift Package、示例工程与重新构建的 device / simulator 静态 XCFramework 最低系统统一为 iOS 11.0；历史 `6.0.13` 及更早产物不追溯扩大支持范围。
- 请求字段 `lts` 从顶层移入 `device` 对象；公开 API 签名、无激励能力边界、静态 framework 与外置资源包交付形态不变。
- 基于上游 6.0.14 重新 rebrand 构建并通过 iOS 11、公开头、资源、符号与链接门禁；`Package.swift` URL/checksum、podspec、README 和示例同步到 `6.0.14`。

## [6.0.13] - 2026-07-09

### 新增
- 自渲染信息流（NativeFeed）摇一摇提示控件：交互类型为「点击+摇一摇」的广告绑定成功后，由 SDK 自动在容器右下角添加「摇一摇查看详情」提示（避让关闭按钮、放不下则不添加、非独立点击区域，普通点击广告不展示）。
- 自渲染素材校验失败（71501）新增 error 级诊断日志（template_id / 素材类型 / 图片数 / videoURL 有无），便于定位投放侧素材配置问题。

### 说明
- 基于上游 6.0.13 重新 rebrand 构建（变体 YSNoReward 静态 framework），公开 API 签名不变；`Package.swift`(url+checksum) / `podspec` / README / 示例 Podfile 同步 `6.0.13`。
- 发布前断言：双切片均为静态归档；裸 `IFLY` 类符号、`[IFLYAd` 日志前缀、`itms-services` 字面量均为 0。

## [6.0.12] - 2026-07-08

### 变更
- **交付形态由动态 framework 切换为静态 framework**（应媒体要求）：`YSIFLYADLib.xcframework` 内为静态归档（ar archive），随 app 静态链接，无需 Embed & Sign、运行期少一个动态库加载。公开 API 与能力与 `6.0.11` 一致。
- **资源包外置**：静态 framework 不投递内嵌资源，`YSAdvSDK.bundle`（内含 Apple 隐私清单 `PrivacyInfo.xcprivacy`）改为外置随包分发——CocoaPods 经 podspec `s.resources` 自动拷入 app；SPM / 手动集成需把 bundle 加入 app target 的 Copy Bundle Resources（见 README 接入方式）。与已下线的 1.0.0（静态包但资源仍内嵌、不投递）不同，本版本资源交付路径经打包脚本断言校验（外置 bundle 非空、framework 内零残留）。
- **Release 资产结构调整**：每版本发布两个资产——合并 zip `YSIFLYADLib-<版本>.zip`（xcframework + `YSAdvSDK.bundle` + LICENSE，CocoaPods / 手动集成用）与 `YSIFLYADLib.xcframework.zip`（仅 xcframework，SPM binaryTarget 用）。

### 说明
- 基于上游 6.0.12 重新 rebrand 构建（变体 YSNoReward **静态** framework，`build-xcframework.sh --brand ys` 默认即静态，打包走新增的 `package-ys-release.sh`）；`Package.swift`(url+checksum) / `podspec`（`static_framework` + `s.resources`）/ README（接入方式含新增手动集成章节）/ CHANGELOG / 示例 Podfile 同步 `6.0.12`。
- 发布前断言：双切片均为静态归档；裸 `IFLY` 类符号、`[IFLYAd` 日志前缀、`itms-services` 字面量均为 0。

## [6.0.11] - 2026-07-08

### 修复
- **移除跳转黑名单中的 `itms-services` / `itms-apps` 字面量，改为 `itms` 前缀拦截**（随上游 IFLYADLib 6.0.11）：编译产物中不再出现 `itms-services` 完整字符串（避免被应用市场 / 审核的二进制静态扫描误判为企业分发 / 侧载），拦截行为完全不变且更严（覆盖整个 `itms` 家族）。公开 API、能力与交付形态均与 `6.0.10` 一致。

### 说明
- 基于上游 6.0.11 重新 rebrand 构建（变体 YSNoReward 动态 framework）；`Package.swift`(checksum) / `podspec` / README 版本表 / CHANGELOG / 示例 Podfile+README 同步 `6.0.11`。

## [6.0.10] - 2026-07-01

### 新增
- **自渲染信息流（NativeFeed）新增落地页关闭前回调 `ysifly_nativeFeedAdWillDismissLandingPage:`**：随上游 IFLYADLib 6.0.10，在内嵌落地页关闭动画开始前**同步**回调，作为「落地页露出前的最后确认点」，供媒体在落地页收起、广告重新露出前做最后一次确认；随后仍会照常回调 `ysifly_nativeFeedAdDidDismissLandingPage:`。为 `YSIFLYNativeFeedAdDelegate` 新增的**可选**方法。
- 基于上游 6.0.10 重新 `rebrand` 构建（变体 `YSNoReward` 动态 framework）；`Package.swift` 的 `binaryTarget` checksum 与 `YSIFLYADLib.podspec` 的 `:http` 源已同步到 `6.0.10`。
- 公开 API 其余部分 / 能力（开屏 / Banner / 插屏 / 信息流，含视频，无激励）/ 动态 framework 交付形态与 `6.0.9` 一致。

## [6.0.9] - 2026-06-30

### 变更
- **自渲染信息流（NativeFeed）放宽素材完整性判定**：随上游 IFLYADLib 6.0.9，广告标题、视频封面图均改为**非必填**；`isMaterialComplete` 仅按素材类型校验核心素材（单图 ≥1 张图 / 视频含可播放地址 / 三图 ≥3 张图），与开屏 / 插屏 / Banner 的原生视频素材口径对齐。缺标题或缺视频封面的素材不再被判为不完整而加载失败。
- **服务端竞价（S2S）测试环境域名对齐**：测试环境 `/ad/sdk-s2s/{bid,load}` 由 `sdk-grey.voiceads.cn` 对齐为 `sdk-adx.voiceads.cn`（生产环境本就为 `sdk-adx`，发布二进制无变化）。
- 基于上游 6.0.9 重新 `rebrand` 构建（变体 `YSNoReward`）；`Package.swift` 的 `binaryTarget` checksum 与 `YSIFLYADLib.podspec` 的 `:http` 源已同步到 `6.0.9`。
- 公开 API / 能力（开屏 / Banner / 插屏 / 信息流，含视频，无激励）/ 动态 framework 交付形态与 `6.0.8` 一致。

## [6.0.8] - 2026-06-22

### 变更
- **SDK 内部日志整体清除，仅保留关键节点 `error`**：随上游 IFLYADLib 6.0.8，`info` / `warn` / 调试 / JSON 日志宏整体置为无操作（不再产生任何输出），仅保留各失败关键节点的 `error` 日志（请求 / 渲染 / 播放 / 监测失败等）。**彻底解决 YS 白标变体运行期日志仍输出 `IFLY` 字眼的问题**——根因是 `rebrand` 后内部类名为 `YSIFLY*`（含 `IFLY` 子串），原 `info`/`warn` 日志经 `NSStringFromClass` 打印类名时带出；现 `error` 日志仅含错误码与脱敏文案，不打印类名或裸 `NSError`。运行期日志前缀仍为 `[YSAd]`。
- 基于上游 6.0.8 重新 `rebrand` 构建（变体 `YSNoReward`）；`Package.swift` 的 `binaryTarget` checksum 与 `YSIFLYADLib.podspec` 的 `:http` 源已同步到 `6.0.8`。
- 公开 API / 能力（开屏 / Banner / 插屏 / 信息流，含视频，无激励）/ 动态 framework 交付形态与 `6.0.7` 一致。

## [6.0.7] - 2026-06-18

### 变更
- **服务端竞价（S2S）正式环境域名切换**：随上游 IFLYADLib 6.0.7，生产环境 `/ad/sdk-s2s/bid`、`/ad/sdk-s2s/load` 地址由 `msdk.voiceads.cn` 切换为 `sdk-adx.voiceads.cn`；灰度调试地址 `sdk-grey.voiceads.cn` 不变。`PrivacyInfo.xcprivacy` 的 `NSPrivacyTrackingDomains` 新增 `sdk-adx.voiceads.cn`。
- 基于上游 6.0.7 重新 `rebrand` 构建（变体 `YSNoReward`）；`Package.swift` 的 `binaryTarget` checksum 与 `YSIFLYADLib.podspec` 的 `:http` 源已同步到 `6.0.7`。
- 公开 API / 能力（开屏 / Banner / 插屏 / 信息流，含视频，无激励）/ 动态 framework 交付形态与 `6.0.6` 一致。

## [6.0.6] - 2026-06-17

### 变更
- **SDK 内部日志精简 + 输出去 IFLY 字眼**：随上游 IFLYADLib 6.0.6，删除调试级与冗余追踪日志，移除日志中内部类名（`NSStringFromClass`）/ 裸 `NSError`（域名合成串）打印；运行期日志前缀 `[YSAd]`，无品牌名。
- 基于上游 6.0.6 重新 `rebrand` 构建；`Package.swift` 的 `binaryTarget` checksum 与 `YSIFLYADLib.podspec` 的 `:http` 源已同步到 `6.0.6`。
- 公开 API / 能力（开屏 / Banner / 插屏 / 信息流，含视频，无激励）/ 动态 framework 交付形态与 `6.0.5` 一致。

## [6.0.5] - 2026-06-17

### 变更
- **版本线对齐主 SDK**：版本号由 `1.0.x` 线切换为与上游 IFLYADLib 一致的 `6.0.5`（YS 定制白标即同一 SDK 经 `rebrand` 产出，统一版本号便于与主线对账）。
- SDK 版本号常量（随广告请求上报的 `sdk_ver`）更新为 `6.0.5`。
- 基于上游 6.0.5 重新 `rebrand` 构建（含资源加载器跨域兜底修复）；`Package.swift` 的 `binaryTarget` checksum 与 `YSIFLYADLib.podspec` 的 `:http` 源已同步到 `6.0.5`。
- 公开 API / 能力（开屏 / Banner / 插屏 / 信息流，含视频，无激励）/ 动态 framework 交付形态与 `1.0.4` 一致。

## [1.0.4] - 2026-06-16

### 修复
- **开屏「摇一摇或点击」文案左侧图标变成白色占位文件图标**（运行期缺图）。根因：改名工具链 `rebrand` 的符号发现阶段把 `NS_ENUM` 注释一起扫描，从 `IFLYAdResourceLoader.h` 注释里收割出资源名 `IFLYAd_shack` 当作符号，将代码中 `@"IFLYAd_shack"` 误改为 `@"YSIFLYAd_shack"`，而内嵌 `YSAdvSDK.bundle` 内文件仍为未改名的 `IFLYAd_shack.png` → `pathForResource` 落空 → `NSTextAttachment` 渲染为白色文件占位。影响开屏摇一摇交互按钮与 Banner 摇一摇提示两处。
- 修复后二进制资源名恢复为 `IFLYAd_shack`，与 `YSAdvSDK.bundle` 内文件一致；二进制零 `YSIFLY*` 资源名残留。

### 变更（资源分发治理，行为不变）
- 交互图标改用统一资源加载器（按域定位 + 密度选择），替换裸文件路径加载。
- 资源加载器新增跨域兜底：请求域未命中时回退其余域 bundle（修复边界资产在按格式分包下的“域内缺图”）。
- `rebrand` 应用 `resourceBundles` 域 bundle 名映射（域 bundle 名品牌化为 `YSAdvSDK*Resources`）。

### 说明
- 公开 API、能力（开屏 / Banner / 插屏 / 信息流，含视频，无激励）、动态 framework 交付形态均与 `1.0.3` 一致；本版仅为缺图修复与资源分发治理。`Package.swift` 的 `binaryTarget` checksum 与 `YSIFLYADLib.podspec` 的 `:http` 源已同步到 `1.0.4`。

## [1.0.3] - 2026-06-16

### 变更
- 运行期日志行前缀去品牌：主线 `[IFLYAd <时间戳>]` 经改名链统一为 `[YSAd <时间戳>]`（对齐公开库 6.0.4 的合规去名；主线已改为中性 `[AdSDK]`，YS 变体由 `rebrand` 去名为 `[YSAd]`）。仅日志输出文本变化，公开 API、能力（开屏 / Banner / 插屏 / 信息流，含视频，无激励）、动态 framework 交付形态均与 `1.0.2` 一致。

### 说明
- 动态 framework 二进制因日志字符串改动重建，`Package.swift` 的 `binaryTarget` checksum 与 `YSIFLYADLib.podspec` 的 `:http` 源已同步到 `1.0.3`。

## [1.0.2] - 2026-06-16

### 修复
- 改为**动态 framework** 交付，修复 1.0.1 残留空 `libPods` 悬空 `LC_LOAD_DYLIB` 依赖导致**真机启动崩溃**（动态 framework 三必备 build 设置：`MH_DYLIB` + `GCC_SYMBOLS_PRIVATE_EXTERN=NO` + `-Wl,-dead_strip_dylibs`）。
- 资源包 `YSAdvSDK.bundle` 随动态 framework 整体嵌入消费方 app，广告图片正常加载；消费方**无需 `-ObjC`**。
- 下线废弃的 1.0.0 / 1.0.1，请统一使用 1.0.2。

## [1.0.1] - 2026-06-16（已下线）

### 修复
- 由静态 framework 改为动态 framework，修复 1.0.0 静态包不投递内嵌资源包（广告图片缺失）。
- 遗留缺陷：动态 framework 残留空 `libPods` 悬空依赖致真机崩溃，已由 1.0.2 修复。

## [1.0.0] - 2026-06-16（已下线）

### 新增
- YS 媒体定制广告 SDK 首版（model B 单包）：类型名统一前缀 `YS`（如 `YSIFLYSplashAd`）、公开方法统一前缀 `ysifly_`、资源包 `YSAdvSDK.bundle`、日志前缀 `[YSAd]`。
- 缺陷：静态 framework 不投递内嵌资源包，广告图片缺失，已由后续版本修复。

[6.2.2]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2
[6.2.3]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.3
[6.2.1]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.1
[6.2.0]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.0
[6.1.0]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.1.0
[6.0.14]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.14
[6.0.13]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.13
[6.0.12]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.12
[6.0.11]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.11
[6.0.10]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.10
[6.0.9]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.9
[6.0.8]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.8
[6.0.7]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.7
[6.0.6]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.6
[6.0.5]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.5
[1.0.4]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/1.0.4
[1.0.3]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/1.0.3
[1.0.2]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/1.0.2
