// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "api",
  products: [
    .executable(name: "API", targets: ["API"])
  ],
  dependencies: [
    .package(name: "CDK", path: "../../")
  ],
  targets: [
    .executableTarget(name: "API", dependencies: ["CDK"])
  ]
)
