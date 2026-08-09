// swift-tools-version:5.9

// Release CI 将本次正式二进制和受版本控制的资源复制到本清单旁，
// 以本地 binaryTarget 实际构建 SwiftPM 产品，再链接最小消费端。

import PackageDescription

let package = Package(
    name: "YSIFLYADLibReleaseValidation",
    platforms: [
        .iOS("11.0"),
    ],
    products: [
        .library(
            name: "YSIFLYADLib",
            targets: ["YSIFLYADLib", "YSIFLYADLibResources"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "YSIFLYADLib",
            path: "YSIFLYADLib.xcframework"
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
