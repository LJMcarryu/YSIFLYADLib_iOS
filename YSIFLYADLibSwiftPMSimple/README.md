# SwiftPM 接入示例

此独立示例固定使用 SDK `6.5.5-beta.1`；仓库当前发布版本另见[根 README](../README.md)。工程包含与本仓 CocoaPods Demo 对应的广告示例页面，应用 Bundle Identifier 独立，可以分别安装对比。示例源码是生成时的独立副本。

## 激励预发布版

本示例使用的 `6.5.5-beta.1` 新增图片与视频激励广告，首页显示“激励广告”入口。先在本副本 `YSIFLYADLibSimple/Supporting Files/YSIFLYAdPrefixHeader.pch` 填写 `__REWARD_AD_UNIT_ID__`，空值不会发起请求。

操作为 `Load` → `DidReady` → `Show` → 奖励回调 / 关闭。页面仅记录奖励生效，不发放真实业务奖励；播放完成、失败和关闭不代替奖励生效回调。接入要求与源码见[激励指南](../docs/接入指南/广告加载与展示.md#激励广告655-beta1)。本示例的依赖解析、构建与静态核对范围见下方“已验证范围”；广告运行仍须在宿主 App 联调。

## 获取示例

使用 [GitHub main 分支源码 ZIP](https://github.com/LJMcarryu/YSIFLYADLib_iOS/archive/refs/heads/main.zip)，解压后进入 `YSIFLYADLib_iOS-main/YSIFLYADLibSwiftPMSimple/`。不要只下载本页、`.xcodeproj` 或准备脚本，工程依赖同目录源码与资源。也可以从终端获取：

```bash
git clone --branch main --single-branch https://github.com/LJMcarryu/YSIFLYADLib_iOS.git
cd YSIFLYADLib_iOS/YSIFLYADLibSwiftPMSimple
```

以下命令均在这个示例目录执行。已有仓库先确认使用最新 main，并检查本页声明的 SDK 版本；当前 main 的独立示例固定使用 `6.5.5-beta.1`，历史 Tag 的示例不会随 main 更新。安装自己的 App 请按[安装指南](../docs/接入指南/安装与资源配置.md)操作。

## 运行

无需运行 `pod install`。打开共享 workspace：

```bash
open YSIFLYADLibSwiftPMSimple.xcworkspace
```

Xcode 自动从 `https://github.com/LJMcarryu/YSIFLYADLib_iOS.git` 解析 **Exact Version 6.5.5-beta.1**，选择的 Product 为 **YSIFLYADLib**；二进制从 TOS 下载。提交的 `Package.resolved` 绑定该版本 Tag。初次构建需联网，后续不要同时添加 Pods 或手动 framework。

在 Xcode 选择 **YSIFLYADLibSwiftPMSimple** scheme，再选择模拟器或真机。真机运行时设置自己的 Team 与 Bundle Identifier，替换源码 `Supporting Files` 中的广告位配置。示例 ID 不保证填充。工程最低声明 iOS 11.0，实际可用系统范围需结合所用 Xcode 与 SDK 验证。

App target 已配置 `$(inherited) -ObjC`、`AdSupport.framework` 和 Optional 的 `AppTrackingTransparency.framework`。请保留应用隐私流程与系统授权处理；构建通过不代表广告已成功加载或展示。

页面使用与各广告形式 API 见[接入指南](../docs/接入指南/README.md)；本副本的源码目录仍为 `YSIFLYADLibSimple/`。日志或请求失败须按实际回调和系统日志定位。

## 构建检查

```bash
xcodebuild -workspace YSIFLYADLibSwiftPMSimple.xcworkspace \
  -scheme YSIFLYADLibSwiftPMSimple -configuration Debug -scmProvider system \
  -destination 'generic/platform=iOS Simulator' -sdk iphonesimulator \
  -derivedDataPath build/DerivedData ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO build
```

## 运行与排错

构建成功后运行 App，首页应显示 SDK `6.5.5-beta.1`。广告位宏、页面按钮顺序及回调观察见 [CocoaPods 示例的页面说明](../YSIFLYADLibSimple/README.md)；本副本中的对应源码仍位于 `YSIFLYADLibSimple/`，请修改本副本文件，不是另一示例的文件。内置格式等待 Ready 后 Show；信息流按页面完成加载、渲染与挂载。无填充不能据此认定安装失败。

若找不到 workspace，先确认终端目录；若依赖下载失败，先恢复网络并重试。资源缺失、重复符号和模块名问题见[安装排查](../docs/接入指南/安装与资源配置.md#安装失败排查)。

## 已验证范围

2026-11-25，固定 SDK `6.5.5-beta.1`，使用 Xcode 26.2（17C52）通过本示例原生 workspace 完成真实 SwiftPM 依赖解析，以及 Debug 的 iOS Simulator arm64 和 iOS 设备 arm64 构建；设备构建关闭代码签名。`Package.resolved` 由 Xcode 实际解析生成，绑定 Tag 对应提交 `02f456849b372fdf05329f7ab30e986f99c8ecc6`。

两种产物均核对 SDK 版本、五种广告形式链接符号、一份 `YSAdvSDK.bundle` 及隐私清单；bundle 内 62 个文件与解析到的同版包资源逐项一致。在 iOS 26.2 模拟器安装并启动 App，核对版本、进入激励页并验证空广告位 Load 提示。签名安装、真实媒体宿主、x86_64 和 iOS 11 设备运行未验证；最低部署目标仍为 iOS 11.0；Xcode 对该目标给出支持范围从 iOS 12.0 起的警告，设备链接还提示 SwiftPM 资源目标按 iOS 12.0 构建。本轮不据此声明 iOS 11 运行兼容性。

## 版本维护

此示例不会随仓库当前版本自动升级。更新依赖时同时更新工程、锁文件或资产摘要、同版资源及说明，并重新验证模拟器与设备架构。不得混用不同版本的库与资源。`示例来源.json` 记录本副本的 SDK Tag 和示例源码提交。
