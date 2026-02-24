// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Mir",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26),
        .tvOS(.v26)
    ],
    products: [
        .library(
            name: "Mir",
            targets: ["Mir"]
        ),
    ],
    targets: [
        .target(
            name: "Mir"
        ),
        .testTarget(
            name: "MirTests",
            dependencies: ["Mir"]
        ),
    ]
)
