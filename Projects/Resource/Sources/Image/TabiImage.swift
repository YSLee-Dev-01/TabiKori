//
//  TabiImage.swift
//  Resource
//
//  Created by 이윤수 on 6/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public enum TabiImage: String {

    // MARK: - Image

    case star = "star"
    case seoulTower = "seoulTower"
}

public enum TabiIcon: String {

    // MARK: - Category Icon

    case sightseeing = "building.columns"
    case food = "fork.knife"
    case hotel = "bed.double"
    case festival = "calendar"
    case shopping = "bag"
    case nature = "leaf"
}

// MARK: - Extension

extension Image {
    public init(_ tabiImage: TabiImage) {
        self.init(tabiImage.rawValue, bundle: .module)
    }

    public init(_ tabiIcon: TabiIcon) {
        self.init(systemName: tabiIcon.rawValue)
    }
}
