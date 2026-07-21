//
//  TabiMapMarker.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/20/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct TabiMapMarker: Identifiable, Equatable {
    public let id: String
    public let latitude: Double
    public let longitude: Double
    public let title: String

    public init(id: String, latitude: Double, longitude: Double, title: String) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
    }
}
