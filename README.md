# YS 广告 iOS SDK


`YSIFLYADLib` 为 YS 媒体提供 iOS 开屏、Banner、插屏和自渲染信息流广告；本仓库包含分发清单、接入指南与示例。

当前正式版本：[`6.4.4`](https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.4.4)。

<!-- ifly-release-status: {"schemaVersion":1,"version":"6.4.4","releaseState":"FORMAL","distribution":"github-release","releaseUrl":"https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/tag/6.4.4"} -->

[运行示例](YSIFLYADLibSimple/README.md) · [安装指南](docs/接入指南/安装与资源配置.md) · [广告接入](docs/接入指南/广告加载与展示.md) · [更新记录](CHANGELOG.md) · [隐私与网络](docs/接入指南/隐私与网络.md) · [支持](https://github.com/LJMcarryu/YSIFLYADLib_iOS/issues) · [许可](LICENSE)

## 能力与接入身份

| 项目 | 说明 |
| --- | --- |
| 广告能力 | 开屏、Banner、插屏、自渲染信息流（单图、多图、视频）；不包含激励广告 |
| CocoaPods / SwiftPM product | `YSIFLYADLib` |
| 代码模块 / 导入 | `YSIFLYADLib` / `#import <YSIFLYADLib/YSIFLYADLib.h>` |
| 资源包 | `YSAdvSDK.bundle`，含 `PrivacyInfo.xcprivacy` |
| API 命名 | 类型使用 `YSIFLY` 前缀；公开方法和 delegate 回调使用 `ysifly_` 前缀，初始化方法和属性不加此前缀 |
| 共存限制 | 与仅开屏 `YSIFLYADLibSplash` 使用相同模块、类型与资源，同一 App 只能选择一个 YS 包 |

迁移 YS 包时先移除旧依赖、手工 framework 和重复资源。接口以所安装版本的 framework 公开头为准。

## 环境要求

- iOS 11.0+；SwiftPM 清单要求 Swift tools 5.9。
- 静态 XCFramework，包含设备与模拟器切片；App 最终链接需要 `-ObjC`，无需 **Embed & Sign**。
- [环境与安装说明](docs/接入指南/安装与资源配置.md#环境要求)区分部署目标、清单要求与工具兼容范围。

## 安装

推荐 CocoaPods，使用精确版本的 Podspec URL：

```ruby
source 'https://cdn.cocoapods.org/'
platform :ios, '11.0'

target 'YourApp' do
  use_frameworks!
  pod 'YSIFLYADLib',
      :podspec => 'https://raw.githubusercontent.com/LJMcarryu/YSIFLYADLib_iOS/6.4.4/YSIFLYADLib.podspec'
end
```

```bash
pod install
open YourApp.xcworkspace
```

此版本使用上述 Podspec URL 安装，无需依赖 CocoaPods trunk 收录。CocoaPods 自动加入资源、`-ObjC` 和所需系统库；安装后始终打开 `.xcworkspace`。

SwiftPM 或手动集成见[安装与资源配置](docs/接入指南/安装与资源配置.md)。三种方式选择一种；代码导入 `#import <YSIFLYADLib/YSIFLYADLib.h>`。

## 最小使用流程

SDK 无需额外 App ID 初始化。完成宿主隐私流程，使用平台分配给当前 App 和广告形式的广告位，创建并强持有广告对象、设置 delegate，然后调用 `ysifly_loadAd`。开屏、Banner、插屏收到 Ready 后检查有效性、来源窗口与宿主展示时机，再调用展示方法；失败、结束或宿主放弃等待时继续业务并清理对象。成功展示后的下一次机会需新建对象。

完整普通请求示例、稍后展示与失败出口见[广告加载与展示](docs/接入指南/广告加载与展示.md)。NativeFeed 使用 DidLoad → 媒体渲染 → attach 流程，没有 Ready 回调；临时离屏按具体容器 detach，数据项继续持有同一广告。

## 按广告形式接入

| 广告形式 | 接入指南 | 示例源码 |
| --- | --- | --- |
| 图片 / 视频开屏 | [开屏广告](docs/接入指南/广告加载与展示.md#开屏广告) | [开屏页面](YSIFLYADLibSimple/YSIFLYADLibSimple/biz/splash/YSIFLYSplashViewController.m) |
| Banner | [Banner 广告](docs/接入指南/广告加载与展示.md#banner-广告) | [Banner 页面](YSIFLYADLibSimple/YSIFLYADLibSimple/biz/banner/YSIFLYBannerViewController.m) |
| 插屏 | [插屏广告](docs/接入指南/广告加载与展示.md#插屏广告) | [插屏页面](YSIFLYADLibSimple/YSIFLYADLibSimple/biz/interstitial/YSIFLYInterstitialViewController.m) |
| 自渲染信息流 | [素材、列表复用与外部 CTA](docs/接入指南/广告加载与展示.md#自渲染信息流) | [信息流页面](YSIFLYADLibSimple/YSIFLYADLibSimple/biz/native/YSIFLYNativeViewController.m) |

普通广告无需服务端竞价；已开通媒体可查阅 [S2S 与 Header Bidding](docs/接入指南/竞价接入.md)。

## 隐私、支持与许可

`ysifly_setPersonalizedEnabled:` 仅记录状态，不改变数据处理、请求、填充、展示或点击行为，也不替代宿主同意流程与 ATT 授权。IDFA 只在授权后读取或传入；资源清单、ATS 与日志说明见[隐私与网络](docs/接入指南/隐私与网络.md)。

接入失败先查[错误处理与反馈](docs/接入指南/错误处理与反馈.md)；仍需帮助时通过 [Issues](https://github.com/LJMcarryu/YSIFLYADLib_iOS/issues) 提供版本、操作步骤、错误码和脱敏日志。使用许可见 [LICENSE](LICENSE)。

<details>
<summary>原章节入口</summary>

<a id="能力与环境"></a>

原“能力与环境”内容见[能力与接入身份](#能力与接入身份)和[环境要求](#环境要求)。

<a id="cocoapods"></a>

原“CocoaPods”内容见[对应指南](docs/接入指南/安装与资源配置.md#cocoapods)。

<a id="swift-package-manager"></a>

原“Swift Package Manager”内容见[对应指南](docs/接入指南/安装与资源配置.md#swift-package-manager)。

<a id="手动集成"></a>

原“手动集成”内容见[对应指南](docs/接入指南/安装与资源配置.md#手动集成)。

<a id="请求与通用生命周期"></a>

原“请求与通用生命周期”内容见[对应指南](docs/接入指南/广告加载与展示.md#请求与通用生命周期)。

<a id="开屏广告"></a>

原“开屏广告”内容见[对应指南](docs/接入指南/广告加载与展示.md#开屏广告)。

<a id="展示配置与回调"></a>

原“展示配置与回调”内容见[对应指南](docs/接入指南/广告加载与展示.md#展示配置与回调)。

<a id="banner-广告"></a>

原“Banner 广告”内容见[对应指南](docs/接入指南/广告加载与展示.md#banner-广告)。

<a id="插屏广告"></a>

原“插屏广告”内容见[对应指南](docs/接入指南/广告加载与展示.md#插屏广告)。

<a id="自渲染信息流"></a>

原“自渲染信息流”内容见[对应指南](docs/接入指南/广告加载与展示.md#自渲染信息流)。

<a id="素材和视图"></a>

原“素材和视图”内容见[对应指南](docs/接入指南/广告加载与展示.md#素材和视图)。

<a id="列表复用和视频"></a>

原“列表复用和视频”内容见[对应指南](docs/接入指南/广告加载与展示.md#列表复用和视频)。

<a id="容器外-cta"></a>

原“容器外 CTA”内容见[对应指南](docs/接入指南/广告加载与展示.md#容器外-cta)。

<a id="s2s-和-header-bidding"></a>

原“S2S 和 Header Bidding”内容见[对应指南](docs/接入指南/竞价接入.md)。

<a id="资源隐私与网络"></a>

原“资源、隐私与网络”内容见[隐私与网络](docs/接入指南/隐私与网络.md)。

<a id="错误处理与常见问题"></a>

原“错误处理与常见问题”内容见[对应指南](docs/接入指南/错误处理与反馈.md)。

</details>
