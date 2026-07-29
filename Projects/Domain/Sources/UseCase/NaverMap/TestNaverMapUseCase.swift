//
//  TestNaverMapUseCase.swift
//  Domain
//
//  Created by 이윤수 on 7/23/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestNaverMapUseCase: NaverMapUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var searchedQuery: String?
    public var routedCoordinate: Coordinate?
    public var routedDestinationName: String?
    public var sharedQuery: String?

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func searchPlace(query: String) async {
        self.searchedQuery = query
    }

    public func routeToDestination(coordinate: Coordinate, destinationName: String) async {
        self.routedCoordinate = coordinate
        self.routedDestinationName = destinationName
    }

    public func makeShareURL(query: String) -> URL? {
        self.sharedQuery = query
        var components = URLComponents()
        components.scheme = "https"
        components.host = "map.naver.com"
        components.path = "/p/search/\(query)"
        return components.url
    }
}
