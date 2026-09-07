import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeProject(
    name: "App",
    product: .app,
    hasResource: true,
    infoPlist: .file(path: .relativeToRoot("Projects/App/Info.plist")),
    xcconfig: .relativeToRoot("Projects/Data/Sources/Secret.xcconfig"),
    entitlements: Environment.appGroupEntitlements,
    scripts: [
        .post(
            script: "\"${SRCROOT}/../../Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run\"",
            name: "Firebase Crashlytics",
            inputPaths: [
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
                "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
                "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)"
            ]
        )
    ]
)
