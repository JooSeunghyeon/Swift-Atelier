// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swift-array-slice-index-rebase-retention",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "ArraySliceLib",
            targets: ["ArraySliceLib"]
        ),
        .executable(
            name: "ArraySliceDemo",
            targets: ["ArraySliceDemo"]
        )
    ],
    targets: [
        .target(
            name: "ArraySliceLib",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "ArraySliceLibTests",
            dependencies: ["ArraySliceLib"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "ArraySliceDemo",
            dependencies: ["ArraySliceLib"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
