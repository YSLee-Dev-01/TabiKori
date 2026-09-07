//
//  TestToastCenter.swift
//  Domain
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// TCA 의존성(testValue)용 테스트 더블 — 호출된 `ToastItem`들을 배열로 기록한다
public final class TestToastCenter: ToastCenterProtocol, @unchecked Sendable {
    public var shownItems: [ToastItem] = []
    public var actionTappedIds: [UUID] = []

    public init() {}

    public var events: AsyncStream<ToastItem> {
        AsyncStream { _ in }
    }

    public var actionTapEvents: AsyncStream<UUID> {
        AsyncStream { _ in }
    }

    public func show(_ item: ToastItem) {
        self.shownItems.append(item)
    }

    public func notifyActionTapped(id: UUID) {
        self.actionTappedIds.append(id)
    }
}
