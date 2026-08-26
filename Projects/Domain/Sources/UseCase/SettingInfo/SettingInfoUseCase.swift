//
//  SettingInfoUseCase.swift
//  Domain
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class SettingInfoUseCase: SettingInfoUseCaseProtocol {

    // MARK: - Properties

    private let repository: SettingInfoRepositoryProtocol

    // MARK: - Init

    public init(repository: SettingInfoRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetchDataSourceContent() async throws -> String {
        return try await self.repository.fetchDataSourceContent()
    }

    public func fetchEtcInfoContent() async throws -> String {
        return try await self.repository.fetchEtcInfoContent()
    }
}
