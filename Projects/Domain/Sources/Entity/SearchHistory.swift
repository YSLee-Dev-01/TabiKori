//
//  SearchHistory.swift
//  Domain
//
//  Created by 이윤수 on 7/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct SearchHistory: Codable, Equatable, Sendable {
    public let keyword: String
    public let searchedAt: Date

    public init(keyword: String, searchedAt: Date) {
        self.keyword = keyword
        self.searchedAt = searchedAt
    }
}
