//
//  SearchHistoryRepositoryProtocol.swift
//  Domain
//
//  Created by 이윤수 on 7/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol SearchHistoryRepositoryProtocol: Sendable {
    func fetch() -> [SearchHistory]
    func save(_ histories: [SearchHistory])
}
