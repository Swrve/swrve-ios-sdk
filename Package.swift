// swift-tools-version:5.3
import Foundation
import PackageDescription

let BinaryTargetSwrveSDK: Target = .binaryTarget(
    name: "SwrveSDK",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/9.1.0/SwrveSDKStatic.xcframework.zip",
    checksum: "012013e1f14df46628e914cb69dd51e9520e985b5d857b1e8889f633f69784ec"
)

let BinaryTargetSwrveSDKCommon: Target = .binaryTarget(
    name: "SwrveSDKCommon",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/9.1.0/SwrveSDKCommonStatic.xcframework.zip",
    checksum: "79fc5dd6f7cff360c9fdf91e801a8bf9930e1185725d1b7bf326bc09a3879451"
)

let package = Package(
    name: "SwrveSDK",
    platforms: [.iOS(.v12), .tvOS(.v12)],
    products: [
        .library(name: "SwrveSDKCommon", targets: ["SwrveSDKCommon"]),
        .library(name: "SwrveSDK", targets: ["SwrveSDKWrapper"])
    ],
    dependencies: [.package(url: "https://github.com/SDWebImage/SDWebImage.git", .upToNextMajor(from: "5.13.0"))],
    targets: [
        .target(
            name: "SwrveSDKWrapper",
            dependencies: [.product(name: "SDWebImage", package: "SDWebImage"), "SwrveSDKCommon", "SwrveSDK"],
            path: "SwrveSDKWrapper"
        ),
        BinaryTargetSwrveSDK,
        BinaryTargetSwrveSDKCommon
    ],
    swiftLanguageVersions: [.v5]
)
