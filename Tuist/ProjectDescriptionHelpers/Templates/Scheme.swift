//
//  Scheme.swift
//  Config
//
//  Created by 이윤수 on 6/7/26.
//

import Foundation
import ProjectDescription

public extension Scheme {
    static func makeScheme(
        schemeName: String,
        targetName: String,
        configurationName: ConfigurationName,
        isRunnable: Bool = false
    ) -> Scheme {
        let isRelease = configurationName == .release
        return Scheme.scheme(
            name: schemeName,
            shared: true,
            buildAction: .buildAction(targets: ["\(targetName)"]),
            runAction: isRunnable ? .runAction(configuration: configurationName) : nil,
            archiveAction: .archiveAction(configuration: isRelease ? .release : configurationName),
            analyzeAction: .analyzeAction(configuration: configurationName)
        )
    }
}
