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
    // Tuist 매니페스트(빌드 타임)와 앱 런타임(Core.AppGroup.identifier)은 컴파일 컨텍스트가 달라 상수를 공유할 수 없다.
    // 이 값을 변경하면 Projects/Core/Sources/Config/AppGroup.swift도 함께 변경해야 한다
    public static let appGroupIdentifier: String = "group.com.yslee.tabikori"
    public static let destinations: Destinations = [.iPhone]
    public static let deploymentTargetVersion: String = "26.0"
    public static let deploymentTarget: DeploymentTargets = .iOS(Environment.deploymentTargetVersion)
    public static let appGroupEntitlements: Entitlements = .dictionary([
        "com.apple.security.application-groups": .array([.string(Environment.appGroupIdentifier)])
    ])
}
