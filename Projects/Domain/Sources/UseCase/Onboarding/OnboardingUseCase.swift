//
//  OnboardingUseCase.swift
//  Domain
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class OnboardingUseCase: OnboardingUseCaseProtocol {

    // MARK: - Properties

    private let repository: OnboardingRepositoryProtocol

    // MARK: - Init

    public init(repository: OnboardingRepositoryProtocol) {
        self.repository = repository
    }

    public func isCompleted() -> Bool {
        return self.repository.isCompleted()
    }

    public func markAsCompleted() {
        self.repository.markAsCompleted()
    }
}
