//
//  SettingInfoRepository.swift
//  Data
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

import FirebaseDatabase

public final class SettingInfoRepository: SettingInfoRepositoryProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchDataSourceContent() async throws -> String {
        return try await self.fetchContent(childKey: "dataSource")
    }

    public func fetchEtcInfoContent() async throws -> String {
        return try await self.fetchContent(childKey: "etcInfo")
    }
}

// MARK: - Method

private extension SettingInfoRepository {
    func fetchContent(childKey: String) async throws -> String {
        let databaseReference = Database.database().reference(withPath: "TabiKori/settingInfo/\(childKey)")
        let snapshot = try await databaseReference.getData()

        guard let content = snapshot.value as? String, content.isEmpty == false else {
            AppLogger.network.log(.error, "설정 안내 문구 조회 실패: TabiKori/settingInfo/\(childKey) 데이터 없음")
            throw TabiError.dataNotFound
        }

        return content.replacingOccurrences(of: "\\n", with: "\n")
    }
}
