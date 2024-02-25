// swift-tools-version: 5.7.1

import PackageDescription

let package = Package(
    name: "LiveActivityKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "LiveActivityKit",
            targets: ["LiveActivityKit"]),
    ],
    targets: [
        .target(
            name: "LiveActivityKit"),
    ]
)
