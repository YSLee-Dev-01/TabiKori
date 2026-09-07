//
//  HomeSheetAnnounceRepository.swift
//  Data
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

import FirebaseDatabase

public final class HomeSheetAnnounceRepository: HomeSheetAnnounceRepositoryProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchAnnouncements() async throws -> [Announcement] {
        let databaseReference = Database.database().reference(withPath: "TabiKori/homeSheetAnnounce")
        let snapshot = try await databaseReference.getData()

        do {
            return try snapshot.decodeOrderedList(order: { Int($0.startDate.timeIntervalSince1970) }) { id, dict in
                AnnouncementDTO(id: id, dict: dict)?.toEntity()
            }
        } catch {
            AppLogger.network.log(.error, "홈 시트 공지 목록 조회 실패: TabiKori/homeSheetAnnounce 데이터 없음")
            throw error
        }
    }
}
