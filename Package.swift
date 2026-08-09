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
    // 6.2.2 正式二进制按 iOS 11 构建；资源由资源 target 同步投递。
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(name: "YSIFLYADLib", targets: ["YSIFLYADLib", "YSIFLYADLibResources"]),
    ],
    targets: [
        .binaryTarget(
            name: "YSIFLYADLib",
            // checksum 来自 6.2.2 正式冻结的签名 zip，不得替换为本地重打包产物。
            url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/6.2.2/YSIFLYADLib.xcframework.zip",
            checksum: "757f133d00cbd248366392f1dbf460adbd35089588c8da57b1cf947adc7f813d"
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
