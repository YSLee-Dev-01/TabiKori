//
//  TestSubwayStationUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestSubwayStationUseCase: SubwayStationUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var searchResults: [TouristSpot] = []

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func search(keyword: String) async -> [TouristSpot] {
        return self.searchResults
    }
}
