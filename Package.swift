// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ThockPlus",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ThockPlus", targets: ["ThockPlus"])
    ],
    targets: [
        .executableTarget(
            name: "ThockPlus",
            path: "Sources/ThockPlus",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
