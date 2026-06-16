// swift-tools-version:5.9

// YSIFLYADLib —— YS 媒体定制广告 SDK（model B 单包整变体）的 SwiftPM 分发清单。
// binaryTarget 指向 GitHub Releases 的 YSIFLYADLib.xcframework.zip（含 device + 模拟器双切片，
//   资源包 YSAdvSDK.bundle 已内嵌于 framework）；checksum 为 zip 的 sha256。
// 静态库含 OC category / +load：SwiftPM 的 binaryTarget 不便注入 -ObjC（unsafeFlags 会使本包无法作为
//   带版本号依赖被消费），请在【消费方】App target 的 OTHER_LDFLAGS 自行加 -ObjC。
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
            url: "https://github.com/LJMcarryu/YSIFLYADLib_iOS/releases/download/1.0.0/YSIFLYADLib.xcframework.zip",
            checksum: "fb61be615062dabc19c17524037f6433e0d33824c339f2920920433a5d3948eb"
        ),
    ]
)
