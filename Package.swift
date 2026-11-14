// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "ElyraCore", platforms: [.iOS(.v17), .macOS(.v14)], products: [
    .library(name: "ElyraCore", targets: ["ElyraCore"])
], dependencies: [
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", revision: "22787ffb59de99e5dc1fbfe80b19c97a904ad48d")
], targets: [
    .target(name: "ElyraCore", dependencies: [.product(name: "ZIPFoundation", package: "ZIPFoundation")], path: "Elyra/Core"),
    .testTarget(name: "ElyraCoreTests", dependencies: ["ElyraCore"], path: "Tests/ElyraCoreTests")
])
