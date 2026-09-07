//
//  TestSettingInfoUseCase.swift
//  Domain
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestSettingInfoUseCase: SettingInfoUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var dataSourceContent: String = ""
    public var etcInfoContent: String = ""

    // MARK: - Method

    public func fetchDataSourceContent() async throws -> String {
        return self.dataSourceContent
    }

    public func fetchEtcInfoContent() async throws -> String {
        return self.etcInfoContent
    }
}
