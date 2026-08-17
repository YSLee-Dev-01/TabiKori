//
//  GeocodedAddress.swift
//  Domain
//
//  Created by 이윤수 on 8/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct GeocodedAddress: Equatable, Sendable {
    public let coordinate: Coordinate
    public let formattedAddress: String

    public init(coordinate: Coordinate, formattedAddress: String) {
        self.coordinate = coordinate
        self.formattedAddress = formattedAddress
    }
}
