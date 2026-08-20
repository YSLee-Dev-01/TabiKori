//
//  BookmarkUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol BookmarkUseCaseProtocol: Sendable {
    func fetch() async throws -> [Bookmark]
    func add(_ spot: TouristSpot) async throws
    func update(_ spot: TouristSpot) async throws
    func remove(contentId: String) async throws
    func isBookmarked(contentId: String) async throws -> Bool
}
