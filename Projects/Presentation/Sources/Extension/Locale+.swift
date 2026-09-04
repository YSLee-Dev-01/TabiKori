//
//  Locale+.swift
//  Presentation
//
//  Created by Claude on 9/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

extension Locale {
    /// 시스템 로케일이 한국어인지 여부. 일본어 사용자 대상 번역 버튼·언어 안내 문구 등
    /// 한국어 사용자에게는 의미가 없는 UI의 노출 조건으로 사용
    static var isKoreanLanguage: Bool {
        Locale.current.language.languageCode == .korean
    }
}
