# YSIFLYADLib —— YS 媒体定制广告 SDK（model B 单包，自包含整变体）。
# 由 IFLYADLib 私有 dev 仓经 scripts/rebrand.sh --brand ys + build-xcframework.sh --brand ys --variant YSNoReward 产出：
#   类型名前置 YS（YSIFLYSplashAd…）、公开方法前置 ysifly_、资源包 YSAdvSDK.bundle、日志 [YSAd]。
# 变体 = Full 关闭 REWARD、保留 VIDEO：开屏 / Banner / 插屏 / 信息流（含视频），无激励视频。
# 6.0.12 起交付为【静态 framework】（应媒体要求，由动态切换）：静态 framework 不投递内嵌资源，
#   故 YSAdvSDK.bundle（含 PrivacyInfo.xcprivacy）外置于合并 zip 根，经 s.resources 由 CocoaPods
#   拷入 app 主包，SDK 运行时按 mainBundle 定位；类与 category 随 app 静态链接，无需 embed、无需 -ObjC
#   （SDK 无独立 category 编译单元，category 均随宿主类 .o 链入）。
# 换版本/主机：dev 仓重跑 rebrand + build-xcframework + package-ys-release.sh，更新本仓 :http URL / Package.swift checksum 与版本。

Pod::Spec.new do |s|
  s.name     = 'YSIFLYADLib'
  s.version  = '6.0.12'
  s.summary  = 'YSIFLYADLib —— YS 媒体定制广告 SDK（开屏/Banner/插屏/信息流，含视频，无激励）。'
  s.homepage = 'https://github.com/LJMcarryu/YSIFLYADLib_iOS'
  s.author   = { 'YS' => 'placeholder@example.com' }
  s.source   = { :http => 'https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/6.0.12/YSIFLYADLib-6.0.12.zip' }
  s.license  = { :type => 'MIT', :file => 'LICENSE' }

  s.platform = :ios, '13.0'
  s.static_framework = true
  s.vendored_frameworks = 'YSIFLYADLib.xcframework'
  s.resources = ['YSAdvSDK.bundle']
end
