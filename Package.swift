// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownStudio",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MarkdownStudio", targets: ["MarkdownStudio"])
    ],
    targets: [
        .executableTarget(
            name: "MarkdownStudio",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("WebKit")
            ]
        ),
        .testTarget(
            name: "MarkdownStudioTests",
            dependencies: ["MarkdownStudio"]
        )
    ]
)
