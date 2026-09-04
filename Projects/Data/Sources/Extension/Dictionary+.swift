//
//  Dictionary+.swift
//  Data
//
//  Created by 이윤수 on 9/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    /// { "ko": ..., "ja": ... } 형태의 다국어 필드 dict에서 기기 로케일에 맞는 문자열을 반환
    var localizedStringValue: String? {
        let languageKey = Locale.current.language.languageCode == .korean ? "ko" : "ja"
        return (self[languageKey] as? String) ?? (self["ja"] as? String) ?? (self["ko"] as? String)
    }
}
