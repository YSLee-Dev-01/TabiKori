import ProjectDescription

let project = Project(
    name: "TabiKori",
    targets: [
        .target(
            name: "TabiKori",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.TabiKori",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "TabiKori/Sources",
                "TabiKori/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "TabiKoriTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.TabiKoriTests",
            infoPlist: .default,
            buildableFolders: [
                "TabiKori/Tests"
            ],
            dependencies: [.target(name: "TabiKori")]
        ),
    ]
)
