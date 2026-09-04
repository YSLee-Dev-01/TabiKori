//
//  NoticePopupUseCase.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class NoticePopupUseCase: NoticePopupUseCaseProtocol {

    // MARK: - Properties

    private let repository: NoticePopupRepositoryProtocol

    // MARK: - Init

    public init(repository: NoticePopupRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetchActiveAnnouncement() async throws -> Announcement? {
        let announcements = try await self.repository.fetchAnnouncements()
        return Announcement.firstActive(in: announcements)
    }

    public func isDismissedToday(id: String) -> Bool {
        return self.repository.isDismissedToday(id: id)
    }

    public func markDismissedToday(id: String) {
        self.repository.markDismissedToday(id: id)
    }
}
