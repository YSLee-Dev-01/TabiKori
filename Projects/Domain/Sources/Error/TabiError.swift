//
//  TabiError.swift
//  Domain
//
//  Created by 이윤수 on 7/9/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum TabiError: Error, Equatable, Sendable {
    case apiFailed(code: String, message: String)
    case dataNotFound
}
