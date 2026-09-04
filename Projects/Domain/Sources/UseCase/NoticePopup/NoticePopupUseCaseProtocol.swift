//
//  NoticePopupUseCaseProtocol.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol NoticePopupUseCaseProtocol: Sendable {
    /// 활성 기간(startDate~endDate)에 해당하는 공지 중 startDate 오름차순 첫 번째 항목
    func fetchActiveAnnouncement() async throws -> Announcement?
    func isDismissedToday(id: String) -> Bool
    func markDismissedToday(id: String)
}
