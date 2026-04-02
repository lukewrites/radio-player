// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RadioPlayer",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RadioPlayer",
            targets: ["RadioPlayer"]
        ),
    ],
    targets: [
        .target(
            name: "RadioPlayer",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "RadioPlayerTests",
            dependencies: ["RadioPlayer"],
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
