// swift-tools-version:5.9

// YSIFLYADLib —— YS 媒体定制广告 SDK（model B 单包整变体）的 SwiftPM 分发清单。
// binaryTarget 指向 TOS 的 YSIFLYADLib.xcframework.zip（6.0.12 起为【静态 framework】，
//   含 device + 模拟器双切片）；checksum 为 `swift package compute-checksum` 结果。
// 6.1.0 起由 YSIFLYADLibResources 源码 target 投递外置 YSAdvSDK.bundle（含
//   PrivacyInfo.xcprivacy），与 binaryTarget 一起组成同名 product，接入方无需再手工复制资源。
// 换版本/主机：dev 仓重跑 rebrand + build-xcframework + package-ys-release.sh 后，
//   据 checksums.txt 同步更新此处 url/checksum 与版本。

import PackageDescription

let package = Package(
    name: "YSIFLYADLib",
    // 6.5.0 目标二进制继续按 iOS 11 构建；资源由资源 target 同步投递。
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(name: "YSIFLYADLib", targets: ["YSIFLYADLib", "YSIFLYADLibResources"]),
    ],
    targets: [
        .binaryTarget(
            name: "YSIFLYADLib",
            // 6.5.0 极速发布资产摘要；verification=not-run。
            url: "https://download-adsdk.voiceads.cn/ios_sdk/6.5.0/ys/YSIFLYADLib.xcframework.zip",
            checksum: "7785f376d93d544e6993bba28f93429a132c14987198566bd75bfe6edd149d45"
        ),
        .target(
            name: "YSIFLYADLibResources",
            path: "spm/YSIFLYADLibResources",
            resources: [
                .copy("YSAdvSDK.bundle"),
            ]
        ),
    ]
)
