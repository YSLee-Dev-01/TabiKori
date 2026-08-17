//
//  SubwayStationRepositoryProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol SubwayStationRepositoryProtocol: Sendable {
    func searchLocal(keyword: String) async -> [SubwayStation]
    func confirmExists(stationName: String) async throws -> Bool
}
