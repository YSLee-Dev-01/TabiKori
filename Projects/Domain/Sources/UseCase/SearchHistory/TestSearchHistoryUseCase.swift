//
//  TestSearchHistoryUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestSearchHistoryUseCase: SearchHistoryUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var histories: [SearchHistory] = []
    public var addedKeyword: String?
    public var removedKeyword: String?

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetch() -> [SearchHistory] {
        return self.histories
    }

    public func add(keyword: String) {
        self.addedKeyword = keyword
    }

    public func remove(keyword: String) {
        self.removedKeyword = keyword
        self.histories.removeAll { $0.keyword == keyword }
    }
}
