// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cdk-swift",
    products: [
        .library(name: "CDK", targets: ["CDK"]),
    ],
    targets: [
        .target(name: "IC", dependencies: []),
        .target(name: "CDK", dependencies: ["IC"]),
    ]
)
