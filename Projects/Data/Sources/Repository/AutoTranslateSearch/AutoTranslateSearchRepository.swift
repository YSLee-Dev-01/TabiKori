//
//  AutoTranslateSearchRepository.swift
//  Data
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

public final class AutoTranslateSearchRepository: AutoTranslateSearchRepositoryProtocol {

    // MARK: - Properties

    private let userDefault: TabiUserDefaultProtocol

    // MARK: - Init

    public init(userDefault: TabiUserDefaultProtocol = TabiUserDefault.shared) {
        self.userDefault = userDefault
    }

    public func isEnabled() -> Bool {
        return self.userDefault.get(forKey: .autoTranslateSearchEnabled) ?? true
    }

    public func setEnabled(_ isEnabled: Bool) {
        self.userDefault.set(isEnabled, forKey: .autoTranslateSearchEnabled)
    }
}
