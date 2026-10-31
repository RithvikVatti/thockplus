// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Snick",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Snick", targets: ["Snick"])
    ],
    targets: [
        .executableTarget(
            name: "Snick",
            path: "Sources/Snick",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
