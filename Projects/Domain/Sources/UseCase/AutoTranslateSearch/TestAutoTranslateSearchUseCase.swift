//
//  TestAutoTranslateSearchUseCase.swift
//  Domain
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestAutoTranslateSearchUseCase: AutoTranslateSearchUseCaseProtocol, @unchecked Sendable {
    public var isEnabledValue: Bool = false

    public init() {}

    public func isEnabled() -> Bool {
        return self.isEnabledValue
    }

    public func setEnabled(_ isEnabled: Bool) {
        self.isEnabledValue = isEnabled
    }
}
