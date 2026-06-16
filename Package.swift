// swift-tools-version:5.9

// YSIFLYADLib —— YS 媒体定制广告 SDK（model B 单包整变体）的 SwiftPM 分发清单。
// binaryTarget 指向 GitHub Releases 的 YSIFLYADLib.xcframework.zip（动态 framework，含 device + 模拟器双切片，
//   资源包 YSAdvSDK.bundle 内嵌于 framework，随动态 framework 整体嵌入消费方 app）；checksum 为 zip 的 sha256。
// 动态 framework 自动加载全部类/分类，消费方无需 -ObjC、无需额外资源声明。
// 换版本/主机：dev 仓重跑 rebrand + build-xcframework 后，据新 zip 的 checksum 同步更新此处 url/checksum 与版本。

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
            url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/1.0.3/YSIFLYADLib.xcframework.zip",
            checksum: "e5b871a93a66af01433e5324a9620f58093d0b92524b66b6393b2d8df6e47159"
        ),
    ]
)
