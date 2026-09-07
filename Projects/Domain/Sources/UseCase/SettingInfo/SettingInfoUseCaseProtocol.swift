//
//  SettingInfoUseCaseProtocol.swift
//  Domain
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol SettingInfoUseCaseProtocol: Sendable {
    func fetchDataSourceContent() async throws -> String
    func fetchEtcInfoContent() async throws -> String
}
