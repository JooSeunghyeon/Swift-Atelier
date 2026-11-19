// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-task-local-context-propagation",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "TaskLocalContext",
            targets: ["TaskLocalContext"]
        ),
        .executable(
            name: "TaskLocalBenchmark",
            targets: ["TaskLocalBenchmark"]
        )
    ],
    targets: [
        .target(
            name: "TaskLocalContext",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "TaskLocalContextTests",
            dependencies: ["TaskLocalContext"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "TaskLocalBenchmark",
            dependencies: ["TaskLocalContext"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
