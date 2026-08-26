//
//  ToastCenterProtocol.swift
//  Domain
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 앱 전역 Toast 이벤트를 브로드캐스트하는 센터
///
/// `show(_:)`로 이벤트를 발행하고, `events` 스트림을 구독하는 쪽(RootFeature)이
/// 큐에 쌓아 순차적으로 화면에 표시한다.
///
/// Toast의 액션 버튼이 탭된 경우, RootFeature는 어떤 화면이 이 Toast를 띄웠는지 알지 못한다.
/// 대신 `notifyActionTapped(id:)`로 탭된 `ToastItem.id`만 다시 브로드캐스트하면,
/// 해당 Toast를 띄운 화면이 `actionTapEvents`를 구독해 자신이 띄운 id와 일치하는지 확인하고
/// 필요한 후속 동작(번역 후 재검색 등)을 직접 수행한다
public protocol ToastCenterProtocol: Sendable {
    /// 새 Toast 이벤트를 브로드캐스트한다
    func show(_ item: ToastItem)

    /// 브로드캐스트된 Toast 이벤트를 구독할 수 있는 스트림
    var events: AsyncStream<ToastItem> { get }

    /// Toast 액션 버튼이 탭되었음을 해당 `ToastItem.id`로 브로드캐스트한다
    func notifyActionTapped(id: UUID)

    /// 액션 버튼이 탭된 `ToastItem.id`를 구독할 수 있는 스트림
    var actionTapEvents: AsyncStream<UUID> { get }
}
