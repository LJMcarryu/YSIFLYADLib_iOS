// swift-tools-version:5.9

// YSIFLYADLib —— YS 媒体定制广告 SDK（model B 单包整变体）的 SwiftPM 分发清单。
// binaryTarget 指向 GitHub Releases 的 YSIFLYADLib.xcframework.zip（6.0.12 起为【静态 framework】，
//   含 device + 模拟器双切片）；checksum 为 `swift package compute-checksum` 结果。
// 静态交付下资源包不再内嵌：SwiftPM 的 binaryTarget 不能挂资源，接入方须从同版本 Release 的
//   合并 zip（YSIFLYADLib-<版本>.zip）取 YSAdvSDK.bundle（含 PrivacyInfo.xcprivacy）手动加入
//   app target 的 Copy Bundle Resources；或改用 CocoaPods（podspec 已配 s.resources 自动投递）。
// 换版本/主机：dev 仓重跑 rebrand + build-xcframework + package-ys-release.sh 后，
//   据 checksums.txt 同步更新此处 url/checksum 与版本。

import PackageDescription

let package = Package(
    name: "YSIFLYADLib",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "YSIFLYADLib", targets: ["YSIFLYADLib"]),
    ],
    targets: [
        .binaryTarget(
            name: "YSIFLYADLib",
            url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/6.0.13/YSIFLYADLib.xcframework.zip",
            checksum: "c8b6b6913fb9abfa4c836b10e8729d0dd8d8176878c3020646c0b93f43053859"
        ),
    ]
)
