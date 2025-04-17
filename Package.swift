// swift-tools-version:5.3
import Foundation
import PackageDescription

let BinaryTargetSwrveSDK: Target = .binaryTarget(
    name: "SwrveSDK",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/10.4.0/SwrveSDKStatic.xcframework.zip",
    checksum: "fe7afe398230e7050ace49e019b43613412a05ec8f52a93fd52d2645a56d3fa2"
)

let BinaryTargetSwrveSDKCommon: Target = .binaryTarget(
    name: "SwrveSDKCommon",
    url: "https://github.com/Swrve/swrve-ios-sdk/releases/download/10.4.0/SwrveSDKCommonStatic.xcframework.zip",
    checksum: "1bcc38fc06366748a25bf23ef15a9b90f1598ba73fc320a1dc77559b5a7655db"
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
