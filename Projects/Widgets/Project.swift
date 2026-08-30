import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeProject(
    name: "Widgets",
    product: .appExtension,
    hasResource: false,
    infoPlist: .file(path: .relativeToRoot("Projects/Widgets/Info.plist")),
    entitlements: Environment.appGroupEntitlements
)
