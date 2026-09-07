// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Default is .staticFramework
        // App/Core, DesignSystem/Presentation 등 서로 다른 경로에서 동시에 링크되는
        // static product는 최종 빌드 시 리소스 복사 태스크가 중복 스케줄링되어
        // "Unexpected duplicate tasks" 에러를 유발하므로 dynamic framework로 전환
        productTypes: [
            "ComposableArchitecture": .framework,
            "Kingfisher": .framework,
            "Firebase": .framework,
            "FirebaseCore": .framework,
            "FirebaseCoreInternal": .framework,
            "FirebaseInstallations": .framework,
            "FBLPromises": .framework,
            "GoogleUtilities-Environment": .framework,
            "GoogleUtilities-Logger": .framework,
            "GoogleUtilities-NSData": .framework,
            "GoogleUtilities-UserDefaults": .framework,
            "nanopb": .framework,
            "third-party-IsAppEncrypted": .framework
        ]
    )
#endif

let package = Package(
    name: "TabiKori",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.25.5"),
        .package(url: "https://github.com/airbnb/lottie-ios", from: "4.6.1"),
        .package(url: "https://github.com/onevcat/Kingfisher", from: "8.10.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.16.0"),
        .package(url: "https://github.com/navermaps/SPM-NMapsMap", from: "3.23.3"),
    ]
)
