//
//  TestDataResetUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestDataResetUseCase: DataResetUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var shouldThrowError: Bool = false
    public var resetAllCalled: Bool = false

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func resetAll() async throws {
        self.resetAllCalled = true
        if self.shouldThrowError {
            throw TabiError.persistenceFailed(message: "테스트 초기화 실패")
        }
    }
}
