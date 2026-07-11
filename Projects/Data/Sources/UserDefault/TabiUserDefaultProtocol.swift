//
//  TabiUserDefaultProtocol.swift
//  Data
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol TabiUserDefaultProtocol: Sendable {
    func set<T>(_ value: T, forKey: TabiUserDefaultKey)
    func get<T>(forKey: TabiUserDefaultKey) -> T?
}
