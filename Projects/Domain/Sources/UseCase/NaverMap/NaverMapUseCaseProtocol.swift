//
//  NaverMapUseCaseProtocol.swift
//  Domain
//
//  Created by 이윤수 on 7/23/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol NaverMapUseCaseProtocol: Sendable {
    func searchPlace(query: String) async
    func routeToDestination(coordinate: Coordinate, destinationName: String) async
}
