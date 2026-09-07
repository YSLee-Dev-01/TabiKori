//
//  PlanDetailNextFrameTrigger.swift
//  Presentation
//
//  Created by 이윤수 on 8/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import UIKit

/// 다음 화면 갱신 프레임 이후(디스플레이 vsync 1회 경과 후) 클로저를 1회 실행한다.
///
/// `PlanDetailView`의 일자 전환 애니메이션은 방향 플래그(`isMovingForward`) 변경과
/// `selectedDayIndex` 변경이 같은 SwiftUI 렌더 트랜잭션에 묶이면, 사라지는 뷰의 removal
/// transition이 직전 프레임에 커밋된 방향을 그대로 사용해 역방향 전환 시 이전 title이
/// 밀려나지 않고 남는 문제가 있다. `DispatchQueue.main.async`는 같은 화면 갱신 프레임
/// 안에서 실행될 수 있어 두 변경을 분리하지 못하므로, 실제 프레임 경계를 보장하는
/// `CADisplayLink`로 두 상태 변경을 서로 다른 렌더 트랜잭션으로 분리한다.
final class PlanDetailNextFrameTrigger {
    private var displayLink: CADisplayLink?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        let link = CADisplayLink(target: self, selector: #selector(self.fire))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }

    func cancel() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
}

// MARK: - Method

private extension PlanDetailNextFrameTrigger {
    @objc func fire() {
        self.cancel()
        self.action()
    }
}
