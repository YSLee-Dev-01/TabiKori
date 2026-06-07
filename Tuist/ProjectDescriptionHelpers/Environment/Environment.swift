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
    public static let destinations: Destinations = [.iPhone]
    public static let deploymentTargetVersion: String = "26.0"
    public static let deploymentTarget: DeploymentTargets = .iOS(Environment.deploymentTargetVersion)
}
