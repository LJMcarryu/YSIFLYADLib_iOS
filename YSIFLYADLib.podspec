# YSIFLYADLib —— YS 媒体定制广告 SDK（model B 单包，自包含整变体）。
# 由 IFLYADLib 私有 dev 仓经 scripts/rebrand.sh --brand ys + build-xcframework.sh --brand ys --variant YSNoReward 产出：
#   类型名前置 YS（YSIFLYSplashAd…）、公开方法前置 ysifly_、资源包 YSAdvSDK.bundle（内嵌于 framework）、日志 [YSAd]。
# 变体 = Full 关闭 REWARD、保留 VIDEO：开屏 / Banner / 插屏 / 信息流（含视频），无激励视频。
# 交付为【动态 framework】：YSAdvSDK.bundle 随 framework 整体嵌入消费方 app（静态 framework 不会投递内嵌资源包），
#   因此无需单独 resource_bundles，也无需消费方加 -ObjC（动态 framework 自动加载全部类/分类）。
# 换版本/主机：dev 仓重跑 rebrand + build-xcframework，更新本仓 :http URL / Package.swift checksum 与版本。

Pod::Spec.new do |s|
  s.name     = 'YSIFLYADLib'
  s.version  = '6.0.5'
  s.summary  = 'YSIFLYADLib —— YS 媒体定制广告 SDK（开屏/Banner/插屏/信息流，含视频，无激励）。'
  s.homepage = 'https://github.com/LJMcarryu/YSIFLYADLib_iOS'
  s.author   = { 'YS' => 'placeholder@example.com' }
  s.source   = { :http => 'https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/6.0.5/YSIFLYADLib.xcframework.zip' }
  s.license  = { :type => 'MIT' }

  s.platform = :ios, '13.0'
  s.vendored_frameworks = 'YSIFLYADLib.xcframework'
end
