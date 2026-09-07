//
//  Coordinate.swift
//  Domain
//
//  Created by 이윤수 on 7/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct Coordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public static let zero = Coordinate(latitude: 0, longitude: 0)
    public static let seoulCityHall = Coordinate(latitude: 37.5666102, longitude: 126.9783881)

    public var isValid: Bool {
        return self != .zero
    }
}
