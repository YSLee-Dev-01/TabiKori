//
//  BookmarkUseCaseDependencyKey.swift
//  App
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Data

extension BookmarkUseCaseDependencyKey: @retroactive DependencyKey {
    public static var liveValue: BookmarkUseCaseProtocol {
        BookmarkUseCase(repository: BookmarkRepository())
    }
}
