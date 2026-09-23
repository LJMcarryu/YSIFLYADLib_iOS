# YS 广告接入示例

本工程使用 `YSIFLYADLib 6.4.0`，演示开屏、Banner、插屏和自渲染信息流，支持信息流列表复用及视频素材。SDK 不包含激励广告。

先按本文运行和替换广告位；将能力接入自己的 App 时，参考[SDK 接入说明](../README.md)与各页面代码。

> 本示例的 `Podfile` 固定正式版本 `6.4.0`。版本公开状态与消费验证结论以 `release-state.json.publication` 和同版本 GitHub Release 的实际状态为准。
>
> `6.4.0` 的公开 API 方法签名不变。展示、落地页、外跳回流、曝光判断和 UI 生命周期应归属广告的实际来源 window/Scene；无来源时只允许唯一且明确的前台应用 Scene，不跨 Scene 随机兜底，独立落地页始终属于来源 Scene。开屏 rootVC 仍须入窗；Scene 宿主的 `customWindow` 必须可见、尺寸有限且为正、已关联 Scene，并与 `rootVC.window` 同 Scene，可以是非 key、高 `windowLevel`、无 rootVC。非法输入展示失败，修正后可以重试。

## 从下载到运行

准备 macOS、Xcode、CocoaPods 和可访问 GitHub Releases 的网络。最低部署目标为 iOS 11.0。使用模拟器可检查安装、链接和页面；真实广告填充、跳转和 ATT 请用真机联调。

```bash
git clone https://github.com/LJMcarryu/YSIFLYADLib_iOS.git
cd YSIFLYADLib_iOS/YSIFLYADLibSimple
pod install
open YSIFLYADLibSimple.xcworkspace
```

1. 在 Xcode 选择 `YSIFLYADLibSimple` scheme 和模拟器或已连接的 iPhone。
2. 真机运行前，在 App target 的 **Signing & Capabilities** 选择自己的 Team；必要时将 Bundle Identifier 改为自己的标识。
3. 按下文替换广告位，确认后台授权的 App 信息与当前 App 一致，然后运行。
4. 首页应显示 `SDK Version: 6.4.0`。示例的 `Podfile` 固定使用正式版 `6.4.0`，示例页面可以随本仓库更新。

使用 CocoaPods 后始终打开 `.xcworkspace`。它自动加入 `YSAdvSDK.bundle`（含隐私清单）和 `-ObjC`；不需再手工嵌入静态 framework。其他安装方式见[SDK 接入说明](../README.md#安装)。

## 配置广告位与请求

打开 [`YSIFLYAdPrefixHeader.pch`](YSIFLYADLibSimple/Supporting%20Files/YSIFLYAdPrefixHeader.pch)，将需要体验的宏替换为媒体获分配的广告位 ID。仓库内的示例 ID 不保证填充；图片、视频等结果以广告位配置和实际返回为准。

| 宏 | 对应页面/选项 |
| --- | --- |
| `__SPLASH_NATIVE_AD_UNIT_ID__` | 开屏 / 图片开屏 |
| `__SPLASH_VIDEO_AD_UNIT_ID__` | 开屏 / 视频开屏 |
| `__BANNER_AD_UNIT_ID__` | Banner |
| `__INTERSTITIAL_AD_UNIT_ID__` | 插屏 |
| `__TYPED_ONE_NATIVE_AD_UNIT_ID__` | 自渲染信息流 / 单图 |
| `__TYPED_MORE_NATIVE_AD_UNIT_ID__` | 自渲染信息流 / 多图 |
| `__FEED_VIDEO_AD_UNIT_ID__` | 自渲染信息流 / 视频 |

公共请求参数在 [`YSIFLYADUtil.m`](YSIFLYADLibSimple/Supporting%20Files/YSIFLYADUtil.m) 的 `mediaSampleRequestConfig` 中：示例超时为 5 秒，`settleType = @1`、`bidFloor = @0.01`、`interactStatus = @1`。这些是演示值，业务接入请按平台约定调整，勿将示例价格作为正式结算配置。App 名称与版本从宿主信息读取。

SDK 不要求额外 App ID 初始化。广告位须与媒体获授权的 App 和广告形式匹配。启动配置见 [`AppDelegate.m`](YSIFLYADLibSimple/AppDelegate.m)，首页入口见 [`ViewController.m`](YSIFLYADLibSimple/ViewController.m)。

## 隐私与网络设置

- 示例在 App 激活后申请 ATT，并在每次请求时检查授权、过滤全零 IDFA。拒绝 ATT 时继续以空 IDFA 请求；不要为了取得 IDFA 重复弹窗。
- 示例不包含生产 App 的隐私同意页面。接入自己的 App 时，应按用户授权和业务要求安排 SDK 使用时机；`ysifly_setPersonalizedEnabled:` 只记录状态，不会代替隐私流程或停止广告请求。
- [`Info.plist`](YSIFLYADLibSimple/Info.plist) 含 `NSUserTrackingUsageDescription` 和用于测试素材的 ATS 例外。生产 App 请使用准确的用途文案，并按实际网络需求收窄 ATS 配置。
- 示例开启日志便于查看回调。上线前按需关闭 `ysifly_setLogEnabled:`，反馈问题时隐藏设备标识、Token 和业务敏感数据。

## 页面与操作对照

| 首页入口 | 示例文件 | 操作与观察重点 |
| --- | --- | --- |
| 开屏广告 | [YSIFLYSplashViewController.m](YSIFLYADLibSimple/biz/splash/YSIFLYSplashViewController.m) | 选择图片/视频，点击 `Load`，等 Ready 后点击 `Show`；观察底部品牌区、跳过和关闭 |
| Banner 广告 | [YSIFLYBannerViewController.m](YSIFLYADLibSimple/biz/banner/YSIFLYBannerViewController.m) | `Load` → Ready → `Show`；广告显示在页面内的 Banner 容器 |
| 插屏广告 | [YSIFLYInterstitialViewController.m](YSIFLYADLibSimple/biz/interstitial/YSIFLYInterstitialViewController.m) | 选择半屏/全屏，`Load` → Ready → `Show`；观察展示、曝光与关闭回调 |
| 自渲染信息流 | [YSIFLYNativeViewController.m](YSIFLYADLibSimple/biz/native/YSIFLYNativeViewController.m) | 广告行进入屏幕后自动加载；切换单图/多图/视频后点“加载 / 换一条”；离屏再回屏检查原广告恢复 |

开屏、Banner、插屏页面中的 `Show` 初始禁用，Ready 且广告有效后启用；“检查状态”记录有效性与公开竞价信息；`Destroy` 终止当前对象。再次点 `Load` 会先清理旧对象，再新建广告请求。演示开屏手动展示，实际启动场景由宿主在合适时机展示。

信息流页面把一条广告插入普通内容列表。数据层持有广告对象，Cell 在素材 UI 准备好后调用 `ysifly_attachWithViewBinder:error:`。离屏和 `prepareForReuse` 都按具体容器同步调用 `ysifly_detachAdFromContainerView:`；滚回时复用原广告对象。“永久淘汰”释放当前广告对象，点“加载 / 换一条”可请求新广告；空广告行再次进入屏幕时也会自动请求。不要将离屏操作替换为 `ysifly_destroy`。

信息流单图/多图由示例下载并显示，视频容器交给 SDK。标题、广告标识、关闭按钮与可点击区域见 Cell 的 `renderAd:` 和 `viewBinderForAd:`；`Exposure` / `Unknown` 素材使用空 `clickViews`。业务点击和跳转交给 SDK，媒体无需为 CTA 再加跳转逻辑。

## 如何确认接入成功

构建成功、展示成功和线上有填充是不同层面的结果，可依次检查：

1. **安装与启动**：`pod install` 成功，workspace 构建通过，App 首页显示 `6.3.5` 和四种广告入口。
2. **内置渲染**：加载后看到 `DidLoad`，随后 `DidReady`；点击 `Show` 后广告可见，日志有展示/曝光回调；关闭后页面可继续操作。
3. **自渲染**：有 `nativeFeedAdDidLoad`，素材显示且挂载成功，进入有效可见状态后收到曝光回调；视频素材在曝光后按播放策略播放。
4. **列表复用**：广告离屏再回屏能恢复；同一逻辑广告不重复触发曝光回调。换一条后旧图片或旧回调不应覆盖新广告。
5. **交互与退出**：真机验证可点击素材的点击、跳转、返回；退出页面后不再展示该页广告。网络失败或无填充时应显示错误并允许主动重试。

`DidLoad` 仅表示响应解析成功；开屏、Banner、插屏仍须等待 `DidReady`。信息流没有 Ready 回调，由媒体完成素材 UI 再 attach。收到失败回调且页面仍可操作，表示失败路径已执行，不能据此认定展示成功。

## 常见问题

| 现象 | 检查方法 |
| --- | --- |
| `pod install` 下载失败 | 确认能访问 `raw.githubusercontent.com` 和本版本 GitHub Release；保留失败 URL/错误后重试，检查代理、证书和网络限制 |
| `No such module` / 找不到头文件 | 确认依赖安装完成，打开的是 workspace，且当前选择 `YSIFLYADLibSimple` scheme |
| 真机签名失败 | 配置自己的 Team、Bundle Identifier 与设备授权；这类错误发生在运行广告请求之前 |
| 首页版本不是 `6.3.5` | 核对 `Podfile`、安装输出和 `Pods/Manifest.lock`；清理旧构建后重新从 workspace 运行 |
| Show 不可点击 | 等待 Ready，查看失败回调；`DidLoad` 不等于素材就绪，失效实例需要重新加载 |
| 无填充 / 请求超时 | 核对广告位、App 信息、后台授权和网络；示例 ID 或模拟器不保证填充，不要连续无间隔重试 |
| 信息流挂载失败 | 查看错误码和描述，检查主线程、素材完整性、容器布局及视频 `videoView`；完整规则见根 README |
| 信息流回屏为空 | 确认数据层仍持同一个 Ad，离屏只按具体容器 detach；如果已过期，释放旧对象后请求新广告 |
| IDFA 为空 | 检查 ATT 状态；拒绝/未决定时为空是预期行为，授权后在新请求中重新读取 |
| 视频/图标缺失 | 核对 App 中存在一份 `YSAdvSDK.bundle`，并检查素材下载错误；不要重复拷贝资源或重复接入不同 YS 包 |

反馈请使用 [Issues](https://github.com/LJMcarryu/YSIFLYADLib_iOS/issues)，附 SDK/iOS/Xcode 版本、真机或模拟器、页面与操作顺序、错误码和脱敏后的日志。版本变化见[更新记录](../CHANGELOG.md)。
