// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AutoIQ",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AutoIQ",
            targets: ["AutoIQ"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AutoIQ",
            dependencies: [],
            resources: [
                .process("Resources/Prompts/SystemPrompt.txt"),
                .process("Resources/Tools/tools.json")
            ]
        ),
        .testTarget(
            name: "AutoIQTests",
            dependencies: ["AutoIQ"]
        ),
    ]
)
