# 更新日志

## [6.5.1] - 发布说明

<!-- ifly-release-status: {"version":"6.5.1","status":"FAST_UNVERIFIED","distribution":"tos","releaseUrl":"https://download-adsdk.voiceads.cn/ios_sdk/6.5.1/ys/fast-release-record.json"} -->

本版尚未完成安装、构建与广告展示验证，请先在宿主 App 中联调。

## [6.5.0] - 更新说明

> `6.5.0` 已验证 CocoaPods、SwiftPM 的安装、版本锁定与模拟器构建；真机广告展示需在宿主 App 中联调。



> 以下为历史版本记录，验收结论仅适用于各节明确列出的历史版本。

## [6.4.6] - TOS 分发

调整 SDK 下载分发，安装入口保持不变。

下载文件与校验值见[版本下载记录](https://download-adsdk.voiceads.cn/ios_sdk/6.4.6/ys/release-record.json)。


## [6.4.4] - 发布工程优化

<a id="变更"></a>

优化 SDK 分发。公开 API、广告形式和最低系统要求保持不变。


## [6.4.2] - 冻结与发布记录

更新 SDK 分发。


## [6.4.1] - 发布工程优化

<a id="变更-1"></a>
<a id="变更-2"></a>

优化 SDK 分发。


## [6.4.0] - 冻结与发布记录

<a id="变更-3"></a>

优化多窗口场景下的广告展示与页面返回。

开屏 `customWindow` 须与宿主页面处于同一 Scene，并保持可见、尺寸有效。


## [6.3.5] - 2026-09-14

优化广告加载、展示及视频播放。


## [6.3.1] - 2026-09-01

优化广告加载与诊断信息。


## [6.3.0] - 2026-08-25

优化 NativeFeed 视图绑定、点击交互与页面跳转。


## [6.2.4] - 2026-08-17

优化 NativeFeed 视图绑定与点击处理。


## [6.2.3] - 2026-08-16

NativeFeed 新增 `allowsExternalClickViews`，默认 `NO`；需要外部点击视图时显式开启。

新增 `ysifly_detachFromCurrentContainer` 便利方法。


## [6.2.2] - 2026-08-10

<a id="发布事实"></a>
<a id="变更-4"></a>
<a id="不兼容调整"></a>
<a id="分发边界"></a>

NativeFeed 改用 Ad 级 `ysifly_attachWithViewBinder:error:` 挂载、容器级 `ysifly_detachAdFromContainerView:` 解绑；数据层持有 Ad，Cell 离屏或复用时解绑。

移除 `YSIFLYNativeFeedDisplaySession`、`YSIFLYNativeFeedAdBinding`、`ysifly_beginDisplaySessionWithError:`、`ysifly_bindAdWithViewBinder:error:`、`ysifly_unbindAd` 和 `ysifly_endDisplaySession`。从旧版升级须替换相关调用并重新编译。


## [6.2.1] - 2026-08-07

<a id="新增"></a>
<a id="变更-5"></a>
<a id="发布说明"></a>

NativeFeed 新增 `YSIFLYNativeFeedDisplaySession`、`YSIFLYNativeFeedAdBinding` 及列表展示接口，支持 Cell 复用。

旧的 `ysifly_bindAdWithViewBinder:error:` / `ysifly_unbindAd` 用于固定卡片，两种接入方式不能在同一广告实例混用。


## [6.2.0] - 2026-08-06

<a id="新增-1"></a>
<a id="新增-2"></a>
<a id="变更-6"></a>

优化请求与跳转处理。

`jumpDirectly` 保留兼容，设置该属性不再影响跳转行为。

iOS 14 及以上传入 IDFA 前须取得 ATT 授权；授权后需要显式传入 IDFA 时，请重新读取并设置。


## [6.1.0] - 2026-07-31

<a id="不兼容变更"></a>
<a id="变更-7"></a>

调整竞价和 NativeFeed 接口；竞价信息使用 `bidInfo.price` / `bidInfo.dealId`，素材文案使用 `ctaText`，新增 `appName`。

移除 `ecpm`、`rawAdData`、`sponsored`、`actionText` 等旧公开字段。`templateId/materialType`、`interactionType` 须按新版枚举接入；仅曝光或未知交互须显式传空 `clickViews`。升级须修改相关调用并重新编译。

完善 SwiftPM 资源集成与接入示例。


## [6.0.14] - 2026-07-20

<a id="新增-3"></a>
<a id="变更-8"></a>

最低支持系统调整为 iOS 11.0。

完善视频完播页，优化广告请求。


## [6.0.13] - 2026-07-09

<a id="新增-4"></a>
<a id="说明"></a>

优化 NativeFeed 展示与素材处理。


## [6.0.12] - 2026-07-08

<a id="变更-9"></a>
<a id="说明-1"></a>
<a id="说明-2"></a>

改用静态 framework，无需 Embed & Sign。

`YSAdvSDK.bundle` 改为外置资源；CocoaPods 自动加入，SwiftPM 和手动集成须加入 App target 的 Copy Bundle Resources。


## [6.0.11] - 2026-07-08

<a id="修复"></a>
<a id="说明-3"></a>

优化广告跳转。


## [6.0.10] - 2026-07-01

<a id="新增-5"></a>

NativeFeed 新增可选回调 `ysifly_nativeFeedAdWillDismissLandingPage:`，用于在落地页开始关闭前处理宿主页面；原有关闭完成回调保留。


## [6.0.9] - 2026-06-30

<a id="变更-10"></a>

优化 NativeFeed 素材兼容性与竞价处理。


## [6.0.8] - 2026-06-22

<a id="变更-11"></a>

优化日志处理。


## [6.0.7] - 2026-06-18

<a id="变更-12"></a>

优化服务端竞价接入。


## [6.0.6] - 2026-06-17

<a id="变更-13"></a>

优化日志处理。


## [6.0.5] - 2026-06-17

<a id="变更-14"></a>

版本号调整为 `6.0.5`，优化资源加载。


## [1.0.4] - 2026-06-16

<a id="修复-1"></a>
<a id="修复-2"></a>
<a id="变更资源分发治理行为不变"></a>
<a id="变更（资源分发治理，行为不变）"></a>
<a id="说明-4"></a>

修复广告图标显示问题，优化资源加载。


## [1.0.3] - 2026-06-16

<a id="变更-15"></a>
<a id="说明-5"></a>

调整日志输出。


## [1.0.2] - 2026-06-16

<a id="修复-3"></a>

修复真机启动与资源显示问题，改用动态 framework 交付。

`1.0.0` / `1.0.1` 已停止使用，请升级到后续可用版本。


## [1.0.1] - 2026-06-16（已下线）

<a id="修复-4"></a>

调整交付方式。该版本已停止使用，请升级到后续可用版本。


## [1.0.0] - 2026-06-16（已下线）

<a id="新增-6"></a>

首次提供 YS 定制 SDK。该版本已停止使用，请升级到后续可用版本。


[6.2.2]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2
[6.3.0]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.0
[6.2.4]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.4
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
[6.3.5]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.5
[6.3.1]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.1
[1.0.1]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/1.0.1
[1.0.0]: https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/1.0.0
