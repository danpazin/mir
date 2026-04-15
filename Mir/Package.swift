// swift-tools-version: 6.3

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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Mir",
            dependencies: ["MirSharedTypes"],
            resources: [.process("Shaders")]
        ),
        .target(name: "MirSharedTypes"),
        .testTarget(
            name: "MirTests",
            dependencies: ["Mir"]
        ),
    ]
)
