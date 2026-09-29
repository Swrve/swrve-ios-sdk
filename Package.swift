// swift-tools-version:5.3
import Foundation
import PackageDescription

let BinaryTargetSwrveSDK: Target = .binaryTarget(
    name: "SwrveSDK",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/10.11.1/SwrveSDKStatic.xcframework.zip",
    checksum: "1381f229feaca4b7aa471807de7a883b1fc33caa1f9e585b13eb25bf443a949f"
)

let BinaryTargetSwrveSDKCommon: Target = .binaryTarget(
    name: "SwrveSDKCommon",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/10.11.1/SwrveSDKCommonStatic.xcframework.zip",
    checksum: "9486cb2c06ae7c66d16d0184caf541b69ff8873f68181697da383fd1a8f2f7cf"
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
