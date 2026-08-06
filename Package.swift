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
    // 6.2.0 的静态 binaryTarget 已按 iOS 11 重新构建，最终资源包已同步到资源 target。
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(name: "YSIFLYADLib", targets: ["YSIFLYADLib", "YSIFLYADLibResources"]),
    ],
    targets: [
        .binaryTarget(
            name: "YSIFLYADLib",
            // checksum 来自 6.2.0 正式签名 zip，并已与 Release 清单核对。
            url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/6.2.0/YSIFLYADLib.xcframework.zip",
            checksum: "e09dae72512e99ada35c35f55eee0b295bb443fc3d40f3cc2b4ea266cb0a4467"
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
