//
//  AppUpdateRepository.swift
//  Data
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

import FirebaseDatabase

public final class AppUpdateRepository: AppUpdateRepositoryProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchAppUpdateInfo() async throws -> AppUpdateInfo {
        let databaseReference = Database.database().reference(withPath: "TabiKori/appUpdate/minimumVersion")
        let snapshot = try await databaseReference.getData()

        guard let minimumVersion = snapshot.value as? String, minimumVersion.isEmpty == false else {
            AppLogger.network.log(.error, "강제 업데이트 정보 조회 실패: TabiKori/appUpdate/minimumVersion 데이터 없음")
            throw TabiError.dataNotFound
        }

        return AppUpdateDTO(minimumVersion: minimumVersion).toEntity()
    }
}
