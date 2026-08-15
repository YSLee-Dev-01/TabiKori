//
//  BookmarkModelContainer.swift
//  Data
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

import Core

public final class BookmarkModelContainer: Sendable {

    // MARK: - Properties

    public static let shared = BookmarkModelContainer()

    public let modelContainer: ModelContainer
    public let isFallbackToMemory: Bool

    // MARK: - Init

    private init() {
        let schema = Schema([BookmarkModel.self])
        do {
            let configuration = ModelConfiguration("Bookmark", schema: schema)
            self.modelContainer = try ModelContainer(for: schema, configurations: configuration)
            self.isFallbackToMemory = false
        } catch {
            AppLogger.core.log(.error, "BookmarkModelContainer 생성 실패, in-memory로 폴백: \(error.localizedDescription)")
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            guard let fallback = try? ModelContainer(for: schema, configurations: fallbackConfig) else {
                fatalError("BookmarkModelContainer in-memory 폴백조차 실패: \(error.localizedDescription)")
            }
            self.modelContainer = fallback
            self.isFallbackToMemory = true
        }
    }
}
