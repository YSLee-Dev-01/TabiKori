//
//  DependencyInformation.swift
//  Config
//
//  Created by 이윤수 on 6/7/26.
//

import Foundation
import ProjectDescription

public enum DependencyInformation: String, CaseIterable, Sendable {
    // 내부
    case app = "App"
    case dicontainer = "DIContainer"
    case domain = "Domain"
    case data = "Data"
    case core = "Core"
    case designSystem = "DesignSystem"
    case presentation = "Presentation"
    case resource = "Resource"
    
    // 외부 (라이브러리)
    case tca = "ComposableArchitecture"
    
    static let internalDependencyInfo: [DependencyInformation: [DependencyInformation]] = [
        .app: [.dicontainer],
        .dicontainer: [.domain, .data, .core, .presentation],
        .domain: [.core],
        .data: [.domain, .core],
        .core: [],
        .designSystem: [.core, .resource],
        .presentation: [.designSystem, .core, .domain],
        .resource: []
    ]
    
    static let externalDependencyInfo: [DependencyInformation: [DependencyInformation]] = [
        .presentation: [.tca]
    ]
}

public extension DependencyInformation {
    static func dependencies(name: String) -> [TargetDependency] {
        guard let module = DependencyInformation(rawValue: name) else { return [] }

        let internalModules = DependencyInformation.internalDependencyInfo[module] ?? []
        let internalDependencies: [TargetDependency] = internalModules.map {
            .project(target: $0.rawValue, path: .relativeToRoot("Projects/\($0.rawValue)"))
        }

        let externalModules = DependencyInformation.externalDependencyInfo[module] ?? []
        let externalDependencies: [TargetDependency] = externalModules.map {
            .external(name: $0.rawValue)
        }

        return internalDependencies + externalDependencies
    }
}
