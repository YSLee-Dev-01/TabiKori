//
//  TestBookmarkUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestBookmarkUseCase: BookmarkUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var bookmarks: [Bookmark] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetch() async throws -> [Bookmark] {
        return self.bookmarks
    }

    public func add(_ spot: TouristSpot) async throws {
        guard self.bookmarks.contains(where: { $0.id == spot.id }) == false else { return }
        self.bookmarks.append(Bookmark(touristSpot: spot, savedAt: Date()))
    }

    public func remove(contentId: String) async throws {
        self.bookmarks.removeAll { $0.id == contentId }
    }

    public func isBookmarked(contentId: String) async throws -> Bool {
        return self.bookmarks.contains { $0.id == contentId }
    }
}
