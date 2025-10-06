// swift-tools-version:5.3
import Foundation
import PackageDescription

let BinaryTargetSwrveSDK: Target = .binaryTarget(
    name: "SwrveSDK",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/10.8.0/SwrveSDKStatic.xcframework.zip",
    checksum: "ad5b27cd3abb0496818841e761669b806aafec531b21d9345c9a262acc034bed"
)

let BinaryTargetSwrveSDKCommon: Target = .binaryTarget(
    name: "SwrveSDKCommon",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/10.8.0/SwrveSDKCommonStatic.xcframework.zip",
    checksum: "1772a98caf5e197867e401280aef31afdab69a8ed59184a52ec4adfe161efa07"
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
