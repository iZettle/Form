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
        .package(url: "https://github.com/iZettle/Flow.git", revision:"fce5caed4500e490c8fadcd28893a7f207438bfe")
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
