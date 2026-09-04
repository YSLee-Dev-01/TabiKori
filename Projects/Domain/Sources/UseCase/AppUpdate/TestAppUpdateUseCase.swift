//
//  TestAppUpdateUseCase.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestAppUpdateUseCase: AppUpdateUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var appUpdateInfo: AppUpdateInfo = AppUpdateInfo(minimumVersion: "0.0.0")

    // MARK: - Method

    public func fetchAppUpdateInfo() async throws -> AppUpdateInfo {
        return self.appUpdateInfo
    }
}
