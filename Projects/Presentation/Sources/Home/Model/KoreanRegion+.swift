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
        }
    }

    var image: TabiImage {
        switch self {
        case .seoul: .regionSeoul
        case .busan: .regionBusan
        case .jeju: .regionJeju
        case .gyeongju: .regionGyeongju
        case .yeosu: .regionYeosu
        case .gangneung: .regionGangneung
        case .jeonju: .regionJeonju
        }
    }

    static let allItems: [Self] = [
        .seoul, .busan, .jeju, .gyeongju, .yeosu, .gangneung, .jeonju
    ]
}
