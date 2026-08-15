//
//  TabiMapMarker.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/20/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Resource

public struct TabiMapMarker: Identifiable, Equatable, Sendable {
    public let id: String
    public let latitude: Double
    public let longitude: Double
    public let title: String
    public let icon: TabiIcon
    public let color: TabiColor
    public let index: Int?

    public init(id: String, latitude: Double, longitude: Double, title: String, icon: TabiIcon, color: TabiColor, index: Int? = nil) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.icon = icon
        self.color = color
        self.index = index
    }
}
