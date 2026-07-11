//
//  TestLocationUseCase.swift
//  Domain
//
//  Created by 이윤수 on 6/24/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestLocationUseCase: LocationUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var coordinate: Coordinate = Coordinate(latitude: 37.5665, longitude: 126.9780)
    public var region: TravelRegion = .korea(.seoul)

    // MARK: - Method

    public func checkAuthorization() -> LocationAuthorizationStatus {
        return .allowed
    }

    public func requestAuthorization() async -> LocationAuthorizationStatus {
        return .allowed
    }

    public func fetchCurrentCoordinate() async throws -> Coordinate {
        return self.coordinate
    }

    public func fetchCurrentRegion() async throws -> TravelRegion {
        return self.region
    }
}
