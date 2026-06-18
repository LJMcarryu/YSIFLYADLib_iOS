# 更新日志

本项目遵循语义化版本。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

`YSIFLYADLib` 为 YS 媒体定制白标分发仓（model B 单包整变体），由 IFLYADLib 私有 dev 仓经 `scripts/rebrand.sh --brand ys` + `build-xcframework.sh --brand ys --variant YSNoReward` 产出。变体 = Full 关闭 `REWARD`、保留 `VIDEO`：开屏 / Banner / 插屏 / 信息流（含视频），无激励视频。

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

[6.0.7]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.7
[6.0.6]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.6
[6.0.5]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.0.5
[1.0.2]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/1.0.2
