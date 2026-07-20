//
//  TabiClusteringKey.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/20/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import NMapsMap

final class TabiClusteringKey: NSObject {
    let markerID: String
    let position: NMGLatLng

    init(markerID: String, position: NMGLatLng) {
        self.markerID = markerID
        self.position = position
    }
}

// MARK: - NMCClusteringKey

extension TabiClusteringKey: NMCClusteringKey {}

// MARK: - NSCopying

extension TabiClusteringKey: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        TabiClusteringKey(markerID: self.markerID, position: self.position)
    }
}

// MARK: - Equality

extension TabiClusteringKey {
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? TabiClusteringKey else { return false }
        return self.markerID == other.markerID
    }

    override var hash: Int {
        self.markerID.hashValue
    }
}
