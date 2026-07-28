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

    // MARK: - Init

    private init() {
        do {
            self.modelContainer = try ModelContainer(for: Schema([BookmarkModel.self]))
        } catch {
            AppLogger.core.log(.error, "BookmarkModelContainer 생성 실패: \(error.localizedDescription)")
            fatalError("BookmarkModelContainer 생성 실패: \(error.localizedDescription)")
        }
    }
}
