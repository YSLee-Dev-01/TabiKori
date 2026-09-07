//
//  FirebaseListCache.swift
//  Data
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 자주 바뀌지 않는 Firebase RTDB 정적 목록(준비물/쇼핑/한국어 문구 등)을 최초 조회 후 메모리에 캐싱한다.
actor FirebaseListCache<Item: Sendable> {
    private var cached: [Item]?

    func value(fetch: () async throws -> [Item]) async throws -> [Item] {
        if let cached { return cached }
        let value = try await fetch()
        self.cached = value
        return value
    }
}
