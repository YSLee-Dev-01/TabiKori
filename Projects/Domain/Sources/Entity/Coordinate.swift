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
}
