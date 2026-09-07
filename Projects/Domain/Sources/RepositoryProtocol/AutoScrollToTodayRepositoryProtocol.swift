//
//  AutoScrollToTodayRepositoryProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol AutoScrollToTodayRepositoryProtocol: Sendable {
    func isEnabled() -> Bool
    func setEnabled(_ isEnabled: Bool)
}
