# YSIFLYADLib iOS SDK

`YSIFLYADLib` 是 YS 媒体定制的 iOS 广告 SDK，提供开屏、Banner、插屏和自渲染信息流（含视频素材）。本变体不包含激励视频。

<!-- ifly-release-status: {"schemaVersion":1,"version":"6.3.0","releaseState":"FORMAL","distribution":"github-release","releaseUrl":"https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.0"} -->

当前正式版本：[`6.3.0`](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.0)。生产项目请固定到具体版本，不要依赖 `main` 分支。

## 能力矩阵

| 能力 | 入口类 | 渲染方式 | 说明 |
| --- | --- | --- | --- |
| 开屏 | `YSIFLYSplashAd` | SDK 内置渲染 | 支持图片、视频和跳过/关闭回调 |
| Banner | `YSIFLYBannerAd` | SDK 内置渲染 | 在媒体提供的容器中展示 |
| 插屏 | `YSIFLYInterstitialAd` | SDK 内置渲染 | 支持半屏、全屏和图片/视频素材 |
| 自渲染信息流 | `YSIFLYNativeFeedAd` | 媒体渲染 UI，SDK 管理交互 | 支持单图、多图和视频 |
| 激励视频 | — | — | 本变体不提供 |

YS 版的白标命名规则是：入口类使用 `YSIFLY` 前缀，公开方法和 delegate 回调使用 `ysifly_` 前缀；初始化方法和属性保持系统风格，例如 `initWithAdUnitId:` 与 `ad.delegate`。入口头为：

```objc
#import <YSIFLYADLib/YSIFLYADLib.h>
```

所有广告对象都应强持有。回调在主线程触发；内置渲染格式等待 `ysifly_*DidReady` 后再展示。一次性展示格式在展示或关闭后请重新创建实例。

## 环境要求

- iOS 11.0 及以上。
- Xcode 15.0 及以上；SwiftPM 使用 Swift tools 5.9。
- SDK 是静态 XCFramework，最终 App 必须链接 `-ObjC`，不需要 Embed & Sign。
- 资源包为 `YSAdvSDK.bundle`。CocoaPods 和 SwiftPM 自动投递；手动集成时需复制到 App。

## 安装

### CocoaPods

```ruby
source 'https://cdn.cocoapods.org/'
platform :ios, '11.0'

target 'YourApp' do
  use_frameworks!
  pod 'YSIFLYADLib',
      :podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.3.0/YSIFLYADLib.podspec'
end
```

```bash
pod install
open YourApp.xcworkspace
```

CocoaPods 会自动复制 `YSAdvSDK.bundle` 并传播 `-ObjC`。

### Swift Package Manager

在 Xcode 中添加：

```text
https://github.com/LJMcarryu/YSIFLYADLib_iOS.git
```

选择版本 `6.3.0` 和产品 `YSIFLYADLib`。资源 target 会自动投递 `YSAdvSDK.bundle`；在 App target 的 `Other Linker Flags` 添加：

```text
-ObjC
```

### 手动集成

从 [Release 6.3.0](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.0) 下载 `YSIFLYADLib-6.3.0.zip`：

1. 将 `YSIFLYADLib.xcframework` 加入 App target，Embed 选择 **Do Not Embed**。
2. 将 `YSAdvSDK.bundle` 加入 **Copy Bundle Resources**。
3. 在 App target 的 `Other Linker Flags` 添加 `-ObjC`。
4. 导入 `<YSIFLYADLib/YSIFLYADLib.h>`。

## 初始化、隐私和请求配置

```objc
#import <YSIFLYADLib/YSIFLYADLib.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [YSIFLYAdConfig ysifly_setPersonalizedEnabled:YES];
    [YSIFLYAdConfig ysifly_setLogEnabled:NO];
    return YES;
}
```

`ysifly_setPersonalizedEnabled:` 只记录媒体侧个性化状态，不替代 ATT，也不会自行修改 IDFA、CAID、填充或点击行为。正式上线建议关闭日志。

### ATT 和 IDFA

iOS 14 及以上如需使用 IDFA：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>用于获取广告标识符 IDFA，以便请求和展示相关广告。</string>
```

只有 ATT 状态为 `authorized` 时才读取或传入 IDFA。授权前传入的值会被丢弃；授权完成后请重新读取。宿主仍须在 App Store Connect 隐私标签中合并申报 SDK 的实际数据处理。

### 请求配置

```objc
- (YSIFLYAdRequestConfig *)requestConfig {
    YSIFLYAdRequestConfig *config = [[YSIFLYAdRequestConfig alloc] init];
    config.requestTimeout = @5;
    config.appName = NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
    config.appVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    config.settleType = @1;      // 0=固定价格，1=RTB
    config.bidFloor = @0.01;     // CNY 元/千次展示
    config.interactStatus = @1;  // 1=开启，2=关闭
    return config;
}
```

常用字段包括 `requestId`、`requestTimeout`、`appName`、`appVersion`、`userAgent`、`idfa`、`caidList`、`settleType`、`bidFloor`、`pmpDeals`、`landingPageTransitionType`、`landingPageAutorotateType` 和 `deepLinkDisabled`。广告对象可调用 `ysifly_loadAd` 或：

```objc
[ad ysifly_loadAdWithRequestConfig:[self requestConfig]];
```

点击、DeepLink、落地页和失败回退由 SDK 统一处理；历史 `jumpDirectly` 字段仅为兼容保留，不应用来控制业务跳转。

## 开屏广告

```objc
@interface SplashViewController () <YSIFLYSplashAdDelegate>
@property (nonatomic, strong) YSIFLYSplashAd *splashAd;
@end

- (void)loadSplash {
    YSIFLYSplashAd *ad = [[YSIFLYSplashAd alloc] initWithAdUnitId:@"YOUR_SPLASH_AD_UNIT_ID"];
    ad.delegate = self;
    ad.currentViewController = self;
    self.splashAd = ad;
    [ad ysifly_loadAdWithRequestConfig:[self requestConfig]];
}

- (void)ysifly_splashAdDidReady:(YSIFLYSplashAd *)ad {
    if (ad != self.splashAd || ![ad ysifly_isAdValid]) return;
    YSIFLYSplashAdConfig *config = [[YSIFLYSplashAdConfig alloc] init];
    config.traceDuration = 5;
    config.muteOnStart = YES;
    [ad ysifly_showAdFromRootViewController:self config:config];
}

- (void)ysifly_splashAd:(YSIFLYSplashAd *)ad didFailWithError:(YSIFLYAdError *)error {
    NSLog(@"Splash failed: %d %@", error.errorCode, error.errorDescription);
}
```

等待 `ysifly_splashAdDidReady:` 后展示；常用回调还有 `ysifly_splashAdDidLoad:`、`DidShow`、`DidExpose`、`DidClick`、`DidClose`、`DidSkip` 和失败回调。

## Banner 广告

容器应在布局完成后传入，宽度必须大于 0。

```objc
@interface BannerViewController () <YSIFLYBannerAdDelegate>
@property (nonatomic, strong) YSIFLYBannerAd *bannerAd;
@property (nonatomic, strong) UIView *bannerContainer;
@end

- (void)loadBanner {
    YSIFLYBannerAd *ad = [[YSIFLYBannerAd alloc] initWithAdUnitId:@"YOUR_BANNER_AD_UNIT_ID"];
    ad.delegate = self;
    ad.currentViewController = self;
    ad.closeButtonVisible = YES;
    self.bannerAd = ad;
    [ad ysifly_loadAdWithRequestConfig:[self requestConfig]];
}

- (void)ysifly_bannerAdDidReady:(YSIFLYBannerAd *)ad {
    if (ad == self.bannerAd && [ad ysifly_isAdValid]) {
        [ad ysifly_showInView:self.bannerContainer];
    }
}
```

一个 Banner 实例展示后不要重复加载；需要新机会时重新创建。

## 插屏广告

```objc
@interface InterstitialViewController () <YSIFLYInterstitialAdDelegate>
@property (nonatomic, strong) YSIFLYInterstitialAd *interstitialAd;
@end

- (void)loadInterstitial {
    YSIFLYInterstitialAd *ad = [[YSIFLYInterstitialAd alloc] initWithAdUnitId:@"YOUR_INTERSTITIAL_AD_UNIT_ID"];
    ad.delegate = self;
    ad.currentViewController = self;
    self.interstitialAd = ad;
    [ad ysifly_loadAdWithRequestConfig:[self requestConfig]];
}

- (void)ysifly_interstitialAdDidReady:(YSIFLYInterstitialAd *)ad {
    if (ad != self.interstitialAd || ![ad ysifly_isAdValid]) return;
    YSIFLYInterstitialAdConfig *config = [[YSIFLYInterstitialAdConfig alloc] init];
    config.presentationStyle = YSIFLYInterstitialPresentationStyleHalfScreen;
    config.muteOnStart = YES;
    [ad ysifly_showAdFromRootViewController:self config:config];
}
```

可选 `YSIFLYInterstitialPresentationStyleHalfScreen` 或 `YSIFLYInterstitialPresentationStyleFullScreen`。展示或关闭后请重新创建实例。

## 自渲染信息流

媒体根据 `ad.adData` 渲染标题、图片、视频和 CTA，SDK 负责曝光、点击、跳转、关闭、监测和播放器。加载成功后在主线程同步绑定：

```objc
@interface NativeFeedViewController () <YSIFLYNativeFeedAdDelegate>
@property (nonatomic, strong) YSIFLYNativeFeedAd *nativeAd;
@property (nonatomic, strong) UIView *adContainer;
@end

- (void)loadNativeFeed {
    YSIFLYNativeFeedAd *ad = [[YSIFLYNativeFeedAd alloc] initWithAdUnitId:@"YOUR_NATIVE_FEED_AD_UNIT_ID"];
    ad.delegate = self;
    ad.currentViewController = self;
    ad.muteOnStart = YES;
    self.nativeAd = ad;
    [ad ysifly_loadAdWithRequestConfig:[self requestConfig]];
}

- (void)ysifly_nativeFeedAdDidLoad:(YSIFLYNativeFeedAd *)ad {
    if (ad != self.nativeAd || ![ad.adData ysifly_isMaterialComplete]) return;

    // 先根据 ad.adData 完成媒体 UI，再组装 Binder。
    YSIFLYNativeFeedAdViewBinder *binder = [[YSIFLYNativeFeedAdViewBinder alloc] init];
    binder.containerView = self.adContainer;
    binder.renderViews = @[/* 标题、图片/视频、CTA 等媒体视图 */];
    binder.clickViews = @[/* Redirect/Download 的点击视图；Exposure/Unknown 传 @[] */];
    binder.videoView = /* 视频素材使用普通 UIView；非视频传 nil */ nil;

    YSIFLYAdError *error = nil;
    if (![ad ysifly_attachWithViewBinder:binder error:&error]) {
        NSLog(@"NativeFeed attach failed: %d %@", error.errorCode, error.errorDescription);
    }
}

- (void)leaveScreen {
    [YSIFLYNativeFeedAd ysifly_detachAdFromContainerView:self.adContainer];
}
```

接入规则：

- `ysifly_attachWithViewBinder:error:` 必须在主线程同步调用；`containerView` 必填，视频素材必须提供普通 `UIView` 作为 `videoView`。
- `interactionType` 为 `Exposure` 或 `Unknown` 时，`clickViews` 传 `@[]`；为 `Redirect` 或 `Download` 时只传实际点击视图。
- 如确需在容器外放置 CTA，显式设置 `binder.allowsExternalClickViews = YES`，并保证 CTA 与广告处于同一 window/scene、可见且可交互。常规接入优先让 CTA 位于容器内。
- Cell 离屏、复用或切换普通内容时，调用 `ysifly_detachAdFromContainerView:` 反注册具体容器，不要按旧 `indexPath` 反查广告。
- 列表数据层持有 `YSIFLYNativeFeedAd`，Cell 只负责渲染和 attach/detach。条目暂时离屏可以继续持有同一 Ad；永久删除或退出页面时 detach、置空 delegate 并释放 Ad。
- SDK 管理视频播放器。绑定且曝光后可用 `ysifly_startPlay`、`ysifly_pausePlay`、`ysifly_resumePlay`、`ysifly_stopPlay` 控制播放。

常用 `adData` 字段：`materialType`、`templateId`、`title`、`desc`、`content`、`ctaText`、`brand`、`appName`、`icon`、`mainImage`、`imageList`、`imageURLs`、`videoURL`、`videoCoverURL`、`videoDuration`、`targetURL`、`deeplinkURL`、`marketURL`、`downloadURL`、`packageName`、`interactionType` 和 `interactType`。点击和跳转由 SDK 处理，媒体不要自行打开 URL。

NativeFeed 回调包括 `ysifly_nativeFeedAdDidLoad:`、`DidRender`、`DidExpose`、`DidClick`、`DidJump`、`DidClose`、`didFailWithError:` 和 `didFailToRenderWithError:`；视频素材还会触发播放状态回调。YS 变体不提供优酷专用的媒体摇一摇能力。

### 列表复用

数据项只持有广告对象，Cell 只在自己的容器上执行绑定和解绑：

```objc
- (void)configureCell:(YSIFLYNativeFeedCell *)cell withAd:(YSIFLYNativeFeedAd *)ad {
    [YSIFLYNativeFeedAd ysifly_detachAdFromContainerView:cell.adContainerView];
    [cell renderAdData:ad.adData];
    YSIFLYAdError *error = nil;
    [ad ysifly_attachWithViewBinder:[cell viewBinder] error:&error];
}

- (void)prepareCellForReuse:(YSIFLYNativeFeedCell *)cell {
    [YSIFLYNativeFeedAd ysifly_detachAdFromContainerView:cell.adContainerView];
    [cell resetMediaViews];
}
```

同一逻辑广告回到屏幕时可以再次 attach；如果广告已经失效，应释放旧对象并为相同业务条目请求新广告。

## S2S 和 Header Bidding

如平台已开通服务端竞价：

```objc
NSError *error = nil;
NSString *sdkToken = [YSIFLYAdSDK ysifly_getSdkTokenWithAdUnitId:@"YOUR_AD_UNIT_ID" error:&error];
[ad ysifly_loadAdWithServerBiddingToken:rspToken];
```

加载成功后从公开竞价字段读取价格和订单号：

```objc
NSNumber *price = ad.bidInfo.price;
NSString *dealId = ad.bidInfo.dealId;
[ad ysifly_sendBidResultWithType:YSIFLYAdBidResultTypeWin reason:@"win"];
```

Token、通知时机和失败重试按平台协议执行；未开通时直接使用普通 `ysifly_loadAd`。

## 错误处理和生命周期

错误通过 `YSIFLYAdError` 回调。无填充、网络错误、超时、素材不完整和容器无效时，结束当前实例并按业务策略重试，避免无限重试。

- `ysifly_*AdDidLoad:`：响应解析成功，素材可能仍在下载。
- `ysifly_*AdDidReady:`：内置渲染主素材已就绪，可以展示；NativeFeed 在 `DidLoad` 后自渲染并 attach。
- `ysifly_isAdValid`：展示前检查实例状态。
- `ysifly_destroy`：主动终止仍被持有的实例；NativeFeed 列表离屏通常只需 detach。
- 页面退出时置空 delegate、解绑 NativeFeed 容器并释放广告对象。

## 示例工程

`YSIFLYADLibSimple` 只使用公开 API，包含开屏、Banner、插屏和 NativeFeed 示例；不包含激励视频。

```bash
cd YSIFLYADLibSimple
pod install
open YSIFLYADLibSimple.xcworkspace
```

请替换示例广告位 ID，并在获得隐私同意后加载广告。Demo 的构建成功只表示包能够被正确消费和链接，不代表线上一定有填充。

## 常见问题

| 问题 | 处理方式 |
| --- | --- |
| 找不到 `YSIFLYRewardVideoAd` | YS 变体不包含激励视频，这是能力边界；请使用支持 Reward 的产品。 |
| `-ObjC` 缺失 | 在最终 App target 的 `Other Linker Flags` 添加 `-ObjC`。 |
| 信息流绑定失败 | 确认主线程调用、`containerView` 非空、视频传入 `videoView`，并让 `clickViews` 与 `interactionType` 匹配。 |
| Banner 不展示 | 确认容器已布局且宽度大于 0，并在 `ysifly_*AdDidReady:` 后展示。 |
| IDFA 为空 | 检查 ATT 授权和说明字段；授权完成后重新读取，过滤全零 UUID。 |
| 信息流回屏为空 | 数据层继续持有同一 Ad，Cell 复用时只 detach/attach，不要按 indexPath 重新取广告。 |

## 反馈与支持

请在 [Issues](https://github.com/LJMcarryu/YSIFLYADLib_iOS/issues) 提交问题，并附 SDK 版本、iOS/Xcode 版本、接入方式、复现步骤和错误回调。版本变更见 [`CHANGELOG.md`](./CHANGELOG.md)。
