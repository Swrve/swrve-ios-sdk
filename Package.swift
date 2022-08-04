// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwrveSDK",
    platforms: [.iOS(.v10), .tvOS(.v9)],
    products: [
        .library(
            name: "SwrveSDKCommon",
            targets: ["SwrveSDKCommon"]),
        .library(
            name: "SwrveConversationSDK",
            targets: ["SwrveConversationSDK"]),
        .library(
            name: "SwrveSDK",
            targets: ["SwrveSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", .upToNextMajor(from: "5.13.0"))
    ],
    targets: [
        .target(
            name: "SwrveSDKCommon",
            path: "SwrveSDKCommon",
            resources: [
                   .process("LICENSE"),
                 ],
            publicHeadersPath: "include"),
        .target(
            name: "SwrveConversationSDK",
            dependencies: ["SwrveSDKCommon"],
            path: "SwrveConversationSDK",
            resources: [
                   .process("LICENSE"),
                   .process("Resources/VERSION"),
                   .process("Resources/VGConversationKitResources-Info.plist"),
                   .process("Conversation/SwrveConversationKit-Prefix.pch")
                 ],
            publicHeadersPath: "include"),
        .target(
            name: "SwrveSDK",
            dependencies: [
                    .product(name: "SDWebImage", package: "SDWebImage"),
                    "SwrveSDKCommon", 
                    "SwrveConversationSDK"
                ],
            path: "SwrveSDK",
            resources: [
                   .process("LICENSE"),
                 ],
            publicHeadersPath: "include")
    ],
    swiftLanguageVersions: [.v5]
)

