//
//  TabiMapView.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import NMapsMap

public struct TabiMapView {
    private let centerLatitude: Double
    private let centerLongitude: Double
    private let zoomLevel: Double
    private let markers: [TabiMapMarker]
    private let isClusteringEnabled: Bool
    private let showsLocationButton: Bool
    private let onMapTapped: (Double, Double) -> Void
    private let onMarkerTapped: (String) -> Void

    public init(
        centerLatitude: Double,
        centerLongitude: Double,
        zoomLevel: Double = 15,
        markers: [TabiMapMarker] = [],
        isClusteringEnabled: Bool = false,
        showsLocationButton: Bool = false,
        onMapTapped: @escaping (Double, Double) -> Void,
        onMarkerTapped: @escaping (String) -> Void
    ) {
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.zoomLevel = zoomLevel
        self.markers = markers
        self.isClusteringEnabled = isClusteringEnabled
        self.showsLocationButton = showsLocationButton
        self.onMapTapped = onMapTapped
        self.onMarkerTapped = onMarkerTapped
    }
}

// MARK: - UIViewRepresentable

extension TabiMapView: UIViewRepresentable {
    public func makeCoordinator() -> Coordinator {
        Coordinator(onMapTapped: self.onMapTapped, onMarkerTapped: self.onMarkerTapped)
    }

    public func makeUIView(context: Context) -> NMFNaverMapView {
        let naverMapView = NMFNaverMapView(frame: .zero)
        naverMapView.mapView.touchDelegate = context.coordinator

        let cameraUpdate = NMFCameraUpdate(
            scrollTo: NMGLatLng(lat: self.centerLatitude, lng: self.centerLongitude),
            zoomTo: self.zoomLevel
        )
        naverMapView.mapView.moveCamera(cameraUpdate)

        context.coordinator.sync(
            markers: self.markers,
            isClusteringEnabled: self.isClusteringEnabled,
            on: naverMapView.mapView
        )

        return naverMapView
    }

    public func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        uiView.showLocationButton = self.showsLocationButton
        uiView.mapView.positionMode = self.showsLocationButton ? .direction : .disabled

        context.coordinator.sync(
            markers: self.markers,
            isClusteringEnabled: self.isClusteringEnabled,
            on: uiView.mapView
        )
    }
}
