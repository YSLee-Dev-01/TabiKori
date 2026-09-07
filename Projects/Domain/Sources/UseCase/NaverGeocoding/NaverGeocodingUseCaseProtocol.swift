//
//  NaverGeocodingUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol NaverGeocodingUseCaseProtocol: Sendable {
    func geocode(address: String) async throws -> GeocodedAddress
}
