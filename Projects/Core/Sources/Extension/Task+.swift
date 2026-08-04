//
//  Task+.swift
//  Core
//
//  Created by 이윤수 on 8/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public extension Task where Success == Never, Failure == Never {
    /// operation을 실행하는 동안 최소 seconds만큼의 시간을 보장한다.
    /// operation이 seconds보다 먼저 끝나도 남은 시간만큼 대기한 뒤 결과를 반환하고,
    /// operation이 seconds보다 오래 걸리면 추가 대기 없이 완료 즉시 반환한다.
    static func withMinimumDuration<T: Sendable>(
        seconds: TimeInterval,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        async let result = try operation()
        async let minimumDelay: Void? = try? Task.sleep(for: .seconds(seconds))

        _ = await minimumDelay
        return try await result
    }
}
