//
//  TestShoppingItemUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestShoppingItemUseCase: ShoppingItemUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var recommendedItems: [ShoppingItem] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func fetchRecommendedItems() async throws -> [ShoppingItem] {
        return self.recommendedItems
    }
}
