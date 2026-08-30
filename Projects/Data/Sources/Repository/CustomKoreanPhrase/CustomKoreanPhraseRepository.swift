//
//  CustomKoreanPhraseRepository.swift
//  Data
//
//  Created by Claude on 8/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

import Core
import Domain

public final class CustomKoreanPhraseRepository: Sendable {

    // MARK: - Properties

    private let modelContainer: ModelContainer

    // MARK: - Init

    public init(modelContainer: ModelContainer = KoreanPhraseModelContainer.shared.modelContainer) {
        self.modelContainer = modelContainer
    }
}

// MARK: - CustomKoreanPhraseRepositoryProtocol

extension CustomKoreanPhraseRepository: CustomKoreanPhraseRepositoryProtocol {
    public func fetchCustomPhrases() async throws -> [KoreanPhrase] {
        do {
            let context = ModelContext(self.modelContainer)
            let descriptor = FetchDescriptor<CustomKoreanPhraseModel>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor).enumerated().map { index, model in
                model.toDomain(order: index)
            }
        } catch {
            AppLogger.core.log(.error, "커스텀 한국어 문구 목록 조회 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func addCustomPhrase(_ phrase: KoreanPhrase, createdAt: Date) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            context.insert(CustomKoreanPhraseModel(phrase: phrase, createdAt: createdAt))
            try context.save()
        } catch {
            AppLogger.core.log(.error, "커스텀 한국어 문구 저장 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }

    public func deleteCustomPhrase(id: String) async throws {
        do {
            let context = ModelContext(self.modelContainer)
            var descriptor = FetchDescriptor<CustomKoreanPhraseModel>(
                predicate: #Predicate { $0.id == id }
            )
            descriptor.fetchLimit = 1
            guard let model = try context.fetch(descriptor).first else {
                AppLogger.core.log(.error, "커스텀 한국어 문구 삭제 실패: 대상 항목을 찾을 수 없음 (id: \(id))")
                return
            }
            context.delete(model)
            try context.save()
        } catch {
            AppLogger.core.log(.error, "커스텀 한국어 문구 삭제 실패: \(error.localizedDescription)")
            throw TabiError.persistenceFailed(message: error.localizedDescription)
        }
    }
}
