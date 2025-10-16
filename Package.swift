// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "websites",
    platforms: [
        .macOS("15"),
    ],
    dependencies: [
        // Local Dev
        // .package(path: "../slipstream"),
        .package(url: "https://github.com/21-DOT-DEV/slipstream", branch: "NEW-INPUT-TYPES"),
        .package(url: "https://github.com/21-DOT-DEV/swift-plugin-tailwindcss", exact: "3.4.17"),
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", exact: "0.21.1"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", exact: "1.4.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "21-dev",
            dependencies: [
                .product(name: "Slipstream", package: "slipstream"),
                .target(name: "DesignSystem")
            ]
        ),
        .executableTarget(
            name: "docs-21-dev",
            dependencies: [
                .product(name: "P256K", package: "swift-secp256k1"),
                .product(name: "ZKP", package: "swift-secp256k1"),
                .product(name: "libsecp256k1", package: "swift-secp256k1"),
                .product(name: "libsecp256k1_zkp", package: "swift-secp256k1"),
            ]
        ),
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "Slipstream", package: "slipstream"),
            ]
        ),
        .target(
            name: "TestUtils",
            dependencies: [
                .product(name: "Slipstream", package: "slipstream"),
                "DesignSystem"
            ],
            path: "Tests/TestUtils"
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem", "TestUtils"]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["DesignSystem", "21-dev", "TestUtils"]
        )
    ]
)
