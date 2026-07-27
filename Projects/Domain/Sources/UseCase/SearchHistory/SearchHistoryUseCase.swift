//
//  SearchHistoryUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class SearchHistoryUseCase: SearchHistoryUseCaseProtocol {

    // MARK: - Properties

    private let repository: SearchHistoryRepositoryProtocol
    private let maxHistoryCount = 20

    // MARK: - Init

    public init(repository: SearchHistoryRepositoryProtocol) {
        self.repository = repository
    }

    public func fetch() -> [SearchHistory] {
        return self.repository.fetch()
    }

    public func add(keyword: String) {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedKeyword.isEmpty == false else { return }

        var histories = self.repository.fetch()
        histories.removeAll { $0.keyword == trimmedKeyword }
        histories.insert(SearchHistory(keyword: trimmedKeyword, searchedAt: Date()), at: 0)
        if histories.count > self.maxHistoryCount {
            histories.removeLast(histories.count - self.maxHistoryCount)
        }
        self.repository.save(histories)
    }
}
