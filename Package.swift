// swift-tools-version:5.9

// YSIFLYADLib —— YS 媒体定制广告 SDK（model B 单包整变体）的 SwiftPM 分发清单。
// binaryTarget 指向 GitHub Releases 的 YSIFLYADLib.xcframework.zip（6.0.12 起为【静态 framework】，
//   含 device + 模拟器双切片）；checksum 为 `swift package compute-checksum` 结果。
// 6.1.0 起由 YSIFLYADLibResources 源码 target 投递外置 YSAdvSDK.bundle（含
//   PrivacyInfo.xcprivacy），与 binaryTarget 一起组成同名 product，接入方无需再手工复制资源。
// 换版本/主机：dev 仓重跑 rebrand + build-xcframework + package-ys-release.sh 后，
//   据 checksums.txt 同步更新此处 url/checksum 与版本。

import PackageDescription

let package = Package(
    name: "YSIFLYADLib",
    // 6.3.0 目标二进制继续按 iOS 11 构建；资源由资源 target 同步投递。
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(name: "YSIFLYADLib", targets: ["YSIFLYADLib", "YSIFLYADLibResources"]),
    ],
    targets: [
        .binaryTarget(
            name: "YSIFLYADLib",
            // 6.3.0 冻结签名 zip 的 SwiftPM 校验值。
            url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/6.3.0/YSIFLYADLib.xcframework.zip",
            checksum: "73a1e82ffee9c01d63f1e6a391c732e8837c422d23ab60846c92e8f2c167ad08"
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
