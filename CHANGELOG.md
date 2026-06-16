# 更新日志

本项目遵循语义化版本。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

`YSIFLYADLib` 为 YS 媒体定制白标分发仓（model B 单包整变体），由 IFLYADLib 私有 dev 仓经 `scripts/rebrand.sh --brand ys` + `build-xcframework.sh --brand ys --variant YSNoReward` 产出。变体 = Full 关闭 `REWARD`、保留 `VIDEO`：开屏 / Banner / 插屏 / 信息流（含视频），无激励视频。

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

[1.0.2]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/1.0.2
