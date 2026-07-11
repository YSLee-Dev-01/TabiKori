//
//  Secret.swift
//  Data
//
//  Created by 이윤수 on 7/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Core

enum Secret {
    static let tourAPIKey: String = Self.value(for: "TOUR_API_KEY")
}

private extension Secret {
    static func value(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            AppLogger.network.log(.error, "❌ Info.plist 키 누락: \(key)")
            return ""
        }
        return value
    }
}
