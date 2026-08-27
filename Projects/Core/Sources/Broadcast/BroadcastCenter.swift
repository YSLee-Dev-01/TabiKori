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
///
/// `events`에 접근할 때마다 새 `AsyncStream`과 그 `Continuation`을 내부 목록에 등록하고,
/// `broadcast(_:)`는 등록된 모든 `Continuation`에 값을 전달한다. 여러 화면이 동시에
/// `events`를 구독해도(예: 여러 Feature가 각자 `.onAppear`에서 구독하는 경우) 각자 독립된
/// 스트림을 받으므로 이벤트가 특정 구독자에게만 전달되고 나머지는 놓치는 일이 없다.
/// 구독이 취소되면(`Task` 취소 등) `onTermination`에서 해당 `Continuation`을 목록에서 제거한다
public final class BroadcastCenter<Element: Sendable>: @unchecked Sendable {

    // MARK: - Properties

    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    public var events: AsyncStream<Element> {
        AsyncStream { continuation in
            let id = UUID()
            self.lock.lock()
            self.continuations[id] = continuation
            self.lock.unlock()

            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lock.lock()
                self.continuations.removeValue(forKey: id)
                self.lock.unlock()
            }
        }
    }

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func broadcast(_ element: Element) {
        self.lock.lock()
        let activeContinuations = Array(self.continuations.values)
        self.lock.unlock()

        for continuation in activeContinuations {
            continuation.yield(element)
        }
    }
}
