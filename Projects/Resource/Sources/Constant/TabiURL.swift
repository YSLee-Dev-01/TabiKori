//
//  TabiURL.swift
//  Resource
//
//  Created by 이윤수 on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 앱 전역에서 공용으로 사용하는 외부 URL 상수 모음 (Setting, Onboarding 등에서 참조)
public enum TabiURL {
    /// 개인정보 처리방침 페이지 URL
    public static let privacyPolicy = "https://carnelian-gateway-8a5.notion.site/3c8937a1cf2080b79cece01350c5da81?pvs=74"

    /// 강제 업데이트 Alert에서 이동할 App Store 앱 페이지 URL
    public static let appStoreUpdatePage = "https://apps.apple.com/kr/app/%ED%83%80%EB%B9%84%EC%BD%94%EB%A6%AC/id6805470024"
}
