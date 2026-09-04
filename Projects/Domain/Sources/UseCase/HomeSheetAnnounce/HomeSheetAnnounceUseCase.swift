//
//  HomeSheetAnnounceUseCase.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class HomeSheetAnnounceUseCase: HomeSheetAnnounceUseCaseProtocol {

    // MARK: - Properties

    private let repository: HomeSheetAnnounceRepositoryProtocol

    // MARK: - Init

    public init(repository: HomeSheetAnnounceRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetchActiveAnnouncement() async throws -> Announcement? {
        let announcements = try await self.repository.fetchAnnouncements()
        return Announcement.firstActive(in: announcements)
    }
}
