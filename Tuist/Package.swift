// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Default is .staticFramework
        productTypes: ["ComposableArchitecture": .framework]
    )
#endif

let package = Package(
    name: "TabiKori",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5"),
        .package(url: "https://github.com/airbnb/lottie-ios", from: "4.6.1"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "8.10.0")
    ]
)
