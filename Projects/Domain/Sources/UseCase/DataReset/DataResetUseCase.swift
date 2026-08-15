//
//  DataResetUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class DataResetUseCase: DataResetUseCaseProtocol {

    // MARK: - Properties

    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let travelPlanRepository: TravelPlanRepositoryProtocol
    private let searchHistoryRepository: SearchHistoryRepositoryProtocol

    // MARK: - Init

    public init(
        bookmarkRepository: BookmarkRepositoryProtocol,
        travelPlanRepository: TravelPlanRepositoryProtocol,
        searchHistoryRepository: SearchHistoryRepositoryProtocol
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.travelPlanRepository = travelPlanRepository
        self.searchHistoryRepository = searchHistoryRepository
    }

    // MARK: - Method

    public func resetAll() async throws {
        var failedTargets: [String] = []

        do {
            try await self.bookmarkRepository.removeAll()
        } catch {
            failedTargets.append("bookmark")
        }

        do {
            try await self.travelPlanRepository.removeAll()
        } catch {
            failedTargets.append("travelPlan")
        }

        // save(_:)는 non-throwing이라 인코딩 실패(사실상 발생하지 않음)를 failedTargets로 추적할 수 없다
        self.searchHistoryRepository.save([])

        guard failedTargets.isEmpty == false else { return }
        throw TabiError.persistenceFailed(message: "데이터 초기화 실패: \(failedTargets.joined(separator: ", "))")
    }
}
