// swift-tools-version:5.9

// YS 定制 SDK；product 自动包含资源与隐私清单。
// 在宿主 App target 的 Other Linker Flags 中添加 -ObjC。

import PackageDescription

let package = Package(
    name: "YSIFLYADLib",
    // 6.5.2 目标二进制继续按 iOS 11 构建；资源由资源 target 同步投递。
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(name: "YSIFLYADLib", targets: ["YSIFLYADLib", "YSIFLYADLibResources"]),
    ],
    targets: [
        .binaryTarget(
            name: "YSIFLYADLib",
            url: "https://download-adsdk.voiceads.cn/ios_sdk/6.5.3/ys/YSIFLYADLib.xcframework.zip",
            checksum: "b130894667b054d51f7f781fadf9d13e8829b5c1d900cc2bda1cfb0f02ac6e16"
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
