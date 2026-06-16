# YSIFLYADLib iOS SDK 接入说明

`YSIFLYADLib` 是面向 YS 媒体定制的 iOS 广告 SDK，提供开屏、Banner、插屏、自渲染信息流广告能力（**含视频**，**不含激励视频**）。

当前文档覆盖 `YSIFLYADLib 1.0.0`。

> 本 SDK 为定制白标构建：类型名统一前缀 `YS`（如 `YSIFLYSplashAd`），公开方法统一前缀 `ysifly_`（如 `ysifly_loadAd`），资源包为 `YSAdvSDK.bundle`（已内嵌于 framework），日志前缀 `[YSAd]`。

## 版本记录

| 版本 | 日期 | 说明 |
| --- | --- | --- |
| 1.0.0 | 2026-06-16 | 首个 YS 定制版（model B 单包整变体）：开屏 / Banner / 插屏 / 自渲染信息流，含视频，**关闭激励视频**；含 device + 模拟器双切片。 |

## 环境要求

- iOS 13.0 及以上。
- Xcode 14.1 及以上，建议使用较新 Xcode 构建。
- 交付形态：单一 `YSIFLYADLib.xcframework`（含 **device(arm64) + 模拟器(arm64/x86_64)** 切片，**可在模拟器调试**）；资源包 `YSAdvSDK.bundle` 已内嵌其中。
- 统一入口头文件：`#import <YSIFLYADLib/YSIFLYADLib.h>`。
- 静态库内含 OC category / `+load`，**消费方 App target 必须在 `OTHER_LDFLAGS` 加入 `-ObjC`**。

## CocoaPods 接入

```ruby
platform :ios, '13.0'

target 'YourApp' do
  pod 'YSIFLYADLib', :podspec => 'https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/1.0.0/YSIFLYADLib.podspec'
  # 或在拿到本仓访问权后用 :git
  # pod 'YSIFLYADLib', :git => 'https://github.com/LJMcarryu/YSIFLYADLib_iOS.git', :tag => '1.0.0'
end
```

> 本仓为私有分发仓；如用 `:http`/`:git` 拉取 Release 资产，请确保已获得仓库访问授权（GitHub token）。

## Swift Package Manager 接入

在 Xcode `Add Packages…` 输入 `https://github.com/LJMcarryu/YSIFLYADLib_iOS.git`，选择 `1.0.0`；或在 `Package.swift`：

```swift
dependencies: [
    .package(url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS.git", from: "1.0.0"),
],
targets: [
    .target(name: "YourApp", dependencies: ["YSIFLYADLib"]),
]
```

> SwiftPM 不便自动注入 `-ObjC`，请在 App target 的 **Build Settings → Other Linker Flags** 手动加 `-ObjC`。

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
