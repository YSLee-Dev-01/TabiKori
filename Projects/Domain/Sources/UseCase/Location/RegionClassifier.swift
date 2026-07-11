//
//  RegionClassifier.swift
//  Domain
//
//  Created by 이윤수 on 7/4/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

enum RegionClassifier {

    private struct Anchor {
        let coordinate: Coordinate
        let region: TravelRegion
    }

    private static let maxDistanceKm: Double = 300

    private static let anchors: [Anchor] = [
        Anchor(coordinate: Coordinate(latitude: 37.5665, longitude: 126.9780), region: .korea(.seoul)),
        Anchor(coordinate: Coordinate(latitude: 35.1796, longitude: 129.0756), region: .korea(.busan)),
        Anchor(coordinate: Coordinate(latitude: 33.4996, longitude: 126.5312), region: .korea(.jeju)),
        Anchor(coordinate: Coordinate(latitude: 35.8562, longitude: 129.2247), region: .korea(.gyeongju)),
        Anchor(coordinate: Coordinate(latitude: 34.7604, longitude: 127.6622), region: .korea(.yeosu)),
        Anchor(coordinate: Coordinate(latitude: 37.7519, longitude: 128.8761), region: .korea(.gangneung)),
        Anchor(coordinate: Coordinate(latitude: 35.8242, longitude: 127.1480), region: .korea(.jeonju)),
        Anchor(coordinate: Coordinate(latitude: 33.5904, longitude: 130.4017), region: .japan), // Fukuoka
        Anchor(coordinate: Coordinate(latitude: 34.3853, longitude: 132.4553), region: .japan), // Hiroshima
        Anchor(coordinate: Coordinate(latitude: 34.6937, longitude: 135.5023), region: .japan), // Osaka
        Anchor(coordinate: Coordinate(latitude: 35.6762, longitude: 139.6503), region: .japan), // Tokyo
        Anchor(coordinate: Coordinate(latitude: 38.2682, longitude: 140.8694), region: .japan), // Sendai
        Anchor(coordinate: Coordinate(latitude: 43.0618, longitude: 141.3545), region: .japan), // Sapporo
        Anchor(coordinate: Coordinate(latitude: 26.2124, longitude: 127.6809), region: .japan), // Naha (Okinawa)
    ]

    static func classify(_ coordinate: Coordinate) -> TravelRegion {
        let nearest = self.anchors.min { lhs, rhs in
            self.distanceKm(coordinate, lhs.coordinate) < self.distanceKm(coordinate, rhs.coordinate)
        }

        guard let nearest, self.distanceKm(coordinate, nearest.coordinate) <= self.maxDistanceKm else {
            return .unsupported
        }
        return nearest.region
    }

    private static func distanceKm(_ lhs: Coordinate, _ rhs: Coordinate) -> Double {
        let earthRadiusKm = 6371.0
        let lat1 = lhs.latitude * .pi / 180
        let lat2 = rhs.latitude * .pi / 180
        let deltaLat = (rhs.latitude - lhs.latitude) * .pi / 180
        let deltaLon = (rhs.longitude - lhs.longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKm * c
    }
}
