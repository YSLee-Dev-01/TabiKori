//
//  AutoScrollToTodayRepository.swift
//  Data
//
//  Created by 이윤수 on 8/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

public final class AutoScrollToTodayRepository: AutoScrollToTodayRepositoryProtocol {

    // MARK: - Properties

    private let userDefault: TabiUserDefaultProtocol

    // MARK: - Init

    public init(userDefault: TabiUserDefaultProtocol = TabiUserDefault.shared) {
        self.userDefault = userDefault
    }

    public func isEnabled() -> Bool {
        return self.userDefault.get(forKey: .autoScrollToTodayEnabled) ?? false
    }

    public func setEnabled(_ isEnabled: Bool) {
        self.userDefault.set(isEnabled, forKey: .autoScrollToTodayEnabled)
    }
}
