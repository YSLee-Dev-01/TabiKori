//
//  BookmarkRepository.swift
//  Data
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

import Core
import Domain

public final class BookmarkRepository: Sendable {

    // MARK: - Properties

    private let modelContainer: ModelContainer

    // MARK: - Init

    public init(modelContainer: ModelContainer = BookmarkModelContainer.shared.modelContainer) {
        self.modelContainer = modelContainer
    }
}

// MARK: - BookmarkRepositoryProtocol

extension BookmarkRepository: BookmarkRepositoryProtocol {
    public func fetch() async throws -> [Bookmark] {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<BookmarkModel>(
                sortBy: [SortDescriptor(\.savedAt, order: .reverse)]
            )
            return try context.fetch(descriptor).compactMap(\.toDomain)
        } catch {
            AppLogger.core.log(.error, "북마크 조회 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func add(_ spot: TouristSpot) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            let model = BookmarkModel(spot: spot, savedAt: Date())
            context.insert(model)
            try context.save()
        } catch {
            AppLogger.core.log(.error, "북마크 저장 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func remove(contentId: String) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            guard let model = try self.fetchModel(contentId: contentId, in: context) else { return }
            context.delete(model)
            try context.save()
        } catch {
            AppLogger.core.log(.error, "북마크 삭제 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func isBookmarked(contentId: String) async throws -> Bool {
        do {
            let context = ModelContext(self.modelContainer)
            return try self.fetchModel(contentId: contentId, in: context) != nil
        } catch {
            AppLogger.core.log(.error, "북마크 여부 조회 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func removeAll() async throws {
        do {
            let context = ModelContext(self.modelContainer)
            try context.delete(model: BookmarkModel.self)
            try context.save()
        } catch {
            AppLogger.core.log(.error, "북마크 전체 삭제 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }
}

// MARK: - Method

private extension BookmarkRepository {
    func fetchModel(contentId: String, in context: ModelContext) throws -> BookmarkModel? {
        let descriptor = FetchDescriptor<BookmarkModel>(
            predicate: #Predicate { $0.contentId == contentId }
        )
        return try context.fetch(descriptor).first
    }
}
