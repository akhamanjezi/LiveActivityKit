// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LiveActivityKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "LiveActivityKit",
            targets: ["LiveActivityKit"]),
    ],
    targets: [
        .target(
            name: "LiveActivityKit"),
        .testTarget(
            name: "LiveActivityKitTests",
            dependencies: ["LiveActivityKit"]),
    ]
)
