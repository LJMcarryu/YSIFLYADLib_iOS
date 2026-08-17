# YSIFLYADLib —— YS 媒体定制广告 SDK（model B 单包，自包含整变体）。
# 由 IFLYADLib 私有 dev 仓经 scripts/rebrand.sh --brand ys + build-xcframework.sh --brand ys --variant YSNoReward 产出：
#   类型名前置 YS（YSIFLYSplashAd…）、公开方法前置 ysifly_、资源包 YSAdvSDK.bundle、日志 [YSAd]。
# 变体 = Full 关闭 REWARD、保留 VIDEO：开屏 / Banner / 插屏 / 信息流（含视频），无激励视频。
# 6.0.12 起交付为【静态 framework】（应媒体要求，由动态切换）：静态 framework 不投递内嵌资源，
#   故 YSAdvSDK.bundle（含 PrivacyInfo.xcprivacy）外置于合并 zip 根，经 s.resources 由 CocoaPods
#   拷入 app 主包，SDK 运行时按 mainBundle 定位；静态 framework 无需 embed，但最终 App 链接需 -ObjC。
#   CocoaPods 同时在 pod target 与 aggregate/user target 注入；SwiftPM 和手动接入由宿主 App 配置。
# SwiftPM 由 Package.swift 的 YSIFLYADLibResources target 从仓库 tag 自动投递同一资源包。
# 换版本/主机：dev 仓重跑 rebrand + build-xcframework + package-ys-release.sh，更新本仓 :http URL / Package.swift checksum 与版本。

Pod::Spec.new do |s|
  s.name     = 'YSIFLYADLib'
  s.version  = '6.2.4'
  s.summary  = 'YSIFLYADLib —— YS 媒体定制广告 SDK（开屏/Banner/插屏/信息流，含视频，无激励）。'
  s.homepage = 'https://github.com/LJMcarryu/YSIFLYADLib_iOS'
  s.author   = { 'LJMcarryu' => 'jmliu6@iflytek.com' }
  s.source   = { :http => 'https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/6.2.4/YSIFLYADLib-6.2.4.zip' }
  s.license  = { :type => 'MIT', :file => 'LICENSE' }

  # iOS 11 声明只可随重新构建并验证过的新版本二进制发布；不得套用到旧 release 产物。
  s.platform = :ios, '11.0'
  s.static_framework = true
  s.vendored_frameworks = 'YSIFLYADLib.xcframework'
  s.resources = ['YSAdvSDK.bundle']
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '$(inherited) -ObjC' }
  # 静态 XCFramework 最终由宿主 App 链接，必须把 -ObjC 传播到 aggregate/user target。
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '$(inherited) -ObjC' }
  s.frameworks = 'AdSupport'
  # iOS 14 起使用 ATT；弱链接保证 iOS 11～13 不要求该系统 framework 存在。
  s.weak_frameworks = 'AppTrackingTransparency'
end
