// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MarkitdownKitMac",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "MarkitdownKitMac", targets: ["MarkitdownKitMac"]),
    ],
    targets: [
        .executableTarget(
            name: "MarkitdownKitMac",
            path: "Sources/MarkitdownKitMac"
        ),
    ]
)
