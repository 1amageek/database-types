// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "database-types",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "DatabaseTypes",
            targets: ["DatabaseTypes"]
        ),
        .library(
            name: "DatabaseTypesFoundation",
            targets: ["DatabaseTypesFoundation"]
        ),
    ],
    targets: [
        .target(
            name: "DatabaseTypes"
        ),
        .target(
            name: "DatabaseTypesFoundation",
            dependencies: ["DatabaseTypes"]
        ),
        .testTarget(
            name: "DatabaseTypesTests",
            dependencies: ["DatabaseTypes"]
        ),
        .testTarget(
            name: "DatabaseTypesFoundationTests",
            dependencies: [
                "DatabaseTypes",
                "DatabaseTypesFoundation",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
