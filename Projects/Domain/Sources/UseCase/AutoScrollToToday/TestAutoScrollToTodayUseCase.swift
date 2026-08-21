//
//  TestAutoScrollToTodayUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestAutoScrollToTodayUseCase: AutoScrollToTodayUseCaseProtocol, @unchecked Sendable {
    public var isEnabledValue: Bool = false

    public init() {}

    public func isEnabled() -> Bool {
        return self.isEnabledValue
    }

    public func setEnabled(_ isEnabled: Bool) {
        self.isEnabledValue = isEnabled
    }
}
