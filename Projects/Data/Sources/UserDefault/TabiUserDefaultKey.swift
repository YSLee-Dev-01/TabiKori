//
//  TabiUserDeaultKey.swift
//  Data
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum TabiUserDefaultKey: String {
    case onboardingCompleted
    case recentSearchHistory
    case autoScrollToTodayEnabled
    case autoTranslateSearchEnabled
    /// 팝업 공지 "오늘 하루 보지 않기" 기록: [공지 id: 닫은 날짜("yyyyMMdd") 문자열]
    case noticePopupDismissedRecords
}
