//
//  SearchHistoryRepository.swift
//  Data
//
//  Created by 이윤수 on 7/27/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

public final class SearchHistoryRepository: SearchHistoryRepositoryProtocol {

    // MARK: - Properties

    private let userDefault: TabiUserDefaultProtocol

    // MARK: - Init

    public init(userDefault: TabiUserDefaultProtocol = TabiUserDefault.shared) {
        self.userDefault = userDefault
    }

    public func fetch() -> [SearchHistory] {
        guard let data: Data = self.userDefault.get(forKey: .recentSearchHistory) else { return [] }
        do {
            return try JSONDecoder().decode([SearchHistory].self, from: data)
        } catch {
            AppLogger.core.log(.error, "최근 검색어 디코딩 실패: \(error.localizedDescription)")
            return []
        }
    }

    public func save(_ histories: [SearchHistory]) {
        do {
            let data = try JSONEncoder().encode(histories)
            self.userDefault.set(data, forKey: .recentSearchHistory)
        } catch {
            AppLogger.core.log(.error, "최근 검색어 인코딩 실패: \(error.localizedDescription)")
        }
    }
}
