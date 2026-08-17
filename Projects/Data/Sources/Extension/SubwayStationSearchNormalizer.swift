//
//  SubwayStationSearchNormalizer.swift
//  Data
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

/// 지하철역 검색어 대조 전용 정규화. 한국어 역명(`station_nm`)/일본어 가타카나 역명(`station_nm_jpn`) 매칭에만 사용하며,
/// 관광공사 응답 정제용 `Core`의 `String+`와는 목적이 달라 분리한다.
extension String {
    var subwayStationSearchKey: String {
        var value = self.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.applyingTransform(.hiraganaToKatakana, reverse: false) ?? value
        value = value.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? value
        value = value.replacingOccurrences(of: "駅", with: "")
        value = value.replacingOccurrences(of: "역", with: "")
        value = value.replacingOccurrences(of: "・", with: "")
        return value.uppercased()
    }
}
