//
//  Settings.swift
//  Config
//
//  Created by 이윤수 on 6/7/26.
//

import Foundation
import ProjectDescription

extension Settings {
    static func defaultTargetSettings(xcconfig: Path? = nil) -> Settings {
        return Settings.settings(
            base: [
                "SWIFT_VERSION": "6.0",
                "IPHONEOS_DEPLOYMENT_TARGET": "\(Environment.deploymentTargetVersion)",
                "OTHER_LDFLAGS": "-ObjC",
            ],
            configurations: [
                .debug(
                    name: .debug,
                    settings: [
                        "OTHER_SWIFT_FLAGS": "-DDEBUG",
                    ],
                    xcconfig: xcconfig
                ),
                .release(
                    name: .release,
                    settings: [
                        "OTHER_SWIFT_FLAGS": ["-DRELEASE"],
                    ],
                    xcconfig: xcconfig
                )
            ],
            defaultSettings: DefaultSettings.recommended
        )
    }
}
