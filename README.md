# YSIFLYADLib iOS SDK 接入说明

`YSIFLYADLib` 是面向 YS 媒体定制的 iOS 广告 SDK，提供**开屏、Banner、插屏、自渲染信息流**广告能力（**含视频素材**，**不含激励视频**）。

`6.2.3` 候选提交已冻结正式签名资产、checksum 和 A/B 元数据；公开可用性以同版本
GitHub Release 和发布后 CI 为准。最低支持 iOS 11.0。

<!-- 供发布 CI 机器校验的两提交 provenance；README、CHANGELOG、RELEASING 必须保持一致。 -->
- `releaseState`：`FORMAL`
- `binarySourceCommit`（SDK 二进制源码提交）：`da3cbcb39cc92045b099837fb233268c5c1595ec`
- `releaseMetadataCommit`（仅回填 checksum、扫描汇总和发布验收事实，不是 SDK 二进制源码提交）：`058deaba9ffad0aafe090808f9193a9d88fc0ddc`
- `releaseState=FORMAL` 表示正式签名资产、checksum 和 A/B 元数据已经冻结；公开可用性以同版本 GitHub Release 和发布后 CI 为准。
- 本候选未执行主动 Apple Review 扫描；扫描不属于发布门禁，`not-run` 不得表述为通过。
- 本提交是 `6.2.3` 的不可变发布目标。
- `CHANGELOG.md` 已固定到 `6.2.3` tag。

以下为 `6.2.2` 历史正式事实：

GitHub [Release 6.2.2](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.2.2)
已于 2026 年 8 月 10 日正式公开，annotated tag 解引用后的提交为
`b1bbaa5319335e027c560ab357c86cc6a732003e`，资产库存严格为 3 项。
[published CI](https://github.com/LJMcarryu/YSIFLYADLib_iOS/actions/runs/31347052226) 已成功完成
三资产匿名下载、SHA-256 与双包同源校验，并实际构建 SwiftPM 产品、最小消费端和 CocoaPods Demo，
同时通过完整 `pod spec lint`。该分发验收不代表最终宿主合规、`Validate App` 或 Apple 审核通过。
`6.2.2` 按当版已确认范围原样归档 `SRC-004`、`SRC-008`、`SRC-009`、`SRC-011`、`NET-001`、
`RRA-003`、`TRACK-001`、`TRACK-002`、`ADS-011`、`EXPORT-001` 启发式残余风险，并以
`failOn=high`、`failOnWarning=false`、`strict=false`、`requireManual=false` 发布；该确认不适用于
`6.2.3` 或最终宿主。`6.2.3` 不沿用历史风险授权；主动扫描策略固定为
`failOn=high`、`failOnWarning=true`、`strict=true`、`requireManual=true` 且接受名单为空。
其二进制源码提交为 `a8ec925d3731d7d11734647aa02ca7d91d674965`，发布元数据提交为
`eff78263c2d3f65b029f4114de1a9ed00f3827f3`。

仓库地址：[https://github.com/LJMcarryu/YSIFLYADLib_iOS](https://github.com/LJMcarryu/YSIFLYADLib_iOS)

> **本 SDK 为 YS 媒体定制白标构建**，与标准版命名不同，接入时请严格按本文档：
> - 入口类统一前缀 `YS`，如 `YSIFLYSplashAd`、`YSIFLYBannerAd`。
> - 公开方法统一前缀 `ysifly_`，如 `ysifly_loadAd`、`ysifly_showInView:`、`ysifly_destroy`。
> - delegate 回调统一前缀 `ysifly_`，如 `ysifly_splashAdDidReady:`。
> - 初始化方法、属性保持系统风格（**不**加前缀）：`initWithAdUnitId:`、`ad.delegate`、`ad.bidInfo.price`。
> - 伞头入口：`#import <YSIFLYADLib/YSIFLYADLib.h>`；资源包 `YSAdvSDK.bundle`（**外置随包分发**，CocoaPods / SPM 自动投递，手动集成时需加入 app target，见接入方式）；运行期日志前缀 `[YSAd]`。

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

当前候选版本为 **6.2.3**，其正式冻结状态由 `releaseState=FORMAL` 和发布清单记录；`6.2.2` 将 NativeFeed 列表生命周期改为 SDK 托管：数据层只持有
`YSIFLYNativeFeedAd`，Cell 不持有 Session、Binding 或首次/复用状态；媒体只需在展示时
attach、离屏或复用时按容器 detach。同一逻辑广告条目滚出再回来时，无论曝光前后都能
恢复原广告。详细变更与历史版本记录见 [CHANGELOG.md](./CHANGELOG.md)。

从 `6.2.1` 升级到 `6.2.2` 时须删除 `YSIFLYNativeFeedDisplaySession`、
`YSIFLYNativeFeedAdBinding` 以及旧 bind/unbind/end 调用，改用
`ysifly_attachWithViewBinder:error:` 与 `ysifly_detachAdFromContainerView:`。从 `6.1.0`
或更早版本升级时，还请重点确认：`jumpDirectly` 已成为兼容 no-op；SDK 不再调用
`canOpenURL:` 预检；ATT 未授权时预先设置的显式 IDFA 会被丢弃，授权后须重新设置；
YS 白标方法 `ysifly_reportMediaShakeTriggeredWithError:` 虽然进入公开头，但 YS 变体
未启用优酷媒体摇一摇能力，调用固定返回 `71512`。从 `6.0.14` 或更早版本升级时，
还须处理 `6.1.0` 引入的响应数据白名单变更。`6.2.3` 在该主路径上新增受限外部 CTA
和固定单容器便利解绑。

---

## 环境要求

- **iOS 11.0** 及以上（从 `6.0.14` 起；历史 `6.0.13` 及更早二进制不追溯扩大支持范围）。
- **Xcode 15.0** 及以上（`Package.swift` 使用 Swift tools 5.9）；`6.2.2` 正式二进制由唯一冻结源码提交使用 Xcode 26.2 构建。
- **交付形态**（6.0.12 起）：单一 `YSIFLYADLib.xcframework`（**静态 framework**），含 **真机 `arm64` + 模拟器 `arm64`/`x86_64`** 切片，**可直接在模拟器调试**；代码随 app 静态链接，**无需 Embed & Sign**。
- 资源包 `YSAdvSDK.bundle`（内含隐私清单 `PrivacyInfo.xcprivacy`）**外置随包分发**：CocoaPods 与 SwiftPM 接入自动投递；手动集成需把 bundle 加入 app target 的 Copy Bundle Resources。
- **最终 App 链接需 `-ObjC`**：CocoaPods podspec 同时向 pod target 与 aggregate/user target 注入，确保参数传播到最终 App；SwiftPM 与手动接入需在 App target 的 `OTHER_LDFLAGS` 添加。
- 系统依赖中，CocoaPods podspec 显式链接 `AdSupport`、弱链接 `AppTrackingTransparency`；SwiftPM 与手动接入依靠 XCFramework 目标文件携带的 linker options。`6.2.2` 正式冻结产物已复核 ATT 仍为弱链接，保证 iOS 11～13 启动时不要求该框架存在。
- 统一入口头：`#import <YSIFLYADLib/YSIFLYADLib.h>`。

---

## 接入方式

二进制通过本仓 **GitHub Releases** 分发；`6.2.2` Release 资产已对外可见并通过公开匿名下载验证，
每个版本固定发布三个文件：

| 资产 | 内容 | 适用 |
| --- | --- | --- |
| `YSIFLYADLib-<版本>.zip`（合并 zip） | `YSIFLYADLib.xcframework` + `YSAdvSDK.bundle` + `LICENSE` | CocoaPods（podspec 指向它）、手动集成 |
| `YSIFLYADLib.xcframework.zip` | 仅 `YSIFLYADLib.xcframework`；资源由仓库 tag 中的 SwiftPM 包装 target 提供 | Swift Package Manager |
| `checksums.txt` | 两个 zip 的 SHA-256 与 SwiftPM checksum | 完整性校验 |

推荐 **CocoaPods** 接入：资源包投递全自动，升级只改一处 tag。

### CocoaPods

候选验证与后续生产接入固定使用 `6.2.3` tag：

```ruby
source 'https://cdn.cocoapods.org/'
platform :ios, '11.0'

target 'YourApp' do
  use_frameworks!

  pod 'YSIFLYADLib', :podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.2.3/YSIFLYADLib.podspec'
end
```

安装：

```bash
pod install
open YourApp.xcworkspace
```

> 说明：
> - `:podspec` 的二进制源固定指向同版本 Release 合并 zip；CocoaPods 解包并链接其中的静态 `YSIFLYADLib.xcframework`，同时把 `YSAdvSDK.bundle`（含隐私清单）**自动拷入 app 主包**（podspec 已声明 `s.resources`）。
> - **请把 URL 钉死到具体版本 tag，不要指向分支**；公开可用性以同版本 GitHub Release 和发布后 CI 为准。
> - 静态 framework 随 app 链接，pod 不会（也不需要）Embed；podspec 会同时向 pod target 与 aggregate/user target 注入 `-ObjC`，并复制 `.bundle`，CocoaPods 接入无需手工处理这两项。

### Swift Package Manager

当前可在 Xcode「**File → Add Packages…**」填入仓库地址并选择正式版本 `6.2.2`：

```
https://github.com/LJMcarryu/YSIFLYADLib_iOS.git
```

或在 `Package.swift` 中声明：

```swift
dependencies: [
    .package(url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS.git", from: "6.2.2"),
],
targets: [
    .target(name: "YourApp", dependencies: ["YSIFLYADLib"]),
]
```

`6.1.0` 起，SwiftPM product 同时包含二进制 target 与
`YSIFLYADLibResources` 包装 target，后者会自动把 `YSAdvSDK.bundle`
（含 `PrivacyInfo.xcprivacy`）复制到 App。接入方不再需要从合并 zip
手工复制资源；接入方仍须在 App target 的 `OTHER_LDFLAGS` 添加 `-ObjC`。

> 当前仓库根 `Package.swift` 已写入本候选正式签名 zip 的真实 checksum；远程消费以同版本
> GitHub Release 和发布后 CI 的结果为准，不得复用其他版本 checksum。

### 手动集成

不便使用包管理器时，可下载已发布的正式合并 zip
（`YSIFLYADLib-6.2.2.zip`）并集成其中内容：

1. 解压得到 `YSIFLYADLib.xcframework` 与 `YSAdvSDK.bundle`；
2. 把 `YSIFLYADLib.xcframework` 拖入工程，General → Frameworks, Libraries, and Embedded Content 中 Embed 选 **Do Not Embed**（静态库随 app 链接，无需嵌入）；
3. 把 `YSAdvSDK.bundle` 拖入工程并加入 app target（Build Phases → Copy Bundle Resources）；
4. 在 App target 的 Other Linker Flags（`OTHER_LDFLAGS`）添加 `-ObjC`。

---

## 权限与隐私配置

### 隐私清单（PrivacyInfo.xcprivacy）

SDK 的 Apple 隐私清单 `PrivacyInfo.xcprivacy` 随 `YSAdvSDK.bundle` 交付（CocoaPods / SwiftPM 自动带入；手动集成在把 bundle 加入 app target 后带入，Apple 会扫描 app 内 bundle 中的隐私清单）。**接入方仍须在 App Store Connect 的隐私「营养标签」中如实合并声明以下数据收集，并据 `NSPrivacyTracking = YES` 提供 ATT 授权（见下）。**

- **追踪**：`NSPrivacyTracking = YES`；追踪域名：`voiceads.cn`、`bjimp.voiceads.cn`、`ai.voiceads.cn`、`msdk.voiceads.cn`、`sdk-adx.voiceads.cn`、`caid-api.adn-plus.com.cn`。
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
- `6.2.0` 起系统 IDFA、`YSIFLYAdRequestConfig.idfa` 和底层参数入口使用同一授权门控；iOS 14 及以上只有 ATT 为 `Authorized` 才会进入普通请求或 S2S 请求。
- 在 ATT 为 `NotDetermined`、`Restricted`、`Denied` 时预先设置的显式 IDFA 会被立即丢弃且不会缓存；用户授权后必须重新读取并设置。授权撤销或 App 回到前台发现未授权时，SDK 会清除已有 IDFA 缓存。
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
| `idfa` | 媒体侧显式传入的 IDFA；iOS 14 及以上仅 ATT 已授权时接受，未授权时丢弃且授权后须重新设置。 |
| `caidList` | 媒体侧显式传入的 CAID 列表（每项含 `ver`、`caid`）。 |
| `landingPageTransitionType` | 落地页跳转动画：`0` 右滑入，`1` 底部滑入。 |
| `landingPageAutorotateType` | 落地页旋转方式：`0` 仅竖屏…`3` 全方向。 |
| `jumpDirectly` | 兼容保留字段；`6.2.0` 起为 no-op，不再改变跳转行为。 |
| `deepLinkDisabled` | 是否禁用 DeepLink。 |

`6.2.0` 起 SDK 不再使用 `canOpenURL:` 预检外部 URL，而是直接调用
`openURL:options:completionHandler:` 并以系统完成回调判定结果。DeepLink 打开失败时仍按
原有规则回退到 landing page；非法 HTTP URL、携带凭据的 URL 和危险 scheme 会在打开前拒绝。

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

信息流广告由媒体侧根据 `ad.adData` 自行渲染 UI，再通过
`YSIFLYNativeFeedAdViewBinder` 把容器、点击视图、关闭按钮和视频承载视图交给
SDK。SDK 负责曝光检测、点击/摇一摇响应、关闭、播放器与监测上报；不会清空媒体
已有的 layer 或子视图，也不会自动添加摇一摇提示控件。

`6.2.2` 统一为 SDK 托管生命周期。普通页面和 `UITableView` / `UICollectionView`
复用列表都使用同一组 Ad attach 与容器 detach API；媒体不创建或维护 SDK 生命周期对象。

`6.2.3` 新增两个可选入口：

- 固定、非复用且不会迁移的单活动容器，可调用 `ysifly_detachFromCurrentContainer`；常规 Cell 生命周期仍应立即调用 `ysifly_detachAdFromContainerView:`，避免旧回调误解绑新容器。
- `clickViews` 默认仍须位于 `containerView` 内。只有外部 CTA 与广告同生共灭且媒体无法调整层级时，才显式设置 `binder.allowsExternalClickViews = YES`。SDK 仅接受同 window/scene 且归属可判定的同 Cell 或窄范围兄弟视图；共享、固定悬浮、广告离屏后仍可点击或归属不明时失败关闭。运行中拒绝通过 delegate `ysifly_nativeFeedAd:didRejectClickWithError:` 通知，错误为 `YSIFLYAdErrorCodeNativeFeedClickViewsInvalid`（71503）。

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
    if (![data ysifly_isMaterialComplete] ||
        data.materialType == YSIFLYNativeFeedAdMaterialTypeUnknown) {
        return; // Unknown 不渲染、不绑定
    }

    self.titleLabel.text = data.title ?: data.appName ?: data.brand ?: @"";
    self.descLabel.text = data.desc ?: data.content;
    BOOL clickable =
        data.interactionType == YSIFLYNativeFeedAdInteractionTypeRedirect ||
        data.interactionType == YSIFLYNativeFeedAdInteractionTypeDownload;
    self.ctaButton.hidden = !clickable;
    [self.ctaButton setTitle:(clickable ? (data.ctaText ?: @"查看详情") : nil)
                    forState:UIControlStateNormal];

    // 按 data.materialType / data.templateId 选择单图、多图或视频布局。
    // 多图遍历 data.imageList（2～3 张），不要写死 3 张。
    // 图片素材请媒体侧自行下载并渲染（URL 见 data.imageURLs）。
    // 视频素材请准备 videoView 容器，不要自行播放 videoURL。

    YSIFLYNativeFeedAdViewBinder *binder = [[YSIFLYNativeFeedAdViewBinder alloc] init];
    binder.containerView = self.adContainer;
    binder.renderViews = @[self.mediaContainer, self.titleLabel, self.descLabel, self.ctaButton];
    // nil 会退化为整容器可点击。Exposure / Unknown 必须显式传空数组。
    binder.clickViews = clickable ? @[self.mediaContainer, self.ctaButton] : @[];
    binder.closeView = self.closeButton;
    binder.videoView = ad.hasVideoTemplate ? self.mediaContainer : nil;
    binder.titleView = self.titleLabel;
    binder.descView = self.descLabel;
    binder.imageView = self.imageView;
    binder.ctaView = self.ctaButton;

    YSIFLYAdError *error = nil;
    BOOL success = [ad ysifly_attachWithViewBinder:binder error:&error];
    if (!success) {
        NSLog(@"Native attach failed: %d %@", error.errorCode, error.errorDescription);
    }
}

- (void)adContainerDidLeaveScreenOrPrepareForReuse {
    [YSIFLYNativeFeedAd ysifly_detachAdFromContainerView:self.adContainer];
}
```

`templateId` 与 `materialType` 类型、数值一致，均为 SDK 按实际素材归一出的
`YSIFLYNativeFeedAdMaterialType`，不是服务端原始模板号：

| 枚举 | 值 | 归一规则 |
| --- | ---: | --- |
| `YSIFLYNativeFeedAdMaterialTypeUnknown` | 0 | 无可用视频、多图、主图或 icon。 |
| `YSIFLYNativeFeedAdMaterialTypeSingleImage` | 1 | 有 `img`，或在 `img` 缺失时有 `icon`。 |
| `YSIFLYNativeFeedAdMaterialTypeVideo` | 2 | 有有效 `video` URL，优先级最高。 |
| `YSIFLYNativeFeedAdMaterialTypeMultipleImages` | 3 | 无视频，且 `img1`、`img2` 有效；`img3` 可选。 |

归一优先级固定为 `video → img1 + img2 → img 或 icon → Unknown`。行为类型为
`Exposure(1)`、`Redirect(2)`、`Download(3)` 或 `Unknown(0)`；服务端
`action_type=3/4` 均归一为 `Download`，`9` 及未知值归一为 `Unknown`。
`interactType` 对应 `Click(1)`、`ClickAndShake(2)`、`ClickAndSlide(3)`、
`ClickShakeAndSlide(4)`；当前 NativeFeed 只消费点击及其中的摇一摇分量，不自动实现
上滑手势，`5/6/7` 及未知值归一为 `Unknown`。

`6.1.0` 起响应数据对外采用严格白名单。四种广告通用对象只暴露
`bidInfo.price` 和 `bidInfo.dealId`；只有 NativeFeed 额外提供只读 `adData`：

- 标识与枚举：`creativeId`、`templateId`、`materialType`、`interactionType`、
  `interactType`、`hasShakeInteraction`。
- 文案与品牌：`title`、`desc`、`content`、`ctaText`、`brand`、`appName`、
  `adSourceMark`、`adSourceIconURL`。
- 图片：`mainImage`、`image1`、`image2`、`image3`、`imageList`、
  `imageURLs`、`imageSize`、`icon`、`iconURL`、`closeIconURL`。
- 视频：`videoURL`、`videoCoverURL`、`videoDuration`、`videoSize`。
- 跳转与下载：`targetURL`、`deeplinkURL`、`marketURL`、`downloadURL`、
  `packageName`。

不再提供 `rawAdData`、`sponsored`、`actionText`、`ecpm` 或服务端原始
`template_id`；请勿通过 KVC、反射或写死旧枚举数值继续读取。

### 列表复用：数据项只持 Ad，Cell 只注册和反注册容器

列表数据源用稳定 ID 表示逻辑广告条目，并长期持有同一个 `YSIFLYNativeFeedAd`。
Cell 是临时视图，只负责媒体 UI 和 Binder，不保存 Session、Binding、广告集合或
“第一次展示/复用展示”状态：

```objc
@interface FeedAdItem : NSObject
@property (nonatomic, copy) NSString *stableIdentifier;
@property (nonatomic, strong) YSIFLYNativeFeedAd *ad;
@end

- (void)attachItem:(FeedAdItem *)item toCell:(FeedAdCell *)cell {
    [cell renderAdData:item.ad.adData];

    YSIFLYAdError *error = nil;
    BOOL attached = [item.ad ysifly_attachWithViewBinder:[cell currentViewBinder]
                                                   error:&error];
    if (!attached && error.errorCode == YSIFLYAdErrorCodeNativeFeedAdExpired) {
        item.ad.delegate = nil;
        item.ad = nil;
        [self loadReplacementForStableIdentifier:item.stableIdentifier];
    }
}

- (void)collectionView:(UICollectionView *)collectionView
didEndDisplayingCell:(UICollectionViewCell *)rawCell
     forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (![rawCell isKindOfClass:FeedAdCell.class]) {
        return;
    }
    FeedAdCell *cell = (FeedAdCell *)rawCell;
    [YSIFLYNativeFeedAd ysifly_detachAdFromContainerView:cell.adContainer];
    [cell resetMediaViews];
}

@implementation FeedAdCell
- (void)prepareForReuse {
    [super prepareForReuse];
    [YSIFLYNativeFeedAd ysifly_detachAdFromContainerView:self.adContainer];
    [self resetMediaViews];
}
@end
```

完整时序与边界：

- `ysifly_attachWithViewBinder:error:` 必须在主线程调用。SDK 内部处理同 Ad 向新容器串行迁移、
  同 Ad/同容器幂等，以及目标容器由新 Ad 原子接管；媒体不需要先查询或保存绑定状态。
- `ysifly_detachAdFromContainerView:` 可在 `didEndDisplaying`、`prepareForReuse` 或切换为普通内容
  时重复调用。它只反注册当前视图，不结束逻辑广告；数据项继续持有同一 Ad 时，回屏可再次 attach。
- 异步图片回调仍须校验稳定 ID、数据 generation 和当前 Cell，避免旧素材写进已复用 Cell；
  这属于媒体渲染状态，不是 SDK 生命周期状态。
- 曝光前 detach 后重新 attach 会重新累计连续可见 500ms；已曝光后恢复不会重复曝光、
  曝光回调或曝光监测。点击监测和视频节点监测也按同一逻辑广告去重。
- TTL 或视频 `end_time` 在活动挂载期间到期不会中途强拆当前 Cell；detach 后再次 attach
  返回 `71506`，此时释放旧 Ad，并为同一稳定 ID 请求新广告。
- 条目永久删除、缓存淘汰或页面退出时，先反注册容器、置空 delegate，再释放最后一个 Ad
  强引用即可。`ysifly_destroy` 不是必调项；只有仍需持有 Ad、但希望提前取消请求或立即终止
  恢复能力时才调用。
- `containerView` 必填；视频素材必须传 `videoView`。播放器由 SDK 管理，接入方不要创建
  `AVPlayer` 或自行播放 `videoURL`。
- 视频在 detach/attach 之间保留内容进度与既有播放意图；显式调用 `ysifly_pausePlay` 或
  `ysifly_stopPlay` 后，回屏不会擅自重新起播，只有媒体调用 `ysifly_resumePlay` 或
  `ysifly_startPlay` 才会重新申请播放。

可运行的 `UITableView` 版本见
[`YSIFLYNativeViewController.m`](./YSIFLYADLibSimple/YSIFLYADLibSimple/biz/native/YSIFLYNativeViewController.m)。

`6.2.0` 的 NativeFeed 公开头新增白标方法：

```objc
YSIFLYAdError *error = nil;
BOOL accepted = [ad ysifly_reportMediaShakeTriggeredWithError:&error];
```

该方法用于保持各分发变体公开契约一致。YS `YSNoReward` 变体没有启用优酷媒体摇一摇
采样能力，因此调用会返回 `NO`，并给出
`YSIFLYAdErrorCodeNativeFeedMediaShakeUnavailable`（`71512`）；YS 接入方不应把它作为
摇一摇点击入口。`71513`～`71515` 为启用该能力的其他变体保留，不表示 YS 已开放此能力。

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

`rspToken` 为空会回调 `YSIFLYAdErrorCodeS2STokenEmpty`；无效、过期、重复使用或未竞胜会回调 `YSIFLYAdErrorCodeS2STokenInvalid`。S2S 加载成功后的 `bidInfo.price` 固定返回 `0`。

---

## Header Bidding 结果通知

广告加载成功后，通过 `bidInfo` 获取严格白名单竞价信息：

```objc
NSNumber *price = ad.bidInfo.price;
NSString *dealId = ad.bidInfo.dealId;
```

`price` 或 `dealId` 未下发时可能为 `nil`。媒体侧完成竞价决策后，按实际竞价结果
调用基类通知方法：

```objc
[ad ysifly_sendBidResultWithType:YSIFLYAdBidResultTypeWin reason:@"win"];
// 或失败场景：
[ad ysifly_sendBidResultWithType:YSIFLYAdBidResultTypeLoseBidLower reason:@"loss"];
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
| `pod install` 找不到 SDK | 请确认 `Podfile` 使用 `:podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.2.3/YSIFLYADLib.podspec'`（钉到具体 tag），并检查同版本 GitHub Release 与发布后 CI 状态。 |
| 广告图片缺失 | **6.1.0 及以上**：CocoaPods / SwiftPM 都会自动投递 `YSAdvSDK.bundle`，请确认最终 App 中存在该 bundle 及 `PrivacyInfo.xcprivacy`；手动接入须加入 Copy Bundle Resources。**6.0.12～6.0.14**：CocoaPods 自动，SPM / 手动接入须手工复制。**6.0.11 及以前**为历史动态交付。 |
| 开屏「摇一摇或点击」图标显示为白色文件占位 | 1.0.2/1.0.3 的已知缺陷（改名误改资源名致内嵌图标失配），自 1.0.4 起已修复；请使用已验证的 `6.2.2` 或更高版本。 |
| 真机启动崩溃 | 1.0.1 有悬空依赖缺陷，已下线；请升级到 **1.0.2 及以上**。 |
| 模拟器无法运行 | 本定制版含模拟器切片，可直接在模拟器调试；若报架构缺失，确认拉取的是 1.0.2+ 的 zip。 |
| IDFA 为空 | 确认 `NSUserTrackingUsageDescription` 已配置、用户已允许 ATT、在授权完成后再读取 `ASIdentifierManager`、过滤全零 UUID；授权前设置的显式值已被丢弃，须在授权后重新设置。 |
| `ysifly_isAdValid` 为 NO | 确认已收到 `DidReady` 回调；广告未过期、未展示过、实例未销毁。 |
| 展示失败 | 确认 `rootViewController` 已在 window 上，当前没有正在 present 的控制器。 |
| Banner 不展示 | 确认容器宽度大于 0，布局完成后再调用 `ysifly_showInView:`。 |
| 信息流绑定失败 | 确认 `containerView` 非空；视频素材传入 `videoView`；绑定在主线程执行。 |
| 信息流条目滚回后为空或变成另一条广告 | `6.2.2` 起让稳定 ID 的数据模型只持原 Ad；Cell 展示时调用 `ysifly_attachWithViewBinder:error:`，离屏/复用时按容器调用 `ysifly_detachAdFromContainerView:`，不要因回屏重新请求广告。 |
| 信息流重新挂载返回 `71506` | Ad 已超过 TTL 或视频 `end_time`；释放旧 Ad，为相同稳定 ID 请求新广告。活动挂载到期时不会被中途拆除。 |
| 找不到 `YSIFLYRewardVideoAd` | **本定制版不含激励视频**（变体已关闭 Reward）；如需激励能力请联系商务。 |

---

## 公开 API 速览

| 类别 | 标识 |
| --- | --- |
| 入口类 | `YSIFLYSplashAd` / `YSIFLYBannerAd` / `YSIFLYInterstitialAd` / `YSIFLYNativeFeedAd`（**无 `YSIFLYRewardVideoAd`**） |
| 基类 | `YSIFLYAdBase`（请求配置、状态、竞价通知、DeepLink 开关） |
| 展示配置 | `YSIFLYSplashAdConfig` / `YSIFLYInterstitialAdConfig`（继承 `YSIFLYAdShowConfig`） |
| 请求配置 | `YSIFLYAdRequestConfig` |
| 数据模型 | `YSIFLYNativeFeedAdData`（仅自渲染白名单素材）/ `YSIFLYAdBidInfo`（四种广告通用 `price/dealId`） |
| 信息流挂载 | `YSIFLYNativeFeedAdViewBinder`；Ad `ysifly_attachWithViewBinder:error:`；容器 `ysifly_detachAdFromContainerView:` |
| 全局配置 | `YSIFLYAdConfig`（`ysifly_setLogEnabled:` / `ysifly_setPersonalizedEnabled:`） |
| SDK 能力 | `YSIFLYAdSDK`（`ysifly_getSdkTokenWithAdUnitId:error:`）、`YSIFLYAdTool`（`ysifly_sdkVersion`） |
| 错误 | `YSIFLYAdError` / `YSIFLYAdErrorCode` |
| 加载/展示方法 | `ysifly_loadAd`、`ysifly_loadAdWithRequestConfig:`、`ysifly_loadAdWithServerBiddingToken:`、`ysifly_showInView:`、`ysifly_showAdFromRootViewController:config:`、`ysifly_attachWithViewBinder:error:`、`ysifly_detachAdFromContainerView:`、`ysifly_reportMediaShakeTriggeredWithError:`（YS 返回 `71512`）、`ysifly_destroy`、`ysifly_isAdValid` |
| 命名约定 | 入口类 `YS` 前缀；公开方法 / delegate 回调 `ysifly_` 前缀；初始化与属性保持系统风格（不加前缀） |

> 完整 API 以 framework 公开头 `<YSIFLYADLib/YSIFLYADLib.h>` 及其汇总的各头文件为准。

---

## 接入建议

- 广告对象请由页面或管理对象**强持有**，避免请求过程中提前释放。
- `delegate` 回调均按广告实例生命周期触发；页面结束时置空 delegate、反注册活动容器并释放广告强引用。`ysifly_destroy` 仅用于主动提前终止。
- 展示类广告通常在 `DidReady` 后再展示，不要在 `DidLoad` 里直接展示。
- 一次性页面中的单个广告实例仍为一次性消费；列表中的逻辑广告条目由数据层持有同一 Ad，
  Cell 复用只做容器 detach，不销毁或重新请求；条目永久删除、Ad 失效或页面退出时释放强引用。
- 正式上线前请替换为平台分配的真实广告位 ID，并关闭排查用日志（`[YSIFLYAdConfig ysifly_setLogEnabled:NO]`）。

---

## 问题反馈与支持

- 本仓库是 `YSIFLYADLib` 的**对外分发与接入文档仓**（不含 SDK 源码），不接受外部代码 PR。
- **使用问题 / Bug**：请在 [Issues](https://github.com/LJMcarryu/YSIFLYADLib_iOS/issues) 提交，并附 SDK 版本、iOS / Xcode 版本、接入方式（CocoaPods / SPM）、复现步骤与日志（前缀 `[YSAd]`）。
- **商务合作 / 广告位申请 / 激励能力开通**：请通过 YS 媒体对接渠道联系。
