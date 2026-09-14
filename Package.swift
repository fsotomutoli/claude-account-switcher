// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClaudeAccountSwitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClaudeAccountSwitcher",
            path: "Sources/ClaudeAccountSwitcher"
        )
    ]
)
