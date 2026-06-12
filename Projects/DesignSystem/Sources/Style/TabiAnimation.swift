//
//  TabiAnimation.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public extension Animation {
    static let tabiFast = Animation.timingCurve(0.4, 0.0, 0.6, 1, duration: 0.15)
    static let tabiStandard = Animation.timingCurve(0.4, 0.0, 0.2, 1, duration: 0.25)
    static let tabiModerate = Animation.timingCurve(0.0, 0.0, 0.2, 1, duration: 0.35)
    static let tabiSlow = Animation.timingCurve(0.0, 0.0, 0.2, 1, duration: 0.50)
    static let tabiSpring = Animation.spring(response: 0.35, dampingFraction: 0.7)
}
