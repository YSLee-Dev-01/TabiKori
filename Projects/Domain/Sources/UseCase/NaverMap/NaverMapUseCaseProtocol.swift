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
    func makeShareURL(query: String) -> URL?
}

public enum NaverMapShareURLConstant {
    public static let scheme = "https"
    public static let host = "map.naver.com"
    public static let searchPathPrefix = "/p/search/"
}
