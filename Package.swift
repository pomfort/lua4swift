// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "lua4swift",
  products: [
    .library(
      name: "lua4swift",
      targets: ["lua4swift"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
        name: "CLua",
        dependencies: [],
        path: "Sources/CLua"),
    .target(
      name: "lua4swift",
      dependencies: [
        "CLua",
      ],
      path: "Sources/lua4swift"),
    .testTarget(
      name: "lua4swiftTests",
      dependencies: [
        "lua4swift",
      ]),
  ]
)
