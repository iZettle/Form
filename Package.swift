// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "Form",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Form",
            targets: ["Form"]),
    ],
    dependencies: [
        .package(url: "https://github.com/iZettle/Flow.git", branch: "xcode-16")
    ],
    targets: [
        .target(
            name: "Form",
            dependencies: ["Flow"],
            path: "Form"),
        .testTarget(
            name: "FormTests",
            dependencies: ["Form"],
            path: "FormTests"),
    ]
)
