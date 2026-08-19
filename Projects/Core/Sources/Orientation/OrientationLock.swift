//
//  OrientationLock.swift
//  Core
//
//  Created by 이윤수 on 8/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import UIKit

/// 앱 전역 화면 방향 락 상태를 보관하는 전역 컨테이너.
/// 기본값은 `.portrait`이며, 가로모드가 필요한 화면(예: 한국어 문구 상세)에 진입할 때만 일시적으로 값을 갱신한다.
/// `AppDelegate.application(_:supportedInterfaceOrientationsFor:)`가 이 값을 참조해 실제 허용 방향을 결정하므로,
/// 이 값을 갱신하지 않는 나머지 화면은 항상 portrait로 고정된다
public final class OrientationLock: @unchecked Sendable {

    // MARK: - Properties

    public static let shared = OrientationLock()

    private let lock = NSLock()
    private var currentMask: UIInterfaceOrientationMask = .portrait

    // MARK: - Init

    private init() {}

    // MARK: - Method

    public var mask: UIInterfaceOrientationMask {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.currentMask
    }

    public func setMask(_ mask: UIInterfaceOrientationMask) {
        self.lock.lock()
        self.currentMask = mask
        self.lock.unlock()
    }
}
