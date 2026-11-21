// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenArcMouse",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OpenArcMouse", targets: ["OpenArcMouseApp"]),
        .executable(name: "arc-inspect", targets: ["ArcInspect"]),
        .executable(name: "arc-monitor", targets: ["ArcMonitor"]),
        .library(name: "ArcCore", targets: ["ArcCore"]),
        .library(name: "ArcHID", targets: ["ArcHID"]),
        .library(name: "ArcEngine", targets: ["ArcEngine"])
    ],
    targets: [
        .target(
            name: "ArcCore",
            dependencies: [],
            path: "Sources/ArcCore"
        ),
        .target(
            name: "ArcHID",
            dependencies: ["ArcCore"],
            path: "Sources/ArcHID"
        ),
        .target(
            name: "ArcEngine",
            dependencies: ["ArcCore", "ArcHID"],
            path: "Sources/ArcEngine"
        ),
        .executableTarget(
            name: "OpenArcMouseApp",
            dependencies: ["ArcCore", "ArcHID", "ArcEngine"],
            path: "Sources/OpenArcMouseApp"
        ),
        .executableTarget(
            name: "ArcInspect",
            dependencies: ["ArcCore"],
            path: "Tools/ArcInspect"
        ),
        .executableTarget(
            name: "ArcMonitor",
            dependencies: ["ArcCore"],
            path: "Tools/ArcMonitor"
        )
    ]
)
