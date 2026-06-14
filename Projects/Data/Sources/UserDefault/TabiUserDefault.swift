//
//  TabiUserDefault.swift
//  Data
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TabiUserDefault: TabiUserDefaultProtocol, @unchecked Sendable {

    public static let shared = TabiUserDefault()
    private init() {}
    
    private let sharedUserDefaults: UserDefaults = UserDefaults(suiteName: "group.com.yslee.tabikori") ?? .standard
    
    public func set<T>(_ value: T, forKey: TabiUserDefaultKey) {
        self.sharedUserDefaults.set(value, forKey: forKey.rawValue)
    }

    public func get<T>(forKey: TabiUserDefaultKey) -> T? {
        return self.sharedUserDefaults.object(forKey: forKey.rawValue) as? T
    }
}
