import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeProject(
    name: "App",
    product: .app,
    hasResource: true,
    infoPlist: .file(path: .relativeToRoot("Projects/App/Info.plist")),
    xcconfig: .relativeToRoot("Projects/Data/Sources/Secret.xcconfig")
)
