//
//  AutoTranslateSearchUseCase.swift
//  Domain
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class AutoTranslateSearchUseCase: AutoTranslateSearchUseCaseProtocol {

    // MARK: - Properties

    private let repository: AutoTranslateSearchRepositoryProtocol

    // MARK: - Init

    public init(repository: AutoTranslateSearchRepositoryProtocol) {
        self.repository = repository
    }

    public func isEnabled() -> Bool {
        return self.repository.isEnabled()
    }

    public func setEnabled(_ isEnabled: Bool) {
        self.repository.setEnabled(isEnabled)
    }
}
