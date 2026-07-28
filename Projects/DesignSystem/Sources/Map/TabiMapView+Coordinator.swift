//
//  TabiMapView+Coordinator.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/20/26.
//  Copyright © 2026 yslee. All rights reserved.
//

@preconcurrency import NMapsMap

import Resource

extension TabiMapView {
    public final class Coordinator: NSObject {
        private let onMapTapped: (Double, Double) -> Void
        private let onMarkerTapped: (String) -> Void
        private let onMapDragged: () -> Void
        private var markerCache: [String: NMFMarker] = [:]
        private var clusterer: NMCClusterer<TabiClusteringKey>?
        private var clusteredKeys: [String: TabiClusteringKey] = [:]
        private var markerTitles: [String: String] = [:]
        private var markerAppearances: [String: (icon: TabiIcon, color: TabiColor)] = [:]
        private var lastAppliedFitToken: Int?
        private let singleMarkerFitZoomLevel: Double = 15
        private let boundsFitPadding: CGFloat = 60

        init(
            onMapTapped: @escaping (Double, Double) -> Void,
            onMarkerTapped: @escaping (String) -> Void,
            onMapDragged: @escaping () -> Void
        ) {
            self.onMapTapped = onMapTapped
            self.onMarkerTapped = onMarkerTapped
            self.onMapDragged = onMapDragged
        }
    }
}

// MARK: - NMFMapViewTouchDelegate

extension TabiMapView.Coordinator: NMFMapViewTouchDelegate {
    public func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        self.onMapTapped(latlng.lat, latlng.lng)
    }
}

// MARK: - NMFMapViewCameraDelegate

extension TabiMapView.Coordinator: NMFMapViewCameraDelegate {
    public func mapView(_ mapView: NMFMapView, cameraWillChangeByReason reason: Int, animated: Bool) {
        guard reason == NMFMapChangedByGesture else { return }
        self.onMapDragged()
    }
}

// MARK: - Marker Sync

extension TabiMapView.Coordinator {
    func sync(markers: [TabiMapMarker], isClusteringEnabled: Bool, boundsFitToken: Int, on mapView: NMFMapView) {
        if isClusteringEnabled {
            self.clearPlainMarkers()
            self.syncClusteredMarkers(markers, on: mapView)
        } else {
            self.clearClusterer()
            self.syncPlainMarkers(markers, on: mapView)
        }

        self.applyBoundsFitIfNeeded(token: boundsFitToken, markers: markers, on: mapView)
    }
}

// MARK: - Method

private extension TabiMapView.Coordinator {
    static let markerSize: CGFloat = 30
    static let captionTextSize: CGFloat = 10

    func syncPlainMarkers(_ markers: [TabiMapMarker], on mapView: NMFMapView) {
        let newIDs = Set(markers.map(\.id))
        let staleIDs = Set(self.markerCache.keys).subtracting(newIDs)

        for id in staleIDs {
            self.markerCache[id]?.mapView = nil
            self.markerCache.removeValue(forKey: id)
        }

        for marker in markers where self.markerCache[marker.id] == nil {
            let nmfMarker = NMFMarker()
            nmfMarker.position = NMGLatLng(lat: marker.latitude, lng: marker.longitude)
            nmfMarker.width = Self.markerSize
            nmfMarker.height = Self.markerSize
            // NMFMarker는 UI 오버레이라 sync(...)가 호출되는 makeUIView/updateUIView(메인 액터)에서만 안전함
            MainActor.assumeIsolated {
                nmfMarker.iconImage = TabiMapMarkerImageFactory.image(icon: marker.icon, color: marker.color)
            }
            nmfMarker.captionText = marker.title
            nmfMarker.captionTextSize = Self.captionTextSize
            nmfMarker.touchHandler = { [weak self] _ in
                self?.onMarkerTapped(marker.id)
                return true
            }
            nmfMarker.mapView = mapView
            self.markerCache[marker.id] = nmfMarker
        }
    }

    func clearPlainMarkers() {
        for marker in self.markerCache.values {
            marker.mapView = nil
        }
        self.markerCache.removeAll()
    }

    func applyBoundsFitIfNeeded(token: Int, markers: [TabiMapMarker], on mapView: NMFMapView) {
        guard token != self.lastAppliedFitToken else { return }
        self.lastAppliedFitToken = token
        guard markers.isEmpty == false else { return }

        let singleMarkerFitZoomLevel = self.singleMarkerFitZoomLevel
        let boundsFitPadding = self.boundsFitPadding

        // NMFMapView는 UIView(→ UIResponder)를 상속해 moveCamera가 @MainActor로 격리됨.
        // sync(...)는 UIViewRepresentable의 makeUIView/updateUIView(둘 다 메인 액터)에서만 호출되므로 안전함.
        MainActor.assumeIsolated {
            let cameraUpdate: NMFCameraUpdate
            if markers.count == 1, let marker = markers.first {
                cameraUpdate = NMFCameraUpdate(
                    scrollTo: NMGLatLng(lat: marker.latitude, lng: marker.longitude),
                    zoomTo: singleMarkerFitZoomLevel
                )
            } else {
                let latLngs = markers.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) }
                let bounds = NMGLatLngBounds(latLngs: latLngs)
                cameraUpdate = NMFCameraUpdate(fit: bounds, padding: boundsFitPadding)
            }
            mapView.moveCamera(cameraUpdate)
        }
    }

    func syncClusteredMarkers(_ markers: [TabiMapMarker], on mapView: NMFMapView) {
        let clusterer = self.clusterer ?? self.makeClusterer()
        self.clusterer = clusterer
        clusterer.mapView = mapView

        let newIDs = Set(markers.map(\.id))
        let staleIDs = Set(self.clusteredKeys.keys).subtracting(newIDs)
        let staleKeys = staleIDs.compactMap { self.clusteredKeys[$0] }

        if !staleKeys.isEmpty {
            clusterer.removeAll(staleKeys)
            for id in staleIDs {
                self.clusteredKeys.removeValue(forKey: id)
                self.markerTitles.removeValue(forKey: id)
                self.markerAppearances.removeValue(forKey: id)
            }
        }

        let newMarkers = markers.filter { self.clusteredKeys[$0.id] == nil }
        guard !newMarkers.isEmpty else { return }

        var keyTagMap: [TabiClusteringKey: NSObject] = [:]
        for marker in newMarkers {
            let key = TabiClusteringKey(
                markerID: marker.id,
                position: NMGLatLng(lat: marker.latitude, lng: marker.longitude)
            )
            self.clusteredKeys[marker.id] = key
            self.markerTitles[marker.id] = marker.title
            self.markerAppearances[marker.id] = (marker.icon, marker.color)
            keyTagMap[key] = marker.id as NSString
        }
        clusterer.addAll(keyTagMap)
    }

    func makeClusterer() -> NMCClusterer<TabiClusteringKey> {
        let builder = NMCBuilder<TabiClusteringKey>()
        builder.leafMarkerUpdater = TabiLeafMarkerUpdater(
            onMarkerTapped: self.onMarkerTapped,
            titleProvider: { [weak self] id in self?.markerTitles[id] },
            appearanceProvider: { [weak self] id in self?.markerAppearances[id] }
        )
        return builder.build()
    }

    func clearClusterer() {
        guard let clusterer = self.clusterer else { return }
        clusterer.clear()
        clusterer.mapView = nil
        self.clusterer = nil
        self.clusteredKeys.removeAll()
    }
}

// MARK: - TabiLeafMarkerUpdater

private final class TabiLeafMarkerUpdater: NSObject {
    private let defaultUpdater = NMCDefaultLeafMarkerUpdater()
    private let onMarkerTapped: (String) -> Void
    private let titleProvider: (String) -> String?
    private let appearanceProvider: (String) -> (icon: TabiIcon, color: TabiColor)?

    init(
        onMarkerTapped: @escaping (String) -> Void,
        titleProvider: @escaping (String) -> String?,
        appearanceProvider: @escaping (String) -> (icon: TabiIcon, color: TabiColor)?
    ) {
        self.onMarkerTapped = onMarkerTapped
        self.titleProvider = titleProvider
        self.appearanceProvider = appearanceProvider
    }
}

// MARK: - NMCLeafMarkerUpdater

extension TabiLeafMarkerUpdater: NMCLeafMarkerUpdater {
    func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        self.defaultUpdater.updateLeafMarker(info, marker)

        guard let markerID = info.tag as? String else { return }
        marker.captionText = self.titleProvider(markerID) ?? ""

        if let appearance = self.appearanceProvider(markerID) {
            // NMFMarker는 UI 오버레이라 NMCClusterer가 이 콜백을 메인 스레드에서만 호출함
            MainActor.assumeIsolated {
                marker.iconImage = TabiMapMarkerImageFactory.image(icon: appearance.icon, color: appearance.color)
            }
        }

        marker.touchHandler = { [weak self] _ in
            self?.onMarkerTapped(markerID)
            return true
        }
    }
}
