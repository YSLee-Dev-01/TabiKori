//
//  SubwayStationUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol SubwayStationUseCaseProtocol: Sendable {
    func search(keyword: String) async -> [TouristSpot]
}
