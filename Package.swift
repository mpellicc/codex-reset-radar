// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "CodexResetRadar",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0")
    ],
    targets: [
        .target(name: "RadarCore", path: "Sources/RadarCore"),
        .executableTarget(
            name: "CodexResetRadar",
            dependencies: ["RadarCore", .product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/CodexResetRadar",
            // Sparkle.framework is embedded in Contents/Frameworks by scripts/build-app.sh.
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        ),
        .testTarget(
            name: "RadarCoreTests",
            dependencies: ["RadarCore"],
            path: "Tests/RadarCoreTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
