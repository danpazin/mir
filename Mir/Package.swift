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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Mir",
            dependencies: ["MirTypes"],
            resources: [.process("Shaders")]
        ),
        .target(name: "MirTypes"),
        .testTarget(
            name: "MirTests",
            dependencies: ["Mir"]
        ),
    ]
)
