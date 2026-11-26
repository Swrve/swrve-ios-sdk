// swift-tools-version:5.5
// OCMock's own Swift package compiles its sources with -fno-objc-arc, an "unsafe flag" Xcode refuses in
// remote packages. This local package wraps the prebuilt xcframework from OCMock's GitHub release instead.
import PackageDescription

let package = Package(
    name: "OCMock",
    platforms: [.iOS(.v15), .tvOS(.v15)],
    products: [
        .library(name: "OCMock", targets: ["OCMock"])
    ],
    targets: [
        .binaryTarget(
            name: "OCMock",
            url: "https://github.com/erikdoe/ocmock/releases/download/v3.9.4/OCMock.xcframework.zip",
            checksum: "e4c5169be218de7b5b4cd249cc23461c270855f7f718e1731d79fb6c66703a43"
        )
    ]
)
