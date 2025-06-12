// swift-tools-version:5.3
import Foundation
import PackageDescription

let BinaryTargetSwrveSDK: Target = .binaryTarget(
    name: "SwrveSDK",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/10.5.0/SwrveSDKStatic.xcframework.zip",
    checksum: "0a2a45be543e0fc1b5d8432e369d71249c74091e4a66fe48e5864e1c9eea3bbd"
)

let BinaryTargetSwrveSDKCommon: Target = .binaryTarget(
    name: "SwrveSDKCommon",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/10.5.0/SwrveSDKCommonStatic.xcframework.zip",
    checksum: "6b3011cb5641c51eee3c95a788fda11fe964439ce69ae6feba33fc02800dddc8"
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
