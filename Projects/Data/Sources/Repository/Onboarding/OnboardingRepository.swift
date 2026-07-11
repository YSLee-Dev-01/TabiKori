//
//  OnboardingRepository.swift
//  Data
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

public final class OnboardingRepository: OnboardingRepositoryProtocol {

    // MARK: - Properties

    private let userDefault: TabiUserDefaultProtocol

    // MARK: - Init

    public init(userDefault: TabiUserDefaultProtocol = TabiUserDefault.shared) {
        self.userDefault = userDefault
    }

    public func isCompleted() -> Bool {
        return self.userDefault.get(forKey: .onboardingCompleted) ?? false
    }

    public func markAsCompleted() {
        self.userDefault.set(true, forKey: .onboardingCompleted)
    }
}
