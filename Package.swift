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
        .package(url: "https://github.com/21-DOT-DEV/slipstream", branch: "develop"),
        .package(url: "https://github.com/21-DOT-DEV/swift-plugin-tailwindcss", exact: "3.4.17"),
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", exact: "0.21.1"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", exact: "1.4.5"),
        .package(url: "https://github.com/P24L/DocC4LLM.git", exact: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", exact: "0.2.1"),
        .package(url: "https://github.com/csjones/lefthook-plugin", exact: "2.0.4"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.8.8"),
    ],
    targets: makeDocumentationTargets() + [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "21-dev",
            dependencies: [
                .product(name: "Slipstream", package: "slipstream"),
                .target(name: "DesignSystem"),
                .target(name: "UtilLib")
            ]
        ),
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "Slipstream", package: "slipstream"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .target(name: "UtilLib")
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
            dependencies: ["DesignSystem", "TestUtils", "UtilLib"]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "DesignSystem",
                "21-dev",
                "TestUtils",
                "UtilLib"
            ]
        ),
        // MARK: - Utilities Library & CLI
        .target(
            name: "UtilLib",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "SwiftSoup", package: "SwiftSoup")
            ]
        ),
        .executableTarget(
            name: "util",
            dependencies: [
                .target(name: "UtilLib"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "UtilLibTests",
            dependencies: ["UtilLib"]
        ),
        .testTarget(
            name: "UtilIntegrationTests",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess")
            ]
        )
    ]
)

// MARK: - Documentation Targets

/// Creates documentation targets for external packages.
/// These targets exist solely to allow swift-docc-plugin to generate combined documentation.
func makeDocumentationTargets() -> [Target] {
    return [
       .executableTarget(
           name: "docs-21-dev-P256K",
           dependencies: [ .product(name: "P256K", package: "swift-secp256k1"), ]
       ),
       .executableTarget(
           name: "docs-21-dev-ZKP",
           dependencies: [ .product(name: "ZKP", package: "swift-secp256k1"), ]
       ),
    ]
}
