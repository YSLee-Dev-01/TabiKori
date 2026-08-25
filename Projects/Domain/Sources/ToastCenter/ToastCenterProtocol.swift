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
public protocol ToastCenterProtocol: Sendable {
    /// 새 Toast 이벤트를 브로드캐스트한다
    func show(_ item: ToastItem)

    /// 브로드캐스트된 Toast 이벤트를 구독할 수 있는 스트림
    var events: AsyncStream<ToastItem> { get }
}
