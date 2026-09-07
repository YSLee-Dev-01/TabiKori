//
//  AppUpdateUseCaseProtocol.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol AppUpdateUseCaseProtocol: Sendable {
    func fetchAppUpdateInfo() async throws -> AppUpdateInfo
}
