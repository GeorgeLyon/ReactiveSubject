// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "ReactiveSubject",
  platforms: [
    .iOS(.v14),
    .macOS(.v11),
  ],
  products: [
    .library(
      name: "ReactiveSubject",
      targets: ["ReactiveSubject"]),
  ],
  targets: [
    .target(
      name: "ReactiveSubject",
      dependencies: []),
    .testTarget(
      name: "ReactiveSubjectTests",
      dependencies: ["ReactiveSubject"]),
  ]
)
