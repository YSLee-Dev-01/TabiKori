//
//  AutoTranslateSearchRepositoryProtocol.swift
//  Domain
//
//  Created by Claude on 8/25/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol AutoTranslateSearchRepositoryProtocol: Sendable {
    func isEnabled() -> Bool
    func setEnabled(_ isEnabled: Bool)
}
