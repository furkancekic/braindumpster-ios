// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TaskApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "TaskApp",
            targets: ["TaskApp"]),
    ],
    targets: [
        .target(
            name: "TaskApp",
            path: "."
        )
    ]
)
