# YSIFLYADLib iOS SDK 接入说明

`YSIFLYADLib` 是面向 YS 媒体定制的 iOS 广告 SDK，提供**开屏、Banner、插屏、自渲染信息流**广告能力（**含视频素材**，**不含激励视频**）。

当前文档覆盖 `YSIFLYADLib 6.0.14`，最低支持 iOS 11.0；可运行示例工程见 [YSIFLYADLibSimple](./YSIFLYADLibSimple)（`pod install` 后打开 `YSIFLYADLibSimple.xcworkspace`，演示开屏 / Banner / 插屏 / 自渲染信息流的加载、展示、回调、销毁）。

仓库地址：[https://github.com/LJMcarryu/YSIFLYADLib_iOS](https://github.com/LJMcarryu/YSIFLYADLib_iOS)

> **本 SDK 为 YS 媒体定制白标构建**，与标准版命名不同，接入时请严格按本文档：
> - 入口类统一前缀 `YS`，如 `YSIFLYSplashAd`、`YSIFLYBannerAd`。
> - 公开方法统一前缀 `ysifly_`，如 `ysifly_loadAd`、`ysifly_showInView:`、`ysifly_destroy`。
> - delegate 回调统一前缀 `ysifly_`，如 `ysifly_splashAdDidReady:`。
> - 初始化方法、属性保持系统风格（**不**加前缀）：`initWithAdUnitId:`、`ad.delegate`、`adData.price`。
> - 伞头入口：`#import <YSIFLYADLib/YSIFLYADLib.h>`；资源包 `YSAdvSDK.bundle`（**外置随包分发**，CocoaPods 自动投递，SPM/手动集成需加入 app target，见接入方式）；运行期日志前缀 `[YSAd]`。

---

## 目录

- [版本记录](#版本记录)
- [环境要求](#环境要求)
- [接入方式](#接入方式)
  - [CocoaPods](#cocoapods)
  - [Swift Package Manager](#swift-package-manager)
  - [手动集成](#手动集成)
- [权限与隐私配置](#权限与隐私配置)
- [SDK 全局配置](#sdk-全局配置)
- [统一请求配置](#统一请求配置)
- [开屏广告](#开屏广告)
- [Banner 广告](#banner-广告)
- [插屏广告](#插屏广告)
- [自渲染信息流广告](#自渲染信息流广告)
- [S2S 服务端竞价](#s2s-服务端竞价)
- [Header Bidding 结果通知](#header-bidding-结果通知)
- [错误处理与常见问题](#错误处理与常见问题)
- [公开 API 速览](#公开-api-速览)
- [接入建议](#接入建议)
- [问题反馈与支持](#问题反馈与支持)

---

## 版本记录

| 版本 | 日期 | 说明 |
| --- | --- | --- |
| 6.0.14 | 2026-07-20 | 最低系统版本由 iOS 13.0 下调为 iOS 11.0，device / simulator 静态 XCFramework 重新构建并通过最低版本门禁；插屏视频在服务端同时下发图片时于视频完播后展示图片完播页（开屏保持原关闭语义）；请求字段 `lts` 移入 `device`，补齐分格式点击回调丢弃、客户端竞价时间戳/曝光宏和设备调试状态字段。公开 API 签名、无激励能力边界和静态交付形态不变。 |
| 6.0.13 | 2026-07-09 | 自渲染信息流（NativeFeed）新增摇一摇提示控件：交互类型为「点击+摇一摇」的广告绑定成功后，由 SDK 自动在容器右下角添加「摇一摇查看详情」提示（避让关闭按钮、放不下则不添加、非独立点击区域，普通点击广告不展示）；自渲染素材校验失败（71501）新增 error 级诊断日志。公开 API 签名不变（随上游 6.0.13），能力与交付形态与 6.0.13 一致。 |
| 6.0.12 | 2026-07-08 | **交付形态由动态 framework 切换为静态 framework**（应媒体要求）：`YSIFLYADLib.xcframework` 内为静态归档，随 app 静态链接，**无需 Embed**、少一个动态库加载；资源包 `YSAdvSDK.bundle`（含隐私清单 `PrivacyInfo.xcprivacy`）改为**外置随包分发**——CocoaPods 经 podspec `s.resources` 自动拷入 app，SPM / 手动集成需把 bundle 加入 app target（见接入方式）。与已下线的早期 1.0.0 不同：1.0.0 是「静态包 + 资源仍内嵌」导致资源不投递；6.0.12 资源外置交付，广告图片、摇一摇图标等资源加载正常。公开 API 与能力与 6.0.11 一致。 |
| 6.0.11 | 2026-07-08 | 移除跳转黑名单中 `itms-services` / `itms-apps` 字面量，改为 `itms` 前缀拦截（随上游 6.0.11）：编译产物不再出现 `itms-services` 完整字符串（避免应用市场 / 审核静态扫描误判为企业分发 / 侧载），拦截行为不变且更严。公开 API、能力与交付形态与 6.0.10 一致。 |
| 6.0.10 | 2026-07-01 | 自渲染信息流（NativeFeed）新增可选回调 `ysifly_nativeFeedAdWillDismissLandingPage:`：内嵌落地页关闭动画开始前**同步**回调，作为「落地页露出前的最后确认点」，随后仍照常回调 `ysifly_nativeFeedAdDidDismissLandingPage:`。公开 API 其余部分、能力与交付形态与 6.0.9 一致。 |
| 6.0.9 | 2026-06-30 | 自渲染信息流（NativeFeed）放宽素材完整性：广告标题、视频封面均**非必填**，仅要求核心素材齐备（单图 ≥1 图 / 视频含可播放地址 / 三图 ≥3 图）；S2S 测试环境域名对齐 `sdk-adx`。公开 API、能力与交付形态与 6.0.8 一致。 |
| 6.0.8 | 2026-06-22 | SDK 内部日志整体清除，仅保留关键节点 `error`（移除 `info`/`warn`/调试/JSON 日志）。公开 API、能力与交付形态与 6.0.7 一致。 |
| 6.0.7 | 2026-06-18 | 服务端竞价（S2S）正式环境域名切换；隐私清单新增该域。公开 API、能力与交付形态与 6.0.6 一致。 |
| 6.0.6 | 2026-06-17 | SDK 内部日志精简；公开 API、能力与交付形态与 6.0.5 一致。 |
| 6.0.5 | 2026-06-17 | 版本线对齐上游主 SDK 6.0.5（同一 SDK 经 rebrand 产出） |
| 1.0.4 | 2026-06-16 | 修复开屏「摇一摇或点击」文案左侧图标显示为白色占位文件图标；附带资源分发治理（统一加载器/跨域兜底/域 bundle 名品牌化）。公开 API、能力与交付形态与 1.0.3 一致。 |
| 1.0.3 | 2026-06-16 | 运行期日志前缀统一为 `[YSAd]`；公开 API、能力与交付形态与 1.0.2 一致，二进制仅日志字符串变化。 |
| 1.0.2 | 2026-06-16 | 稳定基线。**动态 framework** 交付：`YSAdvSDK.bundle` 随 framework 整体嵌入 app，广告图片正常加载；消费方**无需 `-ObjC`**。 |

> 早期 `1.0.0`（静态包不投递内嵌资源，广告图片缺失）、`1.0.1`（残留空 `libPods` 悬空依赖致真机崩溃）均已下线，请勿使用，统一接入 **1.0.2 及以上**。

---

## 环境要求

- **iOS 11.0** 及以上（从 `6.0.14` 起；历史 `6.0.13` 及更早二进制不追溯扩大支持范围）。
- **Xcode 14.1** 及以上，建议使用较新 Xcode 构建。
- **交付形态**（6.0.12 起）：单一 `YSIFLYADLib.xcframework`（**静态 framework**），含 **真机 `arm64` + 模拟器 `arm64`/`x86_64`** 切片，**可直接在模拟器调试**；代码随 app 静态链接，**无需 Embed & Sign**。
- 资源包 `YSAdvSDK.bundle`（内含隐私清单 `PrivacyInfo.xcprivacy`）**外置随包分发**：CocoaPods 接入自动投递；SPM / 手动集成需把 bundle 加入 app target 的 Copy Bundle Resources。
- **无需配置 `-ObjC`**：SDK 无独立 category 编译单元（category 均随宿主类目标文件链入）。
- 统一入口头：`#import <YSIFLYADLib/YSIFLYADLib.h>`。

---

## 接入方式

二进制托管在本仓 **GitHub Releases**（公开可匿名下载），每个版本发布两个资产：

| 资产 | 内容 | 适用 |
| --- | --- | --- |
| `YSIFLYADLib-<版本>.zip`（合并 zip） | `YSIFLYADLib.xcframework` + `YSAdvSDK.bundle` + `LICENSE` | CocoaPods（podspec 指向它）、手动集成 |
| `YSIFLYADLib.xcframework.zip` | 仅 `YSIFLYADLib.xcframework` | Swift Package Manager（binaryTarget） |

推荐 **CocoaPods** 接入：资源包投递全自动，升级只改一处 tag。

### CocoaPods

在 `Podfile` 中通过 Release 上的 `YSIFLYADLib.podspec`（raw URL）直连接入：

```ruby
source 'https://cdn.cocoapods.org/'
platform :ios, '11.0'

target 'YourApp' do
  use_frameworks!

  pod 'YSIFLYADLib', :podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.0.14/YSIFLYADLib.podspec'
end
```

安装：

```bash
pod install
open YourApp.xcworkspace
```

> 说明：
> - `:podspec` 指向 tag `6.0.14` 的 raw podspec，其 `s.source` 是 Release 的合并 zip（`YSIFLYADLib-6.0.14.zip`），CocoaPods 会自动下载解包、链接其中的静态 `YSIFLYADLib.xcframework`，并把 `YSAdvSDK.bundle`（含隐私清单）**自动拷入 app 主包**（podspec 已声明 `s.resources`）。
> - **请把 URL 钉死到具体 tag（如 `6.0.14`），不要指向分支**；升级版本时同步改 URL 里的 tag。
> - 静态 framework 随 app 链接，pod 不会（也不需要）Embed；**无需手动加 `-ObjC`**、无需手动拷贝 `.bundle`。

### Swift Package Manager

在 Xcode「**File → Add Packages…**」填入仓库地址，选择版本 `6.0.14`：

```
https://github.com/LJMcarryu/YSIFLYADLib_iOS.git
```

或在 `Package.swift` 中声明：

```swift
dependencies: [
    .package(url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS.git", from: "6.0.14"),
],
targets: [
    .target(name: "YourApp", dependencies: ["YSIFLYADLib"]),
]
```

> **SPM 接入须额外手动加资源包**（SwiftPM 的 `binaryTarget` 无法携带资源）：
> 1. 从 Release 下载同版本合并 zip（`YSIFLYADLib-6.0.14.zip`）并解压；
> 2. 把其中的 `YSAdvSDK.bundle` 拖入 Xcode 工程，勾选 **Copy items if needed** 并加入 app target（确认出现在 Build Phases → Copy Bundle Resources）。
>
> 缺少该步骤时 SDK 可正常编译链接，但广告图片、摇一摇图标等资源会缺失，且 app 缺 SDK 隐私清单。代码链接无需 `-ObjC`。

### 手动集成

不便使用包管理器时，直接集成 Release 合并 zip（`YSIFLYADLib-6.0.14.zip`）内容：

1. 解压得到 `YSIFLYADLib.xcframework` 与 `YSAdvSDK.bundle`；
2. 把 `YSIFLYADLib.xcframework` 拖入工程，General → Frameworks, Libraries, and Embedded Content 中 Embed 选 **Do Not Embed**（静态库随 app 链接，无需嵌入）；
3. 把 `YSAdvSDK.bundle` 拖入工程并加入 app target（Build Phases → Copy Bundle Resources）；
4. 无需 `-ObjC`；若工程已全局开启 `-ObjC`/`-all_load` 亦兼容。

---

## 权限与隐私配置

### 隐私清单（PrivacyInfo.xcprivacy）

SDK 的 Apple 隐私清单 `PrivacyInfo.xcprivacy` 随 `YSAdvSDK.bundle` 交付（CocoaPods 接入自动带入；SPM / 手动集成在把 bundle 加入 app target 后即带入，Apple 会扫描 app 内 bundle 中的隐私清单）。**接入方仍须在 App Store Connect 的隐私「营养标签」中如实合并声明以下数据收集，并据 `NSPrivacyTracking = YES` 提供 ATT 授权（见下）。**

- **追踪**：`NSPrivacyTracking = YES`；追踪域名：`voiceads.cn`、`bjimp.voiceads.cn`、`ai.voiceads.cn`、`msdk.voiceads.cn`、`caid-api.adn-plus.com.cn`。
- **收集的数据类型**：设备 ID（DeviceID）、产品交互（ProductInteraction）、广告数据（AdvertisingData）——均关联用户且用于追踪，用途为第三方广告与分析；其他诊断数据（OtherDiagnosticData）——不关联、不用于追踪，用途为 App 功能与分析。
- **Required Reason API**：UserDefaults（`CA92.1`）、文件时间戳（`C617.1`）、系统启动时间（`35F9.1`）、磁盘可用空间（`E174.1`）。

### ATT 与 IDFA

iOS 14 及以上读取 IDFA 前必须先请求 App Tracking Transparency 权限。宿主 App 需在 `Info.plist` 中添加：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>用于获取广告标识符 IDFA，以便请求和展示相关广告。</string>
```

建议在 App 进入前台后请求 ATT，再发起广告加载：

```objc
#import <AppTrackingTransparency/AppTrackingTransparency.h>

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (@available(iOS 14, *)) {
        if (ATTrackingManager.trackingAuthorizationStatus == ATTrackingManagerAuthorizationStatusNotDetermined) {
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                NSLog(@"ATT status: %ld", (long)status);
            }];
        }
    }
}
```

媒体侧如需显式传入真实 IDFA，可在授权后读取系统 IDFA，写入 `YSIFLYAdRequestConfig.idfa`：

```objc
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>

- (NSString *)currentIDFAString {
    if (@available(iOS 14, *)) {
        if (ATTrackingManager.trackingAuthorizationStatus != ATTrackingManagerAuthorizationStatusAuthorized) {
            return nil;
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (!ASIdentifierManager.sharedManager.advertisingTrackingEnabled) {
            return nil;
        }
#pragma clang diagnostic pop
    }

    NSString *idfa = ASIdentifierManager.sharedManager.advertisingIdentifier.UUIDString;
    if (idfa.length == 0 || [[idfa lowercaseString] isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
        return nil;
    }
    return idfa;
}
```

注意：

- ATT 已允许不等于请求参数里一定有 IDFA，需在授权完成后再读取系统 IDFA。
- 请勿在正式媒体 App 中使用固定测试 IDFA。
- 若用户在系统设置中关闭"允许 App 请求跟踪"，IDFA 仍可能为空或全零。

---

## SDK 全局配置

在广告请求前设置 SDK 全局配置（类方法，无需实例化）：

```objc
#import <YSIFLYADLib/YSIFLYADLib.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [YSIFLYAdConfig ysifly_setPersonalizedEnabled:YES];   // 个性化状态记录
    [YSIFLYAdConfig ysifly_setLogEnabled:NO];             // 正式上线建议关闭日志
    return YES;
}
```

- `ysifly_setPersonalizedEnabled:` 当前用于**记录**媒体侧个性化状态，不会自动过滤或改写 IDFA、CAID、UA、设备信息、广告填充、展示、点击或监测行为。
- `ysifly_setLogEnabled:` 控制日志输出（前缀 `[YSAd]`）：Debug 默认开启、Release 默认关闭；Release 下传 `YES` 可强制开启用于排查。正式发布请关闭。自 `6.0.10` 起 SDK 内部日志仅保留**关键节点 `error`**（请求 / 渲染 / 播放 / 监测失败等），`info` / `warn` / 调试 / JSON 日志已整体移除（即便开启也不输出），且不打印内部类名（含 `YSIFLY*`）或裸 `NSError`。
- 查询当前状态：`+[YSIFLYAdConfig ysifly_isPersonalizedEnabled]`、`+[YSIFLYAdConfig ysifly_isLogEnabled]`。
- 查询 SDK 版本：`[YSIFLYAdTool ysifly_sdkVersion]`。

---

## 统一请求配置

四类广告都可使用 `YSIFLYAdRequestConfig` 传入请求期参数：

```objc
- (YSIFLYAdRequestConfig *)requestConfig {
    YSIFLYAdRequestConfig *config = [[YSIFLYAdRequestConfig alloc] init];
    config.settleType = @1;          // 0=固定价格，1=RTB
    config.bidFloor = @0.01;         // 单位 CNY 元/千次展示
    config.interactStatus = @1;      // 1=开启互动，2=关闭互动
    config.requestTimeout = @5;      // 秒
    config.appName = NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"];
    config.appVersion = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    config.idfa = [self currentIDFAString];
    return config;
}
```

常用字段：

| 字段 | 说明 |
| --- | --- |
| `requestId` | 广告请求 ID；不设置时 SDK 自动生成。 |
| `settleType` | 交易方式：`0` 固定价格，`1` RTB。 |
| `bidFloor` | 竞价底价，单位 CNY 元/千次展示。 |
| `interactStatus` | 广告位互动状态：`1` 开启，`2` 关闭。 |
| `pmpDeals` | PMP 订单信息数组。 |
| `appName` / `appVersion` | 宿主 App 名称和版本号。 |
| `requestTimeout` | 请求超时时间，单位秒。 |
| `userAgent` | 自定义浏览器 User-Agent。 |
| `idfa` | 媒体侧显式传入的 IDFA。 |
| `caidList` | 媒体侧显式传入的 CAID 列表（每项含 `ver`、`caid`）。 |
| `landingPageTransitionType` | 落地页跳转动画：`0` 右滑入，`1` 底部滑入。 |
| `landingPageAutorotateType` | 落地页旋转方式：`0` 仅竖屏…`3` 全方向。 |
| `jumpDirectly` | DeepLink 是否跳过 `canOpenURL` 直接跳转。 |
| `deepLinkDisabled` | 是否禁用 DeepLink。 |

加载广告时调用：

```objc
[ad ysifly_loadAdWithRequestConfig:[self requestConfig]];
```

若请求参数未被 `YSIFLYAdRequestConfig` 覆盖，可用基类扩展方法写入协议字段（键名见 `IFLYAdKeys.h` 中的 `YSIFLYAdKey` 常量）：

```objc
[ad ysifly_setParamValue:value forKey:YSIFLYAdKeyIDFA];
```

主流程建议优先使用 `YSIFLYAdRequestConfig`。

---

## 开屏广告

典型流程：创建实例 → 设置 `delegate` → `ysifly_loadAdWithRequestConfig:` → 等待 `ysifly_splashAdDidReady:` → `ysifly_showAdFromRootViewController:config:` → `ysifly_destroy`。

```objc
@interface SplashViewController () <YSIFLYSplashAdDelegate>
@property (nonatomic, strong) YSIFLYSplashAd *splashAd;
@end

@implementation SplashViewController

- (void)loadSplash {
    YSIFLYSplashAd *ad = [[YSIFLYSplashAd alloc] initWithAdUnitId:@"YOUR_SPLASH_AD_UNIT_ID"];
    ad.delegate = self;
    ad.currentViewController = self;
    self.splashAd = ad;

    [ad ysifly_loadAdWithRequestConfig:[self requestConfig]];
}

- (void)ysifly_splashAdDidReady:(YSIFLYSplashAd *)ad {
    if (![ad ysifly_isAdValid]) {
        return;
    }

    YSIFLYSplashAdConfig *config = [[YSIFLYSplashAdConfig alloc] init];
    config.traceDuration = 5;                 // 倒计时 3~5 秒
    config.mediumBottomView = [self logoBottomView];
    config.muteOnStart = YES;

    [ad ysifly_showAdFromRootViewController:self config:config];
}

- (void)ysifly_splashAd:(YSIFLYSplashAd *)ad didFailWithError:(YSIFLYAdError *)error {
    NSLog(@"Splash failed: %d %@", error.errorCode, error.errorDescription);
}

- (void)dealloc {
    [_splashAd ysifly_destroy];
}

@end
```

常用回调：

- `ysifly_splashAdDidLoad:`：广告响应解析成功，主素材可能仍在下载。
- `ysifly_splashAdDidReady:`：主素材就绪，可展示。
- `ysifly_splashAdDidShow:` / `ysifly_splashAdDidExpose:` / `ysifly_splashAdDidClick:`：展示、曝光、点击。
- `ysifly_splashAdDidClose:` / `ysifly_splashAdDidSkip:`：倒计时结束 / 用户跳过关闭。
- `ysifly_splashAd:didFailWithError:`：加载或展示失败。
- 视频开屏额外有 `ysifly_splashAdDidStartPlay:`、`ysifly_splashAdDidPlayFinish:` 等播放回调。

`YSIFLYSplashAdConfig` 关键字段：`traceDuration`（倒计时 3~5 秒）、`mediumBottomView`（底部 Logo 视图）、`customWindow`（自定义承载窗口）、`muteOnStart`（视频静音）、`headingInteractionEnabled`（YES 时摇一摇降级为扭一扭）。

---

## Banner 广告

典型流程：创建实例 → 设置 `delegate` → `ysifly_loadAdWithRequestConfig:` → 等待 `ysifly_bannerAdDidReady:` → `ysifly_showInView:`。

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
    if ([ad ysifly_isAdValid]) {
        [ad ysifly_showInView:self.bannerContainer];
    }
}

- (void)ysifly_bannerAd:(YSIFLYBannerAd *)ad didFailWithError:(YSIFLYAdError *)error {
    NSLog(@"Banner failed: %d %@", error.errorCode, error.errorDescription);
}
```

`ysifly_showInView:` 需传入有效容器视图：容器宽度必须大于 0；高度为 0 时 SDK 会按主图宽高比自适应撑高。容器布局未就绪时内部会重试，超过 3 秒仍无有效宽高则回调布局超时错误。

---

## 插屏广告

典型流程：创建实例 → 设置 `delegate` → `ysifly_loadAdWithRequestConfig:` → 等待 `ysifly_interstitialAdDidReady:` → `ysifly_showAdFromRootViewController:config:`。

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
    if (![ad ysifly_isAdValid]) {
        return;
    }

    YSIFLYInterstitialAdConfig *config = [[YSIFLYInterstitialAdConfig alloc] init];
    config.presentationStyle = YSIFLYInterstitialPresentationStyleHalfScreen;
    config.muteOnStart = YES;

    [ad ysifly_showAdFromRootViewController:self config:config];
}

- (void)ysifly_interstitialAd:(YSIFLYInterstitialAd *)ad didFailWithError:(YSIFLYAdError *)error {
    NSLog(@"Interstitial failed: %d %@", error.errorCode, error.errorDescription);
}
```

`YSIFLYInterstitialPresentationStyleHalfScreen` 为半屏，`YSIFLYInterstitialPresentationStyleFullScreen` 为全屏。单个插屏实例为一次性使用，展示或关闭后请重新创建实例（再次 `ysifly_loadAd` 会以 `YSIFLYAdErrorCodeInterstitialAdAlreadyUsed` / `...Closed` 失败）。

---

## 自渲染信息流广告

信息流广告由媒体侧根据 `ad.adData` 自行渲染 UI，再通过 `YSIFLYNativeFeedAdViewBinder` 把容器、点击视图、关闭按钮、视频承载视图交给 SDK。SDK 负责曝光检测、点击/摇一摇响应、关闭与视频播放控制及监测上报，**不向媒体容器添加广告 UI 子视图**。

```objc
@interface NativeFeedViewController () <YSIFLYNativeFeedAdDelegate>
@property (nonatomic, strong) YSIFLYNativeFeedAd *nativeAd;
@property (nonatomic, strong) UIView *adContainer;
@property (nonatomic, strong) UIView *mediaContainer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *ctaButton;
@property (nonatomic, strong) UIButton *closeButton;
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
    YSIFLYNativeFeedAdData *data = ad.adData;
    self.titleLabel.text = data.title ?: @"广告标题";
    self.descLabel.text = data.desc ?: data.content;
    [self.ctaButton setTitle:data.actionText ?: @"查看详情" forState:UIControlStateNormal];

    // 图片素材请媒体侧自行下载并渲染到 imageView（URL 见 data.imageURLs）。
    // 视频素材请准备 videoView 容器，不要自行播放 videoURL。

    YSIFLYNativeFeedAdViewBinder *binder = [[YSIFLYNativeFeedAdViewBinder alloc] init];
    binder.containerView = self.adContainer;
    binder.renderViews = @[self.mediaContainer, self.titleLabel, self.descLabel, self.ctaButton];
    binder.clickViews = @[self.mediaContainer, self.ctaButton];
    binder.closeView = self.closeButton;
    binder.videoView = ad.hasVideoTemplate ? self.mediaContainer : nil;
    binder.titleView = self.titleLabel;
    binder.descView = self.descLabel;
    binder.imageView = self.imageView;
    binder.ctaView = self.ctaButton;

    YSIFLYAdError *error = nil;
    BOOL success = [ad ysifly_bindAdWithViewBinder:binder error:&error];
    if (!success) {
        NSLog(@"Native bind failed: %d %@", error.errorCode, error.errorDescription);
    }
}

- (void)ysifly_nativeFeedAdDidRender:(YSIFLYNativeFeedAd *)ad {
    if (ad.hasVideoTemplate) {
        [ad ysifly_startPlay];
    }
}
```

复用注意：

- `containerView` 必填。
- 视频素材必须传 `videoView`，由 SDK 创建播放器并完成播放监测（接入方不要自行播放 `videoURL`）。
- `UITableViewCell` / `UICollectionViewCell` 复用前调用 `ysifly_unbindAd` 或 `ysifly_destroy`。
- 绑定成功后该广告实例视为已消费；新的广告机会请创建新实例并重新 `ysifly_loadAd`。
- 素材类型见 `ad.materialType`（单图 / 三图 / 视频 / 未知）；视频播放控制：`ysifly_startPlay`、`ysifly_pausePlay`、`ysifly_resumePlay`、`ysifly_stopPlay`。

---

## S2S 服务端竞价

SDK 支持生成 S2S SDK token：

```objc
NSError *error = nil;
NSString *sdkToken = [YSIFLYAdSDK ysifly_getSdkTokenWithAdUnitId:@"YOUR_AD_UNIT_ID" error:&error];
if (!sdkToken) {
    NSLog(@"getSdkToken failed: %@", error);
}
```

媒体服务端完成竞价并返回 `rspToken` 后，客户端可使用：

```objc
[splashAd       ysifly_loadAdWithServerBiddingToken:rspToken];
[bannerAd       ysifly_loadAdWithServerBiddingToken:rspToken];
[interstitialAd ysifly_loadAdWithServerBiddingToken:rspToken];
[nativeAd       ysifly_loadAdWithServerBiddingToken:rspToken];
```

`rspToken` 为空会回调 `YSIFLYAdErrorCodeS2STokenEmpty`；无效、过期、重复使用或未竞胜会回调 `YSIFLYAdErrorCodeS2STokenInvalid`。S2S 加载成功后的 `ecpm` 固定返回 `0.0`。

---

## Header Bidding 结果通知

广告加载成功后，可通过 `bidInfo` 或 `ecpm` 获取竞价信息。媒体侧完成竞价决策后，可通过基类方法通知结果：

```objc
if (ad.bidInfo.winNoticeAvailable) {
    [ad ysifly_sendBidResultWithType:YSIFLYAdBidResultTypeWin reason:@"win"];
} else {
    [ad ysifly_sendBidResultWithType:YSIFLYAdBidResultTypeLoseBidLower reason:@"loss"];
}
```

结果类型见 `YSIFLYAdBidResultType`（`Win` / `LoseBidLower` / `LoseCreativePending` / `LoseCreativeRejected` / `LosePriorityLower` / `Error` / `Timeout`）。具体是否需要通知、通知时机和价格字段请以业务接入约定为准。

---

## 错误处理与常见问题

所有广告类型都会通过 `YSIFLYAdError` 返回失败信息：

```objc
- (void)ysifly_splashAd:(YSIFLYSplashAd *)ad didFailWithError:(YSIFLYAdError *)error {
    NSLog(@"errorCode=%d desc=%@", error.errorCode, error.errorDescription);
}
```

错误码（`YSIFLYAdErrorCode`）按范围划分：`70xxx` 为服务端错误（如 `70204` 无填充、`70400` 无效广告位），`71xxx` 为客户端错误（如 `71003` 网络错误、`71006` 超时），各广告形式另有 `713xx`（Banner）/ `714xx`（插屏）/ `715xx`（信息流）/ `716xx`（开屏）细分码。

常见问题：

| 现象 | 排查建议 |
| --- | --- |
| `pod install` 找不到 SDK | 确认 `Podfile` 用的是 `:podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.0.14/YSIFLYADLib.podspec'`（钉到 tag）。 |
| 广告图片缺失 | **6.0.12 及以上（静态交付）**：确认 `YSAdvSDK.bundle` 已进入 app（CocoaPods 自动；SPM / 手动集成须把 bundle 加入 Copy Bundle Resources，见接入方式）。**6.0.11 及以前（动态交付）**：请使用 1.0.2 及以上（动态 framework 才会投递内嵌 bundle）；早期 1.0.0「静态包 + 资源内嵌不投递」已下线，与 6.0.12 的「静态包 + 资源外置」不是一回事。 |
| 开屏「摇一摇或点击」图标显示为白色文件占位 | 1.0.2/1.0.3 的已知缺陷（改名误改资源名致内嵌图标失配），自 1.0.4 起已修复，**请升级到最新版 6.0.14**。 |
| 真机启动崩溃 | 1.0.1 有悬空依赖缺陷，已下线；请升级到 **1.0.2 及以上**。 |
| 模拟器无法运行 | 本定制版含模拟器切片，可直接在模拟器调试；若报架构缺失，确认拉取的是 1.0.2+ 的 zip。 |
| IDFA 为空 | 确认 `NSUserTrackingUsageDescription` 已配置、用户已允许 ATT、在授权完成后再读取 `ASIdentifierManager`、过滤全零 UUID。 |
| `ysifly_isAdValid` 为 NO | 确认已收到 `DidReady` 回调；广告未过期、未展示过、实例未销毁。 |
| 展示失败 | 确认 `rootViewController` 已在 window 上，当前没有正在 present 的控制器。 |
| Banner 不展示 | 确认容器宽度大于 0，布局完成后再调用 `ysifly_showInView:`。 |
| 信息流绑定失败 | 确认 `containerView` 非空；视频素材传入 `videoView`；绑定在主线程执行。 |
| 找不到 `YSIFLYRewardVideoAd` | **本定制版不含激励视频**（变体已关闭 Reward）；如需激励能力请联系商务。 |

---

## 公开 API 速览

| 类别 | 标识 |
| --- | --- |
| 入口类 | `YSIFLYSplashAd` / `YSIFLYBannerAd` / `YSIFLYInterstitialAd` / `YSIFLYNativeFeedAd`（**无 `YSIFLYRewardVideoAd`**） |
| 基类 | `YSIFLYAdBase`（请求配置、状态、竞价通知、DeepLink 开关） |
| 展示配置 | `YSIFLYSplashAdConfig` / `YSIFLYInterstitialAdConfig`（继承 `YSIFLYAdShowConfig`） |
| 请求配置 | `YSIFLYAdRequestConfig` |
| 数据模型 | `YSIFLYAdData` / `YSIFLYNativeFeedAdData` / `YSIFLYAdBidInfo` |
| 信息流绑定 | `YSIFLYNativeFeedAdViewBinder` |
| 全局配置 | `YSIFLYAdConfig`（`ysifly_setLogEnabled:` / `ysifly_setPersonalizedEnabled:`） |
| SDK 能力 | `YSIFLYAdSDK`（`ysifly_getSdkTokenWithAdUnitId:error:`）、`YSIFLYAdTool`（`ysifly_sdkVersion`） |
| 错误 | `YSIFLYAdError` / `YSIFLYAdErrorCode` |
| 加载/展示方法 | `ysifly_loadAd`、`ysifly_loadAdWithRequestConfig:`、`ysifly_loadAdWithServerBiddingToken:`、`ysifly_showInView:`、`ysifly_showAdFromRootViewController:config:`、`ysifly_bindAdWithViewBinder:error:`、`ysifly_unbindAd`、`ysifly_destroy`、`ysifly_isAdValid`、`ecpm` |
| 命名约定 | 入口类 `YS` 前缀；公开方法 / delegate 回调 `ysifly_` 前缀；初始化与属性保持系统风格（不加前缀） |

> 完整 API 以 framework 公开头 `<YSIFLYADLib/YSIFLYADLib.h>` 及其汇总的各头文件为准。

---

## 接入建议

- 广告对象请由页面或管理对象**强持有**，避免请求过程中提前释放。
- `delegate` 回调均按广告实例生命周期触发，页面销毁时建议置空 delegate 并调用 `ysifly_destroy`。
- 展示类广告通常在 `DidReady` 后再展示，不要在 `DidLoad` 里直接展示。
- 单个广告实例通常为一次性消费，展示 / 关闭 / 销毁后请重新创建实例。
- 正式上线前请替换为平台分配的真实广告位 ID，并关闭排查用日志（`[YSIFLYAdConfig ysifly_setLogEnabled:NO]`）。

---

## 问题反馈与支持

- 本仓库是 `YSIFLYADLib` 的**对外分发与接入文档仓**（不含 SDK 源码），不接受外部代码 PR。
- **使用问题 / Bug**：请在 [Issues](https://github.com/LJMcarryu/YSIFLYADLib_iOS/issues) 提交，并附 SDK 版本、iOS / Xcode 版本、接入方式（CocoaPods / SPM）、复现步骤与日志（前缀 `[YSAd]`）。
- **商务合作 / 广告位申请 / 激励能力开通**：请通过 YS 媒体对接渠道联系。
