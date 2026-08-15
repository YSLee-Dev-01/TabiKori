//
//  KoreanRegion+.swift
//  Presentation
//
//  Created by 이윤수 on 6/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import Domain
import Resource

extension KoreanRegion {

    var jaTitle: String {
        switch self {
        case .seoul: Strings.Region.seoul
        case .busan: Strings.Region.busan
        case .jeju: Strings.Region.jeju
        case .gyeongju: Strings.Region.gyeongju
        case .yeosu: Strings.Region.yeosu
        case .gangneung: Strings.Region.gangneung
        case .jeonju: Strings.Region.jeonju
        case .etc: Strings.Region.etc
        }
    }

    var koTitle: String {
        switch self {
        case .seoul: Strings.Region.seoulKo
        case .busan: Strings.Region.busanKo
        case .jeju: Strings.Region.jejuKo
        case .gyeongju: Strings.Region.gyeongjuKo
        case .yeosu: Strings.Region.yeosuKo
        case .gangneung: Strings.Region.gangneungKo
        case .jeonju: Strings.Region.jeonjuKo
        case .etc: Strings.Region.etcKo
        }
    }

    /// 홈 화면 지역 배너 전용 이미지. `.etc`는 대응 에셋이 없고 `allItems`에도 포함되지 않아 실제로 호출되지 않는다
    var image: TabiImage? {
        switch self {
        case .seoul: .regionSeoul
        case .busan: .regionBusan
        case .jeju: .regionJeju
        case .gyeongju: .regionGyeongju
        case .yeosu: .regionYeosu
        case .gangneung: .regionGangneung
        case .jeonju: .regionJeonju
        case .etc: nil
        }
    }

    /// Plan 기능 카드 기본 아이콘. `.etc`는 대표 이모지가 없어 사용자 직접 입력을 유도하기 위해 nil 반환
    var emoji: String? {
        switch self {
        case .seoul: "🏙️"
        case .busan: "🌊"
        case .jeju: "🌋"
        case .gyeongju: "🏛️"
        case .yeosu: "⚓️"
        case .gangneung: "☕️"
        case .jeonju: "🏘️"
        case .etc: nil
        }
    }

    /// 일정 추가 화면 그리드 전용 아이콘. `.etc`는 직접 입력을 유도하는 연필 아이콘을 반환
    var gridEmoji: String {
        self.emoji ?? "✏️"
    }

    static let allItems: [Self] = [
        .seoul, .busan, .jeju, .gyeongju, .yeosu, .gangneung, .jeonju
    ]

    /// 일정 추가 화면 지역 그리드 전용 목록. 홈 화면 배너용 `allItems`와 달리 `.etc`를 포함한다
    static let planGridItems: [Self] = allItems + [.etc]
}
