// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "ElyraCore", platforms: [.iOS(.v17), .macOS(.v14)], products: [
    .library(name: "ElyraCore", targets: ["ElyraCore"])
], targets: [
    .target(name: "ElyraCore", path: "Elyra/Core"),
    .testTarget(name: "ElyraCoreTests", dependencies: ["ElyraCore"], path: "Tests/ElyraCoreTests")
])
