//
//  Project.swift
//  Config
//
//  Created by 이윤수 on 6/7/26.
//

import Foundation
import ProjectDescription

public extension Project {
    static func makeProject(
        name: String,
        product: Product,
        hasResource: Bool
    ) -> Project {
        let debugScheme = Scheme.makeScheme(
            schemeName: "\(name)Debug",
            targetName: name,
            configurationName: .debug,
            isRunnable: product == .app
        )

        let releaseScheme = Scheme.makeScheme(
            schemeName: "\(name)Release",
            targetName: name,
            configurationName: .release,
            isRunnable: product == .app
        )
        
        return Project(
            name: name,
            organizationName: Environment.organizationName,
            options: options(disableBundleAccessors: hasResource),
            settings: Settings.defaultTargetSettings(),
            targets: [
                Target.makeTarget(
                    name: name,
                    hasResource: hasResource,
                    product: product,
                    dependencies: DependencyInformation.dependencies(name: name)
                )
            ],
            schemes: [
                debugScheme,
                releaseScheme
            ]
        )
    }
    
    private static func options(disableBundleAccessors: Bool) -> Options {
        return Options.options(
            automaticSchemesOptions: .disabled,
            defaultKnownRegions: ["en", "ko"],
            developmentRegion: "ko",
            disableBundleAccessors: !disableBundleAccessors
        )
    }
}
