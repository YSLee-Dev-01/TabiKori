//
//  Environment.swift
//  Config
//
//  Created by 이윤수 on 6/7/26.
//

import Foundation
import ProjectDescription

public struct Environment {
    public static let appName: String = "TabiKori"
    public static let organizationName = "yslee"
    public static let bundleIdentifier: String = "com.yslee.tabikori"
    public static let appGroupIdentifier: String = "group.com.yslee.tabikori"
    public static let destinations: Destinations = [.iPhone]
    public static let appVersion: String = "1.0.0"
    public static let buildNumber: String = "1.0.10"
    public static let deploymentTargetVersion: String = "26.0"
    public static let deploymentTarget: DeploymentTargets = .iOS(Environment.deploymentTargetVersion)
    public static let appGroupEntitlements: Entitlements = .dictionary([
        "com.apple.security.application-groups": .array([.string(Environment.appGroupIdentifier)])
    ])
}
