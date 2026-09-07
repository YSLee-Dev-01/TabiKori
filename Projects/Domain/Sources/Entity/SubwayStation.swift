//
//  SubwayStation.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct SubwayStation: Equatable, Sendable {
    public let stationCode: String
    public let frCode: String
    public let koreanName: String
    public let japaneseName: String
    public let lineNumbers: [String]

    public init(
        stationCode: String,
        frCode: String,
        koreanName: String,
        japaneseName: String,
        lineNumbers: [String]
    ) {
        self.stationCode = stationCode
        self.frCode = frCode
        self.koreanName = koreanName
        self.japaneseName = japaneseName
        self.lineNumbers = lineNumbers
    }

    /// 일부 역의 japaneseName(station_nm_jpn)에 반각 괄호로 된 부가 표기(예: "(DDP)", "(新村)")가 섞여 있어,
    /// TouristSpot.title의 전각 괄호 파싱 규칙(japaneseTitle/koreanTitle)과 충돌한다 — 제거한 순수 일본어 역명.
    /// 일본어명이 비어 있으면 한국어명으로 폴백한다.
    public var displayJapaneseName: String {
        let trimmedJapaneseName: String
        if let openRange = self.japaneseName.range(of: "(") {
            trimmedJapaneseName = String(self.japaneseName[self.japaneseName.startIndex ..< openRange.lowerBound]).trimmingCharacters(in: .whitespaces)
        } else {
            trimmedJapaneseName = self.japaneseName.trimmingCharacters(in: .whitespaces)
        }
        return trimmedJapaneseName.isEmpty ? self.koreanName : trimmedJapaneseName
    }
}
