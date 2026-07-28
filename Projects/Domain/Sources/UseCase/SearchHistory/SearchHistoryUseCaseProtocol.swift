//
//  SearchHistoryUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 7/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol SearchHistoryUseCaseProtocol: Sendable {
    func fetch() -> [SearchHistory]
    func add(keyword: String)
    func remove(keyword: String)
}
