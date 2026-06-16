# YSIFLYADLib iOS SDK 接入说明

`YSIFLYADLib` 是面向 YS 媒体定制的 iOS 广告 SDK，提供开屏、Banner、插屏、自渲染信息流广告能力（**含视频**，**不含激励视频**）。

当前文档覆盖 `YSIFLYADLib 1.0.2`；可运行示例工程见 [YSIFLYADLibSimple](./YSIFLYADLibSimple)（`pod install` 后打开 `YSIFLYADLibSimple.xcworkspace`，演示开屏 / Banner / 插屏 / 自渲染信息流的加载、展示、回调、销毁）。

> 本 SDK 为定制白标构建：类型名统一前缀 `YS`（如 `YSIFLYSplashAd`），公开方法统一前缀 `ysifly_`（如 `ysifly_loadAd`），资源包为 `YSAdvSDK.bundle`（已内嵌于 framework），日志前缀 `[YSAd]`。

## 版本记录

| 版本 | 日期 | 说明 |
| --- | --- | --- |
| 1.0.2 | 2026-06-16 | 稳定版。**动态 framework**：资源包 `YSAdvSDK.bundle` 随 framework 整体嵌入 app，广告图片正常加载；消费方**无需 `-ObjC`**。开屏 / Banner / 插屏 / 自渲染信息流（含视频，无激励）。<br/>（早期 1.0.0 静态包不投递内嵌资源、1.0.1 残留空 `libPods` 悬空依赖致设备崩溃，均已下线，请用 1.0.2。） |

## 环境要求

- iOS 13.0 及以上。
- Xcode 14.1 及以上，建议使用较新 Xcode 构建。
- 交付形态：单一 `YSIFLYADLib.xcframework`（**动态 framework**，含 **device(arm64) + 模拟器(arm64/x86_64)** 切片，**可在模拟器调试**）；资源包 `YSAdvSDK.bundle` 内嵌其中，随动态 framework 整体嵌入 app。
- 统一入口头文件：`#import <YSIFLYADLib/YSIFLYADLib.h>`。
- 动态 framework 自动加载全部类/分类，**消费方无需 `-ObjC`**，也无需额外资源声明。

## CocoaPods 接入

```ruby
platform :ios, '13.0'

target 'YourApp' do
  pod 'YSIFLYADLib', :podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/1.0.2/YSIFLYADLib.podspec'
end
```

> 二进制托管在 GitHub Releases（公开可匿名下载）：podspec 的 `s.source` 指向 Release 的 `YSIFLYADLib.xcframework.zip`，CocoaPods 会自动下载解包并链接其中的 `YSIFLYADLib.xcframework`。

## Swift Package Manager 接入

在 Xcode `Add Packages…` 输入 `https://github.com/LJMcarryu/YSIFLYADLib_iOS.git`，选择 `1.0.2`；或在 `Package.swift`：

```swift
dependencies: [
    .package(url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS.git", from: "1.0.2"),
],
targets: [
    .target(name: "YourApp", dependencies: ["YSIFLYADLib"]),
]
```

> 动态 framework 由 SwiftPM 自动嵌入（含内嵌的 `YSAdvSDK.bundle`），消费方无需 `-ObjC`。

## 公开 API 速览（命名约定）

- 入口类：`YSIFLYSplashAd` / `YSIFLYBannerAd` / `YSIFLYInterstitialAd` / `YSIFLYNativeFeedAd`（无 `YSIFLYRewardVideoAd`，本变体已关闭激励）。
- 加载/展示：`ysifly_loadAd`、`ysifly_loadAdWithServerBiddingToken:`、`ysifly_showInView:`、`ysifly_showAdFromRootViewController:`、`ysifly_destroy`、`ysifly_isAdValid` 等。
- delegate 回调：统一前缀 `ysifly_`，如 `ysifly_splashAdDidLoad:`、`ysifly_splashAdDidReady:`、`ysifly_splashAd:didFailWithError:`。
- 初始化保持原名（不加前缀）：`initWithAdUnitId:` 等。
- 属性保持点语法（不加前缀）：如 `ad.delegate`、`adData.ecpm`。

### 最小示例（开屏）

```objc
#import <YSIFLYADLib/YSIFLYADLib.h>

@interface SplashVC () <YSIFLYSplashAdDelegate>
@property (nonatomic, strong) YSIFLYSplashAd *splashAd;
@end

@implementation SplashVC
- (void)load {
    self.splashAd = [[YSIFLYSplashAd alloc] initWithAdUnitId:@"<your_ad_unit_id>"];
    self.splashAd.delegate = self;
    [self.splashAd ysifly_loadAd];
}
- (void)ysifly_splashAdDidReady:(YSIFLYSplashAd *)ad {
    [ad ysifly_showAdFromRootViewController:self];
}
- (void)ysifly_splashAd:(YSIFLYSplashAd *)ad didFailWithError:(YSIFLYAdError *)error {
    NSLog(@"splash failed: %@", error);
}
@end
```

## 反馈

请在本仓 [Issues](https://github.com/LJMcarryu/YSIFLYADLib_iOS/issues) 提交问题。
