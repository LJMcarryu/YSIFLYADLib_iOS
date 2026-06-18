# YSIFLYADLibSimple

这是 `YSIFLYADLib` 的 iOS 接入示例工程，用于演示 YS 媒体定制 SDK 的常见广告样式和基础生命周期处理。

当前 demo 覆盖：

- 开屏广告
- Banner 广告
- 插屏广告
- 自渲染信息流广告
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

`Podfile` 通过 GitHub Releases 上的 `YSIFLYADLib.podspec` 集成公开发布的 `6.0.7` 版本：

```ruby
pod 'YSIFLYADLib', :podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.0.7/YSIFLYADLib.podspec'
```

`6.0.7` 为**动态 framework**：资源包 `YSAdvSDK.bundle` 内嵌其中、随 framework 整体嵌入 app，广告图片可正常加载；**无需在 App target 配置 `-ObjC`**（动态 framework 会自动加载全部类与 category）。

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
