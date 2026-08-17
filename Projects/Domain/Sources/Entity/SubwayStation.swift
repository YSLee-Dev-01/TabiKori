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
}
