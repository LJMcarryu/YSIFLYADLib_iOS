# YSIFLYADLibSimple

这是 `YSIFLYADLib` 的 iOS 接入示例工程，用于演示 YS 媒体定制 SDK 的常见广告样式和基础生命周期处理。

当前目录对应正式版本 `6.2.2`，源码和 `Podfile` 均使用 NativeFeed SDK 托管 API。
[Release 6.2.2](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2) 及其 3 项资产
已正式公开；[published CI](https://github.com/LJMcarryu/YSIFLYADLib_iOS/actions/runs/31347052226)
已通过匿名下载、远程依赖解析及 SwiftPM/CocoaPods 实际消费验证。

当前 demo 覆盖：

- 开屏广告
- Banner 广告
- 插屏广告
- 自渲染信息流广告（含 `UITableView` Cell 复用与原广告恢复）
- 信息流视频素材展示

YS 变体为 model B 单包，包含开屏、Banner、插屏、信息流和视频能力，不包含激励广告能力。本示例已移除激励视频入口和相关代码。

## 运行方式

`6.2.2` tag 与 Release 资产已对外可见，可在本目录执行：

```sh
pod install
open YSIFLYADLibSimple.xcworkspace
```

打开 workspace 后选择 `YSIFLYADLibSimple` scheme 运行。

## 接入要点

`Podfile` 已固定到 `6.2.2` tag，示例工程最低支持 iOS 11.0：

```ruby
pod 'YSIFLYADLib', :podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.2.2/YSIFLYADLib.podspec'
```

`6.2.2` 延续 `6.2.1` 的**静态 framework**交付：代码随 App 静态链接、无需 Embed；`YSAdvSDK.bundle`（含 `PrivacyInfo.xcprivacy`）由 CocoaPods podspec 或 SwiftPM 资源包装 target 自动拷入 App。最终 App 链接需要 `-ObjC`：CocoaPods podspec 同时向 pod target 与 aggregate/user target 注入，SwiftPM 和手动接入需在 App target 的 `OTHER_LDFLAGS` 添加。只有手动接入时需要自行把该 bundle 加入 Copy Bundle Resources。CocoaPods podspec 显式链接 `AdSupport`、弱链接 `AppTrackingTransparency`；SwiftPM 与手动接入依靠 XCFramework 目标文件携带的 linker options，最低 iOS 11.0 不变。

自渲染示例除延续 `6.1.0` 的严格响应数据公开契约外，还演示 `6.2.2` 的 SDK 托管列表复用生命周期：

- 通用竞价信息从 `ad.bidInfo.price/dealId` 获取，不再调用 `ecpm`。
- NativeFeed 使用 `ctaText`、`appName` 和归一后的 `templateId/materialType`；多图按两至三张处理。
- `Exposure` / `Unknown` 显式传空 `clickViews`，避免 `nil` 回退为整容器可点击。
- 数据层用稳定 ID 只持有同一个 `YSIFLYNativeFeedAd`；Cell 不持 Session、Binding 或首次/复用状态。
- Cell 展示且媒体 UI 就绪后调用 Ad `ysifly_attachWithViewBinder:error:`；在
  `didEndDisplaying` / `prepareForReuse` 通过
  `[YSIFLYNativeFeedAd ysifly_detachAdFromContainerView:containerView]` 反注册容器。
- SDK 内部处理同 Ad 串行迁移、同容器幂等、同容器新广告接管和迟到回调隔离；同一条目滚回后不重新请求广告。
- 曝光前后都可恢复原广告；已曝光逻辑广告不重复曝光。TTL / 视频 `end_time` 到期不强拆当前
  活动容器，detach 后下一次 attach 返回 `71506`，此时淘汰数据项并补请求。
- 永久淘汰或离开页面时先反注册容器、置空 delegate，再释放最后一个 Ad 强引用即可；
  `ysifly_destroy` 仅在仍持有 Ad 但希望提前取消或终止时可选调用。视频容器交给 SDK，
  不自行创建 `AVPlayer`。
- 视频 detach/attach 会保留内容进度与既有播放意图；显式 `ysifly_pausePlay` /
  `ysifly_stopPlay` 后不会因回屏自动起播，只有 `ysifly_resumePlay` /
  `ysifly_startPlay` 才重新申请播放。

从 `6.2.1` 升级到 `6.2.2` 时，须删除 DisplaySession / Binding 及旧 bind/unbind/end 调用，
改为上述 Ad attach 与容器 detach。若从 `6.1.0` 或更早版本升级，还需注意
`6.2.0` 已引入的行为变化：

- `jumpDirectly` 已成为兼容 no-op；SDK 不再使用 `canOpenURL:` 预检，DeepLink 以 `openURL` 完成回调判定，失败时仍回退 landing page。
- iOS 14 及以上只有 ATT 已授权时才接受系统或媒体显式 IDFA；授权前设置的显式值会被丢弃，授权后必须重新设置。
- NativeFeed 公开白标方法为 `ysifly_reportMediaShakeTriggeredWithError:`；YS 变体未启用优酷媒体摇一摇能力，调用返回 `NO` 和 `71512`，示例不把该方法作为摇一摇入口。

## API 命名约定

- SDK 类型使用 `YSIFLY*` 前缀，例如 `YSIFLYSplashAd`、`YSIFLYBannerAd`、`YSIFLYInterstitialAd`、`YSIFLYNativeFeedAd`。
- SDK 公开方法使用 `ysifly_*` 前缀，例如 `ysifly_loadAd`、`ysifly_showInView:`、`ysifly_destroy`。
- delegate 属性保持点语法，例如 `ad.delegate = self`。
- 初始化方法保持系统风格，例如 `initWithAdUnitId:` 不加 `ysifly_` 前缀。
- 伞头使用 `<YSIFLYADLib/YSIFLYADLib.h>`。

## 目录说明

```text
YSIFLYADLibSimple/
  YSIFLYADLibSimple.xcodeproj
  YSIFLYADLibSimple/
    AppDelegate.*
    ViewController.*
    biz/
      splash/
      banner/
      interstitial/
      native/
    Supporting Files/
  Podfile
  README.md
```
