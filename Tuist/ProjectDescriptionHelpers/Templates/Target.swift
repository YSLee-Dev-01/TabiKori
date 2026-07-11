//
//  Target.swift
//  Config
//
//  Created by 이윤수 on 6/7/26.
//

import Foundation
import ProjectDescription

public extension Target {
    static func makeTarget(
        name: String,
        hasResource: Bool,
        product: Product,
        dependencies: [TargetDependency],
        infoPlist: InfoPlist = .file(path: .relativeToRoot("Tuist/Config/Info.plist")),
        xcconfig: Path? = nil
    ) -> Target {
        return Target.target(
            name: name,
            destinations: Environment.destinations,
            product: product,
            bundleId: "\(Environment.organizationName).\(Environment.appName).\(name)",
            deploymentTargets: Environment.deploymentTarget,
            infoPlist: infoPlist,
            sources: ["Sources/**"],
            resources: hasResource ? ["Resources/**"] : nil,
            dependencies: dependencies,
            settings: Settings.defaultTargetSettings(xcconfig: xcconfig)
            )
    }
}
