// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FileTunnelUI",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "FileTunnelUI", type: .dynamic, targets: ["FileTunnelUI"]),
    ],
    targets: [
        .target(name: "FileTunnelUI"),
        .testTarget(name: "FileTunnelUITests", dependencies: ["FileTunnelUI"]),
    ]
)
