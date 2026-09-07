//
//  TestNoticePopupUseCase.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestNoticePopupUseCase: NoticePopupUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var activeAnnouncement: Announcement?
    public var dismissedTodayIds: Set<String> = []

    // MARK: - Method

    public func fetchActiveAnnouncement() async throws -> Announcement? {
        return self.activeAnnouncement
    }

    public func isDismissedToday(id: String) -> Bool {
        return self.dismissedTodayIds.contains(id)
    }

    public func markDismissedToday(id: String) {
        self.dismissedTodayIds.insert(id)
    }
}
