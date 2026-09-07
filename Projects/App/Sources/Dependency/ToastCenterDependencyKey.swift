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

/// Core의 제네릭 `BroadcastCenter<Element>`를 조합해 Domain의 `ToastCenterProtocol`을 구현한다
///
/// Core는 Domain을 참조하지 않으므로 `BroadcastCenter`는 Toast를 알지 못하는 제네릭 구현체이며,
/// App(양쪽 모듈을 모두 참조 가능한 계층)에서만 두 계층을 이어줄 수 있다.
/// Toast 표시 이벤트(`ToastItem`)와 액션 버튼 탭 이벤트(`UUID`)는 서로 다른 Element 타입이므로
/// 각각 별도의 `BroadcastCenter` 인스턴스로 관리한다
private final class LiveToastCenter: ToastCenterProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let itemCenter = BroadcastCenter<ToastItem>()
    private let actionTapCenter = BroadcastCenter<UUID>()

    public var events: AsyncStream<ToastItem> { self.itemCenter.events }
    public var actionTapEvents: AsyncStream<UUID> { self.actionTapCenter.events }

    // MARK: - Method

    public func show(_ item: ToastItem) {
        self.itemCenter.broadcast(item)
    }

    public func notifyActionTapped(id: UUID) {
        self.actionTapCenter.broadcast(id)
    }
}

extension ToastCenterDependencyKey: @retroactive DependencyKey {
    public static let liveValue: ToastCenterProtocol = LiveToastCenter()
}
