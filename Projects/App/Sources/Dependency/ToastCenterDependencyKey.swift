//
//  ToastCenterDependencyKey.swift
//  App
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain
import Core

import ComposableArchitecture

/// Core의 제네릭 `BroadcastCenter<ToastItem>`을 Domain의 `ToastCenterProtocol`에 연결한다
///
/// Core는 Domain을 참조하지 않으므로 `BroadcastCenter`는 Toast를 알지 못하는 제네릭 구현체이며,
/// App(양쪽 모듈을 모두 참조 가능한 계층)에서만 두 계층을 이어줄 수 있다
extension BroadcastCenter: @retroactive ToastCenterProtocol where Element == ToastItem {
    public func show(_ item: ToastItem) {
        self.broadcast(item)
    }
}

extension ToastCenterDependencyKey: @retroactive DependencyKey {
    public static let liveValue: ToastCenterProtocol = BroadcastCenter<ToastItem>()
}
