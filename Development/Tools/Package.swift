// swift-tools-version: 6.2

// The swift-tools-version declares the minimum version of Swift required to build this package.

//
//  Package.swift
//  21-DOT-DEV/websites
//
//  Copyright (c) 2026-present Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information

import PackageDescription

let package = Package(
    name: "DevelopmentTools",
    products: [
        .executable(name: "plans", targets: ["plans"]),
    ],
    dependencies: [
        .package(url: "https://github.com/21-DOT-DEV/swift-yaml", revision: "473252b018cbf2e5f8d0b51f19af0a23c21592a0"),
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.6.2"),
    ],
    targets: [
        .target(
            name: "PlanIndex",
            dependencies: [
                .product(name: "YAML", package: "swift-yaml"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(
            name: "plans",
            dependencies: ["PlanIndex"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "PlanIndexTests",
            dependencies: ["PlanIndex"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
    ]
)
