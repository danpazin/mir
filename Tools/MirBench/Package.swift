// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MirBench",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "mir-bench", targets: ["mir-bench"])
    ],
    targets: [
        .target(name: "MirBenchKit"),
        .executableTarget(
            name: "mir-bench",
            dependencies: ["MirBenchKit"]
        ),
        .testTarget(
            name: "MirBenchKitTests",
            dependencies: ["MirBenchKit"]
        )
    ]
)
