// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RefreshableScrollView",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_15),
        .tvOS(.v11),
        .watchOS(.v4),
    ],
    products: [
        .library(
            name: "RefreshableScrollView",
            targets: ["RefreshableScrollView"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "RefreshableScrollView",
            dependencies: []),
        .testTarget(
            name: "RefreshableScrollViewTests",
            dependencies: ["RefreshableScrollView"]),
    ]
)
