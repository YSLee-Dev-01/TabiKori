//
//  AutoScrollToTodayUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class AutoScrollToTodayUseCase: AutoScrollToTodayUseCaseProtocol {

    // MARK: - Properties

    private let repository: AutoScrollToTodayRepositoryProtocol

    // MARK: - Init

    public init(repository: AutoScrollToTodayRepositoryProtocol) {
        self.repository = repository
    }

    public func isEnabled() -> Bool {
        return self.repository.isEnabled()
    }

    public func setEnabled(_ isEnabled: Bool) {
        self.repository.setEnabled(isEnabled)
    }
}
