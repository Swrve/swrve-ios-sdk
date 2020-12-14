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
    targets: [
        .target(
            name: "SwrveSDKCommon",
            path: "SwrveSDKCommon",
            resources: [
                   .process("LICENSE"),
                 ]
        .target(
            name: "SwrveConversationSDK",
            dependencies: ["SwrveSDKCommon"],
            path: "SwrveConversationSDK",
            resources: [
                   .process("LICENSE"),
                   .process("Resources/VERSION"),
                   .process("Resources/VGConversationKitResources-Info.plist"),
                   .process("Conversation/SwrveConversationKit-Prefix.pch")
                 ]
        .target(
            name: "SwrveSDK",
            dependencies: ["SwrveSDKCommon", "SwrveConversationSDK"],
            path: "SwrveSDK",
            resources: [
                   .process("LICENSE"),
                 ]
    ],
    swiftLanguageVersions: [.v5]
)

