# YS 定制 SDK：开屏、Banner、插屏和信息流（含视频）。

Pod::Spec.new do |s|
  s.name     = 'YSIFLYADLib'
  s.version  = '6.5.0'
  s.summary  = 'YSIFLYADLib —— YS 媒体定制广告 SDK（开屏/Banner/插屏/信息流，含视频，无激励）。'
  s.homepage = 'https://github.com/LJMcarryu/YSIFLYADLib_iOS'
  s.author   = { 'LJMcarryu' => 'jmliu6@iflytek.com' }
  s.source   = { :http => 'https://download-adsdk.voiceads.cn/ios_sdk/6.5.0/ys/YSIFLYADLib-6.5.0.zip' }
  s.license  = { :type => 'MIT', :file => 'LICENSE' }
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
