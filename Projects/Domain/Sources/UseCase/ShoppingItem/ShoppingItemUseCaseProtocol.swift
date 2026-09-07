//
//  ShoppingItemUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol ShoppingItemUseCaseProtocol: Sendable {
    func fetchRecommendedItems() async throws -> [ShoppingItem]
}
