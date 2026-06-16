# YSIFLYADLib —— YS 媒体定制广告 SDK（model B 单包，自包含整变体）。
# 由 IFLYADLib 私有 dev 仓经 scripts/rebrand.sh --brand ys + build-xcframework.sh --variant YSNoReward 产出：
#   类型名前置 YS（YSIFLYSplashAd…）、公开方法前置 ysifly_、资源包 YSAdvSDK.bundle（已内嵌于 framework）、日志 [YSAd]。
# 变体 = Full 关闭 REWARD、保留 VIDEO：开屏 / Banner / 插屏 / 信息流（含视频），无激励视频。
# 资源 bundle YSAdvSDK.bundle 已打入 YSIFLYADLib.xcframework，无需单独 resource_bundles。
# 换版本/主机：dev 仓重跑 rebrand + build-xcframework，更新本仓 :http URL / Package.swift checksum 与版本。

Pod::Spec.new do |s|
  s.name     = 'YSIFLYADLib'
  s.version  = '1.0.0'
  s.summary  = 'YSIFLYADLib —— YS 媒体定制广告 SDK（开屏/Banner/插屏/信息流，含视频，无激励）。'
  s.homepage = 'https://github.com/LJMcarryu/YSIFLYADLib_iOS'
  s.author   = { 'YS' => 'placeholder@example.com' }
  s.source   = { :http => 'https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/1.0.0/YSIFLYADLib.xcframework.zip' }
  s.license  = { :type => 'MIT' }

  s.platform = :ios, '13.0'
  s.static_framework = true
  s.vendored_frameworks = 'YSIFLYADLib.xcframework'

  # 静态库内含 OC category / +load，消费方需 -ObjC
  s.pod_target_xcconfig  = { 'OTHER_LDFLAGS' => '-ObjC' }
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '-ObjC' }
end
