//
//  NoticePopupRepository.swift
//  Data
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

import FirebaseDatabase

public final class NoticePopupRepository: NoticePopupRepositoryProtocol {

    // MARK: - Properties

    private let userDefault: TabiUserDefaultProtocol

    // MARK: - Init

    public init(userDefault: TabiUserDefaultProtocol = TabiUserDefault.shared) {
        self.userDefault = userDefault
    }

    // MARK: - Method

    public func fetchAnnouncements() async throws -> [Announcement] {
        let databaseReference = Database.database().reference(withPath: "TabiKori/noticePopup")
        let snapshot = try await databaseReference.getData()

        do {
            return try snapshot.decodeOrderedList(order: { Int($0.startDate.timeIntervalSince1970) }) { id, dict in
                AnnouncementDTO(id: id, dict: dict)?.toEntity()
            }
        } catch {
            AppLogger.network.log(.error, "팝업 공지 목록 조회 실패: TabiKori/noticePopup 데이터 없음")
            throw error
        }
    }

    public func isDismissedToday(id: String) -> Bool {
        guard let records: [String: String] = self.userDefault.get(forKey: .noticePopupDismissedRecords),
              let dismissedDateString = records[id] else {
            return false
        }
        return dismissedDateString == Date().noticePopupDismissRecordDateString
    }

    public func markDismissedToday(id: String) {
        var records: [String: String] = self.userDefault.get(forKey: .noticePopupDismissedRecords) ?? [:]
        records[id] = Date().noticePopupDismissRecordDateString
        self.userDefault.set(records, forKey: .noticePopupDismissedRecords)
    }
}
