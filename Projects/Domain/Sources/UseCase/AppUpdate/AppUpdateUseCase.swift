//
//  AppUpdateUseCase.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class AppUpdateUseCase: AppUpdateUseCaseProtocol {

    // MARK: - Properties

    private let repository: AppUpdateRepositoryProtocol

    // MARK: - Init

    public init(repository: AppUpdateRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetchAppUpdateInfo() async throws -> AppUpdateInfo {
        return try await self.repository.fetchAppUpdateInfo()
    }
}
