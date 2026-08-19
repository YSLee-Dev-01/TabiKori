//
//  BookmarkUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class BookmarkUseCase: BookmarkUseCaseProtocol {

    // MARK: - Properties

    private let repository: BookmarkRepositoryProtocol

    // MARK: - Init

    public init(repository: BookmarkRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetch() async throws -> [Bookmark] {
        return try await self.repository.fetch()
    }

    public func add(_ spot: TouristSpot) async throws {
        try await self.repository.add(spot)
    }

    public func remove(contentId: String) async throws {
        try await self.repository.remove(contentId: contentId)
    }

    public func isBookmarked(contentId: String) async throws -> Bool {
        return try await self.repository.isBookmarked(contentId: contentId)
    }
}
