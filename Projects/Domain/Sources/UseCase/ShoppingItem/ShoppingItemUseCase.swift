//
//  ShoppingItemUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class ShoppingItemUseCase: ShoppingItemUseCaseProtocol {

    // MARK: - Properties

    private let repository: ShoppingItemRepositoryProtocol

    // MARK: - Init

    public init(repository: ShoppingItemRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Method

    public func fetchRecommendedItems() async throws -> [ShoppingItem] {
        return try await self.repository.fetchRecommendedItems()
    }
}
