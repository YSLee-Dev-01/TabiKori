//
//  TabiMapMarkerImageFactory.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import UIKit

@preconcurrency import NMapsMap

import Resource

@MainActor
enum TabiMapMarkerImageFactory {
    private static var cache: [String: NMFOverlayImage] = [:]

    static func image(icon: TabiIcon, color: TabiColor) -> NMFOverlayImage {
        let reuseIdentifier = "\(icon.rawValue)-\(color.rawValue)"
        if let cached = self.cache[reuseIdentifier] {
            return cached
        }

        let renderer = ImageRenderer(content: TabiMapMarkerPinView(icon: icon, color: color))
        renderer.scale = UIScreen.main.scale
        let uiImage = renderer.uiImage ?? UIImage()
        let overlayImage = NMFOverlayImage(image: uiImage, reuseIdentifier: reuseIdentifier)
        self.cache[reuseIdentifier] = overlayImage
        return overlayImage
    }
}
