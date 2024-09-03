// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Form",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "Form",
            targets: ["Form"]),
    ],
    dependencies: [
        .package(url: "https://github.com/izettle/Flow.git", .revision("fce5caed4500e490c8fadcd28893a7f207438bfe"))
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
