# YSIFLYADLibSimple

这是 `YSIFLYADLib` 的 iOS 接入示例工程，用于演示 YS 媒体定制 SDK 的常见广告样式和基础生命周期处理。

当前 demo 覆盖：

- 开屏广告
- Banner 广告
- 插屏广告
- 自渲染信息流广告（含 `UITableView` Cell 复用与原广告恢复）
- 信息流视频素材展示

YS 变体为 model B 单包，包含开屏、Banner、插屏、信息流和视频能力，不包含激励广告能力。本示例已移除激励视频入口和相关代码。

## 运行方式

在本目录执行：

```sh
pod install
open YSIFLYADLibSimple.xcworkspace
```

打开 workspace 后选择 `YSIFLYADLibSimple` scheme 运行。

## 接入要点

`Podfile` 已固定到 `6.2.1` tag，示例工程最低支持 iOS 11.0：

```ruby
pod 'YSIFLYADLib', :podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.2.1/YSIFLYADLib.podspec'
```

`6.2.1` 延续 `6.2.0` 的**静态 framework**交付：代码随 App 静态链接、无需 Embed；`YSAdvSDK.bundle`（含 `PrivacyInfo.xcprivacy`）由 CocoaPods podspec 或 SwiftPM 资源包装 target 自动拷入 App。最终 App 链接需要 `-ObjC`：CocoaPods podspec 同时向 pod target 与 aggregate/user target 注入，SwiftPM 和手动接入需在 App target 的 `OTHER_LDFLAGS` 添加。只有手动接入时需要自行把该 bundle 加入 Copy Bundle Resources。CocoaPods podspec 显式链接 `AdSupport`、弱链接 `AppTrackingTransparency`；SwiftPM 与手动接入依靠 XCFramework 目标文件携带的 linker options，最低 iOS 11.0 不变。

自渲染示例除延续 `6.1.0` 的严格响应数据公开契约外，还演示 `6.2.1` 的列表复用生命周期：

- 通用竞价信息从 `ad.bidInfo.price/dealId` 获取，不再调用 `ecpm`。
- NativeFeed 使用 `ctaText`、`appName` 和归一后的 `templateId/materialType`；多图按两至三张处理。
- `Exposure` / `Unknown` 显式传空 `clickViews`，避免 `nil` 回退为整容器可点击。
- 数据层用稳定 ID 持有同一个 `YSIFLYNativeFeedAd + YSIFLYNativeFeedDisplaySession`；
  Cell 只持当前 `YSIFLYNativeFeedAdBinding`。
- Cell 在 `didEndDisplaying` / `prepareForReuse` 调用 `ysifly_detach`，同一条目滚回后重新
  `ysifly_attachWithViewBinder:error:`，不因 Cell 复用重新请求广告。
- 曝光前后都恢复原广告；已曝光会话不重复曝光。TTL / 视频 `end_time` 到期不强拆当前
  Binding，正常 detach 后下一次 attach 返回 `71506`，此时才淘汰模型并补请求。
- 永久淘汰或离开页面时依次调用 Cell `ysifly_detach`、Session
  `ysifly_endDisplaySession`、置空 delegate、Ad `ysifly_destroy`；视频容器交给 SDK，
  不自行创建 `AVPlayer`。
- 视频 detach/attach 会保留内容进度与既有播放意图；显式 `ysifly_pausePlay` /
  `ysifly_stopPlay` 后不会因回屏自动起播，只有 `ysifly_resumePlay` /
  `ysifly_startPlay` 才重新申请播放。

从 `6.1.0` 或更早版本升级到 `6.2.1` 时，除上述列表生命周期外，还需注意
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
