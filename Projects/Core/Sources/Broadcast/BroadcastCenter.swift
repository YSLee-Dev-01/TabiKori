//
//  BroadcastCenter.swift
//  Core
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// `AsyncStream` 기반 전역 이벤트 브로드캐스터
///
/// Toast 등 앱 전역에 알림성 이벤트를 전달할 때 사용하는 최하위 레이어 유틸리티로,
/// 특정 도메인 타입에 의존하지 않는 제네릭 구조로 구현되어 있다.
/// 상위 모듈(App)에서 `Element`를 구체 타입으로 지정해 도메인 프로토콜과 연결한다.
public final class BroadcastCenter<Element: Sendable>: @unchecked Sendable {

    // MARK: - Properties

    private let stream: AsyncStream<Element>
    private let continuation: AsyncStream<Element>.Continuation

    public var events: AsyncStream<Element> {
        self.stream
    }

    // MARK: - Init

    public init() {
        var continuation: AsyncStream<Element>.Continuation!
        self.stream = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    // MARK: - Method

    public func broadcast(_ element: Element) {
        self.continuation.yield(element)
    }
}
