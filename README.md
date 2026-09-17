# YS 广告 iOS SDK

`YSIFLYADLib` 为 YS 媒体提供开屏、Banner、插屏和自渲染信息流，支持信息流单图、多图和视频素材，不包含激励广告。当前正式版本为 [6.3.5](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.5)，最低支持 iOS 11.0。

<!-- ifly-release-status: {"schemaVersion":1,"version":"6.3.5","releaseState":"FORMAL","distribution":"github-release","releaseUrl":"https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.5"} -->

## 6.3.6 候选联调说明

`6.3.6` 目前是待联调候选，尚未发布。当前公开正式版和生产依赖仍为 [`6.3.5`](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.5)；已发布的 Tag、Release 和资产不追溯改变。

- 公开 API 方法签名不变。
- 共享 UIScene 适配将展示、落地页、外跳回流、曝光判断和 UI 生命周期绑定到广告的实际来源 window/Scene。没有来源时，仅在前台应用 Scene 唯一且明确时兜底，不跨 Scene 随机选择；独立落地页始终属于来源 Scene。
- 开屏的 rootVC 仍须已经入窗。在 Scene 宿主中使用 `customWindow` 时，窗口必须可见、尺寸有限且为正、已经关联 Scene，并与 `rootVC.window` 属于同一 Scene；它可以不是 key window，可以使用较高 `windowLevel`，也可以不设置 rootVC。输入无效时展示失败，修正窗口后可重试。

首次体验从[示例运行指南](YSIFLYADLibSimple/README.md)开始；接入自己的 App 按本文安装和选择广告形式；升级时查阅[更新记录](CHANGELOG.md)。API 以所安装版本的 framework 公开头为准。

## 能力与环境

| 广告形式 | 入口类 | 渲染与展示 |
| --- | --- | --- |
| 开屏 | `YSIFLYSplashAd` | SDK 展示图片/视频，支持品牌区、跳过和倒计时 |
| Banner | `YSIFLYBannerAd` | SDK 在宿主容器中展示 |
| 插屏 | `YSIFLYInterstitialAd` | SDK 展示半屏/全屏图片或视频 |
| 自渲染信息流 | `YSIFLYNativeFeedAd` | 媒体渲染单图、多图或视频容器，SDK 处理交互与视频播放 |

- iOS 11.0+；SwiftPM 清单要求 Swift tools 5.9。
- 静态 XCFramework，包含设备与模拟器切片，App 链接需 `-ObjC`，不需 Embed & Sign。
- CocoaPods / SwiftPM 产品与模块均为 `YSIFLYADLib`，资源包为 `YSAdvSDK.bundle`。
- 类型使用 `YSIFLY` 前缀，公开方法和 delegate 回调使用 `ysifly_` 前缀；初始化方法和属性不加此前缀，如 `initWithAdUnitId:`、`ad.delegate`。

本包与 `YSIFLYADLibSplash` 使用相同模块、类型及资源，同一 App 只能选择一个 YS 包。迁移时移除旧依赖和重复资源。

## 安装

三种方式选择一种，生产项目固定到正式版本 `6.3.5`。

### CocoaPods

```ruby
source 'https://cdn.cocoapods.org/'
platform :ios, '11.0'

target 'YourApp' do
  use_frameworks!
  pod 'YSIFLYADLib',
      :podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.3.5/YSIFLYADLib.podspec'
end
```

```bash
pod install
open YourApp.xcworkspace
```

此版本使用上述 Podspec URL 安装，无需依赖 CocoaPods trunk 收录。CocoaPods 自动加入资源、`-ObjC` 和所需系统库；安装后始终打开 `.xcworkspace`。

### Swift Package Manager

在 Xcode 的 **Add Package Dependencies** 添加：

```text
https://github.com/LJMcarryu/YSIFLYADLib_iOS.git
```

选择 **Exact Version** `6.3.5`，将产品 `YSIFLYADLib` 加入 App target；在该 target 的 **Other Linker Flags** 保留 `$(inherited)` 并添加 `-ObjC`。SwiftPM 自动投递 `YSAdvSDK.bundle`。

### 手动集成

从 [Release 6.3.5](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.3.5) 下载 `YSIFLYADLib-6.3.5.zip`：

1. 将 `YSIFLYADLib.xcframework` 加入 App target，选择 **Do Not Embed**。
2. 将 `YSAdvSDK.bundle` 加入 **Copy Bundle Resources**，确认最终 App 只有一份。
3. 在 App target 的 **Other Linker Flags** 添加 `$(inherited) -ObjC`。
4. 链接 `AdSupport.framework`，将 `AppTrackingTransparency.framework` 设为 **Optional**，兼容 iOS 11～13。

三种方式统一导入：

```objc
#import <YSIFLYADLib/YSIFLYADLib.h>
```

## 请求与通用生命周期

SDK 无需额外 App ID 初始化。完成宿主隐私流程后，新建具体广告对象、设置 delegate 并强持有它，再调用 `ysifly_loadAd` 或 `ysifly_loadAdWithRequestConfig:`。广告位由平台分配，应与当前 App 和广告形式匹配。

常用请求配置可以封装为函数；各广告对象均可使用返回值：

```objc
static YSIFLYAdRequestConfig *MakeAdRequestConfig(void) {
    YSIFLYAdRequestConfig *config = [[YSIFLYAdRequestConfig alloc] init];
    config.requestTimeout = @5;
    config.appName = NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
    config.appVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    return config;
}
```

`settleType`（`0` 固定价格、`1` RTB）、`bidFloor`（CNY 元/千次展示）、`interactStatus`（`1` 开启、`2` 关闭）按平台接入约定设置。`idfa` 仅传授权后的有效值；`deepLinkDisabled` 可控制是否尝试 DeepLink。请求参数通过 `YSIFLYAdRequestConfig` 设置；展示尺寸、静音和倒计时使用各格式的展示配置。

| 事件/动作 | 接入规则 |
| --- | --- |
| `DidLoad` | 响应解析成功，可读 `bidInfo`；内置渲染格式尚须等待素材就绪 |
| `DidReady` | 开屏、Banner、插屏主素材就绪，可以结合宿主状态判断是否展示 |
| NativeFeed `DidLoad` | 可读 `adData`；媒体完成 UI 后 attach，没有 Ready 回调 |
| `ysifly_isAdValid` | 展示或新挂载前检查有效性；不能替代 Ready、布局或宿主可见性判断 |
| `ysifly_destroy` | 取消/结束当前对象，销毁后不能重新加载；NativeFeed 临时离屏使用 detach |

公开 delegate 回调在主线程触发。UI 和挂载操作放在主线程；异步回调须先判断回调对象仍是当前广告。开屏、Banner、插屏成功展示后需要新建实例获取下一次广告机会。媒体永久结束广告流程时置空 delegate、清理容器并释放对象；不要因为广告打开了落地页就提前销毁仍在使用的对象。

## 开屏广告

以下类可放入 `.m` 文件，替换广告位后在宿主适当时机调用 `loadSplash`。完整的手动加载、品牌区和日志页面见 [开屏示例](YSIFLYADLibSimple/YSIFLYADLibSimple/biz/splash/YSIFLYSplashViewController.m)。

```objc
#import <YSIFLYADLib/YSIFLYADLib.h>

@interface SplashExampleViewController : UIViewController <YSIFLYSplashAdDelegate>
@property (nonatomic, strong) YSIFLYSplashAd *splashAd;
@end

@implementation SplashExampleViewController

// 在宿主隐私流程完成、页面可展示时调用。
- (void)loadSplash {
    [self clearSplash];
    self.splashAd = [[YSIFLYSplashAd alloc] initWithAdUnitId:@"YOUR_SPLASH_AD_UNIT_ID"];
    self.splashAd.delegate = self;
    self.splashAd.currentViewController = self;
    YSIFLYAdRequestConfig *request = [[YSIFLYAdRequestConfig alloc] init];
    request.requestTimeout = @5;
    [self.splashAd ysifly_loadAdWithRequestConfig:request];
}

- (void)ysifly_splashAdDidReady:(YSIFLYSplashAd *)ad {
    if (ad != self.splashAd || ![ad ysifly_isAdValid] || !self.view.window) return;
    YSIFLYSplashAdConfig *config = [[YSIFLYSplashAdConfig alloc] init];
    config.traceDuration = 5;
    config.muteOnStart = YES;
    config.muteButtonHidden = NO;
    [ad ysifly_showAdFromRootViewController:self config:config];
}

- (void)ysifly_splashAd:(YSIFLYSplashAd *)ad didFailWithError:(YSIFLYAdError *)error {
    if (ad != self.splashAd) return;
    NSLog(@"Splash failed: %d %@", error.errorCode, error.errorDescription);
    [self clearSplash]; // 宿主在此继续主流程，避免失败后停在启动页。
}

- (void)ysifly_splashAdDidClose:(YSIFLYSplashAd *)ad {
    if (ad == self.splashAd) [self clearSplash];
}

- (void)ysifly_splashAdDidSkip:(YSIFLYSplashAd *)ad {
    if (ad == self.splashAd) [self clearSplash];
}

- (void)clearSplash {
    self.splashAd.delegate = nil;
    [self.splashAd ysifly_destroy];
    self.splashAd = nil;
}

- (void)dealloc {
    [self.splashAd ysifly_destroy];
}
@end
```
### 展示配置与回调

| 配置/回调 | 含义与接入动作 |
| --- | --- |
| `traceDuration` | 倒计时秒数，有效范围 3～5；默认 5，越界回退为 5 |
| `mediumBottomView` | 宿主品牌区，需由媒体设置视图高度；示例提供 Logo 区域 |
| `customWindow` | 可选展示窗口；默认使用传入控制器所属 window |
| `muteOnStart` / `muteButtonHidden` | 视频初始静音状态、静音按钮是否隐藏 |
| `ysifly_splashAdDidLoad:` | 响应解析成功，可读 `bidInfo` 和 `hasVideoTemplate`，尚不能据此展示 |
| `ysifly_splashAdDidReady:` | 主素材已就绪；检查广告有效性与宿主可展示状态 |
| `ysifly_splashAdDidShow:` / `ysifly_splashAdDidExpose:` | 已显示到 window / 已达到有效曝光，是两个事件 |
| `ysifly_splashAdDidSkip:` | 用户点击跳过，广告关闭 |
| `ysifly_splashAdDidClose:` | 倒计时结束并关闭；不要把视频完播或跳转等同于本回调 |
| `ysifly_splashAd:didJumpWithSuccess:` | 点击跳转结果；SDK 负责跳转及回退，媒体不要再次打开链接 |
| `ysifly_splashAdDidPlayFinish:` | 视频播放完成，广告仍可保留末帧与交互，不表示关闭 |
| `ysifly_splashAd:didFailWithError:` | 统一加载/展示失败出口，记录错误并继续宿主流程 |

回调在主线程触发。强持有广告对象，并在展示前核对回调中的对象是否仍是当前实例。展示时传入已加入 window 的控制器；SDK 将开屏覆盖到窗口，无需宿主另外 `present` 广告控制器。

`ysifly_isAdValid` 仅表示实例当前是否可展示，不代替 Ready 和宿主可见性判断。成功展示后需要新建实例发起下一次请求。取消请求、宿主永久结束广告流程或释放页面时调用 `ysifly_destroy`；销毁后该对象不可恢复。不要仅因为广告打开了落地页就销毁仍在使用的广告。

## Banner 广告

媒体提供已布局且宽高有效的容器，并强持有广告。以下类在 `loadBanner` 中创建容器；实际业务可换为页面已有容器：

```objc
@interface BannerExampleViewController : UIViewController <YSIFLYBannerAdDelegate>
@property (nonatomic, strong) YSIFLYBannerAd *bannerAd;
@property (nonatomic, strong) UIView *bannerContainer;
@end

@implementation BannerExampleViewController
- (void)loadBanner {
    self.bannerAd.delegate = nil;
    [self.bannerAd ysifly_destroy];
    if (!self.bannerContainer) {
        self.bannerContainer = [[UIView alloc] initWithFrame:CGRectMake(16, 120, 288, 90)];
        [self.view addSubview:self.bannerContainer];
    }
    self.bannerAd = [[YSIFLYBannerAd alloc] initWithAdUnitId:@"YOUR_BANNER_AD_UNIT_ID"];
    self.bannerAd.delegate = self;
    self.bannerAd.currentViewController = self;
    self.bannerAd.closeButtonVisible = YES;
    [self.bannerAd ysifly_loadAd];
}
- (void)ysifly_bannerAdDidReady:(YSIFLYBannerAd *)ad {
    if (ad == self.bannerAd && [ad ysifly_isAdValid] && self.view.window) {
        [ad ysifly_showInView:self.bannerContainer];
    }
}
- (void)ysifly_bannerAd:(YSIFLYBannerAd *)ad didFailWithError:(YSIFLYAdError *)error {
    NSLog(@"Banner failed: %d %@", error.errorCode, error.errorDescription);
}
- (void)dealloc {
    [self.bannerAd ysifly_destroy];
}
@end
```

不要在同一 Banner 上循环 load/show；刷新广告时清理旧实例、创建新实例。容器布局与失败、关闭回调的完整处理见 [Banner 示例](YSIFLYADLibSimple/YSIFLYADLibSimple/biz/banner/YSIFLYBannerViewController.m)。

## 插屏广告

在已有业务页面新建并持有插屏，收到 Ready 后在合适的业务间隙展示：

```objc
@interface InterstitialExampleViewController : UIViewController <YSIFLYInterstitialAdDelegate>
@property (nonatomic, strong) YSIFLYInterstitialAd *interstitialAd;
@end

@implementation InterstitialExampleViewController
- (void)loadInterstitial {
    self.interstitialAd.delegate = nil;
    [self.interstitialAd ysifly_destroy];
    self.interstitialAd = [[YSIFLYInterstitialAd alloc] initWithAdUnitId:@"YOUR_INTERSTITIAL_AD_UNIT_ID"];
    self.interstitialAd.delegate = self;
    self.interstitialAd.currentViewController = self;
    [self.interstitialAd ysifly_loadAd];
}
- (void)ysifly_interstitialAdDidReady:(YSIFLYInterstitialAd *)ad {
    if (ad != self.interstitialAd || ![ad ysifly_isAdValid] || !self.view.window) return;
    YSIFLYInterstitialAdConfig *config = [[YSIFLYInterstitialAdConfig alloc] init];
    config.presentationStyle = YSIFLYInterstitialPresentationStyleHalfScreen;
    config.muteOnStart = YES;
    [ad ysifly_showAdFromRootViewController:self config:config];
}
- (void)ysifly_interstitialAd:(YSIFLYInterstitialAd *)ad didFailWithError:(YSIFLYAdError *)error {
    NSLog(@"Interstitial failed: %d %@", error.errorCode, error.errorDescription);
}
- (void)dealloc {
    [self.interstitialAd ysifly_destroy];
}
@end
```

`presentationStyle` 可选 `YSIFLYInterstitialPresentationStyleHalfScreen` 或 `YSIFLYInterstitialPresentationStyleFullScreen`。展示前确认页面可见且没有冲突的模态展示；完整控制和日志见 [插屏示例](YSIFLYADLibSimple/YSIFLYADLibSimple/biz/interstitial/YSIFLYInterstitialViewController.m)。

## 自渲染信息流

媒体负责依据 `ad.adData` 创建标题、图片、广告标识、CTA、关闭按钮和视频容器。SDK 负责广告请求、曝光、点击跳转及视频播放。强持有 `YSIFLYNativeFeedAd` 并设置 delegate 后调用 `ysifly_loadAd`；收到 `ysifly_nativeFeedAdDidLoad:` 后渲染媒体 UI，再调用 `ysifly_attachWithViewBinder:error:`。

### 素材和视图

| 公开数据/视图 | 接入方式 |
| --- | --- |
| `materialType` / `templateId` | `0` 未知、`1` 单图、`2` 视频、`3` 多图；未知素材不展示 |
| `title`、`desc`、`content`、`ctaText`、`appName` | 按实际非空字段布局，不假设每个文案都有值 |
| `mainImage` / `imageList` | 媒体加载图片并处理失败；多图为两至三张 |
| `videoURL` / `videoCoverURL` | 视频交给 SDK 播放，封面可由媒体展示 |
| `adSourceMark` / `brand` | 渲染广告来源与广告标识 |
| `containerView` | 广告整体容器，必须有效且按实际素材完成布局 |
| `renderViews` | 已渲染的广告素材视图；与关闭、视频视图均位于容器内 |
| `videoView` | 视频必填，用普通 `UIView` 承载 SDK 视频，无需创建 `AVPlayer` |
| `clickViews` | `Redirect` / `Download` 传实际点击视图；`Exposure` / `Unknown` 明确传 `@[]` |

下面的辅助函数放入媒体 `.m` 文件，在素材 UI 就绪后调用。传入的视图须已由媒体创建并放在 `container` 中；视频时 `videoView` 必填，可点击素材的 `clickViews` 必须非空。

```objc
static BOOL AttachNativeAd(YSIFLYNativeFeedAd *ad,
                           UIView *container,
                           NSArray<UIView *> *renderViews,
                           NSArray<UIView *> *clickViews,
                           UIView *videoView,
                           UIView *closeView,
                           YSIFLYAdError **error) {
    YSIFLYNativeFeedAdViewBinder *binder = [[YSIFLYNativeFeedAdViewBinder alloc] init];
    binder.containerView = container;
    binder.renderViews = renderViews;
    BOOL clickable = ad.adData.interactionType == YSIFLYNativeFeedAdInteractionTypeRedirect ||
                     ad.adData.interactionType == YSIFLYNativeFeedAdInteractionTypeDownload;
    binder.clickViews = clickable ? clickViews : @[];
    binder.videoView = videoView;
    binder.closeView = closeView;
    return [ad ysifly_attachWithViewBinder:binder error:error];
}
```

必须在主线程同步 attach，检查返回值和 `YSIFLYAdError`。`clickViews = nil` 会回退为整容器可点击，因此无点击行为应显式传空数组。SDK 负责跳转与失败回退，媒体不要对注册的 CTA 再添加自己的跳转或手动打开素材 URL。

### 列表复用和视频

- 数据项强持有同一个 Ad；Cell 只渲染并挂载。`didEndDisplaying`、`prepareForReuse` 或换普通内容时，对回调提供的具体 Cell 容器同步调用 `+[YSIFLYNativeFeedAd ysifly_detachAdFromContainerView:]`。
- detach 解除视图挂载，保留数据项中的广告；滚回屏幕后可再次 attach。同一逻辑广告不会因为滚回重复曝光。不要按旧 `indexPath` 反查广告，也不要延迟执行解绑。
- `ysifly_detachFromCurrentContainer` 只用于固定、非复用且不迁移的单容器；列表必须按具体容器解绑。
- 永久删除条目或退出页面时先 detach、置空 delegate，再释放最后一个 Ad 强引用；仍持有对象但希望主动终止时可调用 `ysifly_destroy`。
- 广告过期后不能新挂载；遇到 `71506` 应淘汰旧条目并请求新广告。不能将一次 attach 失败简单等同于整个列表不可用。
- 视频离屏/回屏可保留进度和播放意图。`ysifly_pausePlay` / `ysifly_stopPlay` 后，不会仅因回屏自动恢复；需要 `ysifly_resumePlay` / `ysifly_startPlay` 请求播放，实际起播仍须满足已挂载、已曝光等条件。

完整的异步图片加载、视频容器、Cell 复用和错误处理见 [信息流示例](YSIFLYADLibSimple/YSIFLYADLibSimple/biz/native/YSIFLYNativeViewController.m)。

### 容器外 CTA

默认 `allowsExternalClickViews = NO`。确需把 CTA 放到广告容器外时显式设为 `YES`；只放宽点击视图，渲染、关闭和视频视图仍须在容器中。

外部 CTA 可在 attach 后挂载或布局；实际点击时须与广告处于同一 window/scene，可见、可交互且尺寸有效，广告容器处于前台并至少有 `2/3` 可见。CTA 不能是 window、页面根视图或容器本身；不要让多个活动广告共享同一个 CTA。调整已挂载的点击视图集合或内外层级关系时，先 detach 再 attach。

拒绝点击通过 `ysifly_nativeFeedAd:didRejectClickWithError:` 返回 `YSIFLYAdErrorCodeNativeFeedClickViewsInvalid`（`71503`）。根据 `errorDescription` 中的 `[71503/<point>]` 定位视图问题；不要用手工曝光、补跳转或重复点击绕过拒绝。

YS 不提供媒体主动上报摇一摇点击的能力，`ysifly_reportMediaShakeTriggeredWithError:` 返回 `NO` 和 `71512`，不要把该方法作为此版本的摇一摇入口。

## S2S 和 Header Bidding

普通广告请求不需要 S2S。平台已开通服务端竞价时：

1. 用 `YSIFLYAdSDK` 的 `ysifly_getSdkTokenWithAdUnitId:error:` 生成请求 Token，并交给媒体服务端。
2. 服务端返回竞价胜出的响应 Token 后，创建对应广告对象，设置 delegate 并强持有，调用 `ysifly_loadAdWithServerBiddingToken:`。
3. 按对应广告格式的 Ready 或 NativeFeed UI/attach 流程展示。请求 Token 与响应 Token 不可互换，响应 Token 不可重复消费；同一实例不要混用普通与 S2S 加载。

普通请求成功后通过 `ad.bidInfo.price` / `ad.bidInfo.dealId` 读取公开竞价信息；按平台协议调用 `ysifly_sendBidResultWithType:reason:` 上报竞胜、竞败等结果，不要把每次 DidLoad 都上报为竞胜。S2S 成功后的 `bidInfo.price` 固定为 `0`，实际竞价结果以服务端为准。

## 资源、隐私与网络

`YSAdvSDK.bundle` 包含广告所需资源及 `PrivacyInfo.xcprivacy`。CocoaPods / SwiftPM 会自动复制，手动集成需自行加入 App；不要同时使用多种安装方式或重复拷贝。宿主须结合实际功能填写自己的隐私说明和 App Store Connect 隐私标签。

SDK 无需额外 App ID 初始化。可在请求前通过 `YSIFLYAdConfig` 设置日志与个性化状态：`ysifly_setLogEnabled:` 用于排错，`ysifly_setPersonalizedEnabled:` **仅记录选择，不改变数据处理、请求、填充、展示或点击行为**。宿主应按自身授权流程控制何时使用 SDK，不能将状态开关当作停止采集或停止广告的控制器。

iOS 14 及以上如需 IDFA，宿主必须配置准确的 `NSUserTrackingUsageDescription`，在合适时机通过 `ATTrackingManager` 申请授权；只有 `authorized` 时才读取或传入 IDFA。未授权时传入的 IDFA 会被丢弃，授权后须重新读取并设置。示例中的授权和过滤逻辑见 Simple 的 `AppDelegate`、`YSIFLYADUtil`。

SDK 允许 HTTP 素材、监测地址和落地页，实际访问仍受宿主 ATS 策略影响。Simple 的网络例外用于联调；生产 App 应按实际域名和网络需求配置，优先使用 HTTPS。

正式上线建议关闭 SDK 日志；临时打开日志用于错误诊断，不要记录或公开完整 Token、设备标识或未脱敏请求。

## 错误处理与常见问题

在加载、渲染和交互失败回调中记录 `errorCode` 与 `errorDescription`，按业务策略决定结束当前机会或有限次重试，避免无间隔重试。

| 错误/现象 | 处理方法 |
| --- | --- |
| `70204` 无填充 | 核对广告位及后台投放状态，继续宿主流程；示例 ID 不保证填充 |
| `70400` / `71005` | 广告位无效 / 为空，替换为分配给当前 App 的对应格式广告位 |
| `71003` / `71006` | 网络错误 / 超时，记录错误并按业务节奏重试 |
| `71304` / `71309` | Banner 容器无效 / 布局超时，检查容器宽高与布局时机 |
| `71406` / `71603` | 插屏 / 开屏未就绪，应等待 Ready 并检查有效性 |
| `71502` / `71504` | 信息流广告容器 / 视频容器无效，检查视图与素材类型 |
| `71503` | 点击视图无效，检查 `interactionType`、点击集合、外部 CTA 可见性及错误 point |
| `71506` | 信息流过期，清理旧条目并重新请求 |
| 模块或头文件找不到 | 检查安装结果、模块名，CocoaPods 工程使用 workspace |
| duplicate symbols / 重复资源 | 不要同时安装两个 YS 包或混合手工、Pods、SwiftPM 依赖 |
| 内置格式 DidLoad 后空白 | DidLoad 不等于 Ready；查看素材失败回调并确认有效展示容器 |
| 信息流回屏为空 | 保留数据项中的同一 Ad，离屏按容器 detach；过期对象重新请求 |
| IDFA 为空 | 未授权 ATT 时为空是预期行为；授权后重新读取并用于新请求 |

反馈请使用 [Issues](https://github.com/LJMcarryu/YSIFLYADLib_iOS/issues)，提供 SDK/iOS/Xcode 版本、接入方式、设备、复现步骤、错误码及脱敏日志。安装、各页面操作与成功标准见[示例运行指南](YSIFLYADLibSimple/README.md)。

历史版本下载：[6.2.2](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2)、[6.2.3](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.3)。升级前请核对 [CHANGELOG](CHANGELOG.md) 中的兼容变化；新项目使用上文当前版本。
