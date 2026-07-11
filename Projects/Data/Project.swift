import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeProject(
    name: "Data",
    product: .staticFramework,
    hasResource: false,
    infoPlist: .file(path: .relativeToRoot("Projects/Data/Info.plist")),
    xcconfig: .relativeToRoot("Projects/Data/Sources/Secret.xcconfig")
)
