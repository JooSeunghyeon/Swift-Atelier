// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-enum-raw-value-persistence",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "RawValuePersistence",
            targets: ["RawValuePersistence"]
        ),
        .executable(
            name: "RawValueDemo",
            targets: ["RawValueDemo"]
        )
    ],
    targets: [
        .target(
            name: "RawValuePersistence",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "RawValuePersistenceTests",
            dependencies: ["RawValuePersistence"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "RawValueDemo",
            dependencies: ["RawValuePersistence"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
