//
//  TabiMapView+Coordinator.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/20/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

@preconcurrency import NMapsMap

import Core
import Resource

extension TabiMapView {
    public final class Coordinator: NSObject {
        private let onMapTapped: (Double, Double) -> Void
        private let onMarkerTapped: (String) -> Void
        private let onMapDragged: () -> Void
        private let onCameraIdle: (Double, Double, Double) -> Void
        private var markerCache: [String: NMFMarker] = [:]
        private var clusterer: NMCClusterer<TabiClusteringKey>?
        private var clusteredKeys: [String: TabiClusteringKey] = [:]
        private var markerTitles: [String: String] = [:]
        private var markerAppearances: [String: (icon: TabiIcon, color: TabiColor, index: Int?)] = [:]
        private var polylineOverlay: NMFPolylineOverlay?
        private var polylineMarkers: [TabiMapMarker] = []
        private var lastAppliedFitToken: Int?
        private let singleMarkerFitZoomLevel: Double = 15
        private let boundsFitPadding: CGFloat = 60
        // makeUIView 시점에는 NMFNaverMapView가 아직 SwiftUI 레이아웃을 거치지 않아 frame이 .zero일 수 있음.
        // fit 계산이 유효한 프레임을 전제로 하므로, 프레임이 잡힐 때까지 런루프 단위로 재시도할 최대 횟수
        private let boundsFitMaxRetryCount: Int = 10
        // MapView 검색 패널 등장 애니메이션(.tabiStandard = Animation.smooth, 기본 duration 0.5초)과
        // 카메라 이동 애니메이션 길이를 맞춰, 시트가 다 올라오기 전에 지도가 먼저 이동해버리는 것을 방지
        private let boundsFitAnimationDuration: TimeInterval = 0.5

        init(
            onMapTapped: @escaping (Double, Double) -> Void,
            onMarkerTapped: @escaping (String) -> Void,
            onMapDragged: @escaping () -> Void,
            onCameraIdle: @escaping (Double, Double, Double) -> Void
        ) {
            self.onMapTapped = onMapTapped
            self.onMarkerTapped = onMarkerTapped
            self.onMapDragged = onMapDragged
            self.onCameraIdle = onCameraIdle
        }
    }
}

// MARK: - Sendable

// Coordinator는 UIViewRepresentable의 makeUIView/updateUIView(메인 액터)와 NMapsMap 델리게이트 콜백
// (메인 스레드에서만 호출됨)에서만 사용되므로 메인 스레드 단일 접근이 보장됨.
// applyBoundsFitIfNeeded(...)의 프레임 재시도가 DispatchQueue.main.async로 self를 넘겨야 해서 채택
extension TabiMapView.Coordinator: @unchecked Sendable {}

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

    public func mapViewCameraIdle(_ mapView: NMFMapView) {
        let target = mapView.cameraPosition.target
        let visibleRadiusMeters = target.distance(to: mapView.contentBounds.northEast)
        self.onCameraIdle(target.lat, target.lng, visibleRadiusMeters)
    }
}

// MARK: - Marker Sync

extension TabiMapView.Coordinator {
    func sync(markers: [TabiMapMarker], isClusteringEnabled: Bool, boundsFitToken: Int, on mapView: NMFMapView) {
        if isClusteringEnabled {
            self.clearPlainMarkers()
            self.syncClusteredMarkers(markers, on: mapView)
            // 클러스터링 모드에서는 마커 좌표가 확정되지 않은 상태로 뭉쳐 보이므로 연결선을 그리지 않음
            self.clearPolyline()
        } else {
            self.clearClusterer()
            self.syncPlainMarkers(markers, on: mapView)
            self.syncPolyline(markers, on: mapView)
        }

        self.applyBoundsFitIfNeeded(token: boundsFitToken, markers: markers, on: mapView)
    }
}

// MARK: - Method

private extension TabiMapView.Coordinator {
    static let markerSize: CGFloat = 30
    static let captionTextSize: CGFloat = 10
    static let polylineWidth: CGFloat = 3

    func syncPlainMarkers(_ markers: [TabiMapMarker], on mapView: NMFMapView) {
        let newIDs = Set(markers.map(\.id))
        let staleIDs = Set(self.markerCache.keys).subtracting(newIDs)

        for id in staleIDs {
            self.markerCache[id]?.mapView = nil
            self.markerCache.removeValue(forKey: id)
            self.markerAppearances.removeValue(forKey: id)
        }

        for marker in markers {
            if let existingMarker = self.markerCache[marker.id] {
                let previousAppearance = self.markerAppearances[marker.id]
                guard previousAppearance?.icon != marker.icon
                    || previousAppearance?.color != marker.color
                    || previousAppearance?.index != marker.index
                else { continue }

                self.markerAppearances[marker.id] = (marker.icon, marker.color, marker.index)
                // NMFMarker는 UI 오버레이라 sync(...)가 호출되는 makeUIView/updateUIView(메인 액터)에서만 안전함
                MainActor.assumeIsolated {
                    existingMarker.iconImage = TabiMapMarkerImageFactory.image(icon: marker.icon, color: marker.color, index: marker.index)
                }
                continue
            }

            let nmfMarker = NMFMarker()
            nmfMarker.position = NMGLatLng(lat: marker.latitude, lng: marker.longitude)
            nmfMarker.width = Self.markerSize
            nmfMarker.height = Self.markerSize
            self.markerAppearances[marker.id] = (marker.icon, marker.color, marker.index)
            MainActor.assumeIsolated {
                nmfMarker.iconImage = TabiMapMarkerImageFactory.image(icon: marker.icon, color: marker.color, index: marker.index)
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
        self.markerAppearances.removeAll()
    }

    func syncPolyline(_ markers: [TabiMapMarker], on mapView: NMFMapView) {
        let orderedMarkers = markers.sorted { ($0.index ?? .max) < ($1.index ?? .max) }

        guard orderedMarkers.count >= 2 else {
            self.clearPolyline()
            return
        }
        guard orderedMarkers != self.polylineMarkers else { return }
        self.polylineMarkers = orderedMarkers

        let coords = orderedMarkers.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) }
        guard let overlay = NMFPolylineOverlay(coords) else {
            self.clearPolyline()
            return
        }
        overlay.width = Self.polylineWidth
        overlay.color = UIColor(Color.getTabiColor(.tabiPrimary))
        // NMFPolylineOverlay.pattern의 실제 기본값은 실선이 아니라 NMFDefaultLinePattern(@[@2, @1], 2pt 실선 + 1pt 공백)이므로
        // 별도 설정 없이 생성하면 점선으로 보임. 헤더 주석상 빈 배열을 지정하면 실선으로 그려짐(NMFPolylineOverlay.h 참고)
        overlay.pattern = []
        overlay.mapView = mapView

        self.polylineOverlay?.mapView = nil
        self.polylineOverlay = overlay
    }

    func clearPolyline() {
        self.polylineOverlay?.mapView = nil
        self.polylineOverlay = nil
        self.polylineMarkers.removeAll()
    }

    func applyBoundsFitIfNeeded(
        token: Int,
        markers: [TabiMapMarker],
        on mapView: NMFMapView,
        retryCount: Int = 0,
        previousBoundsSize: CGSize? = nil
    ) {
        guard token != self.lastAppliedFitToken else { return }
        guard markers.isEmpty == false else {
            self.lastAppliedFitToken = token
            return
        }

        // makeUIView 시점의 NMFNaverMapView는 아직 SwiftUI 레이아웃을 거치지 않아 bounds가 .zero일 수 있음.
        // 뿐만 아니라 bounds가 0이 아니게 된 첫 시점도 SwiftUI/UIHostingController의 중간(transient) 레이아웃
        // 패스일 수 있어(최종 확정 크기보다 작은 값), 그 값을 그대로 fit 계산에 쓰면 카메라가 실제보다
        // 좁은 영역 기준으로 확대되어 일부 스팟만 보이는 문제가 생김. 그래서 bounds가 0이 아닐 뿐 아니라
        // 연속된 두 번의 런루프에서 동일한 값으로 안정화됐을 때만 fit을 계산해 적용함
        // NMFMapView는 UIView(→ UIResponder)를 상속해 bounds 접근이 @MainActor로 격리됨. sync(...)는
        // UIViewRepresentable의 makeUIView/updateUIView(둘 다 메인 액터)에서만 호출되므로 안전함
        let currentBoundsSize = MainActor.assumeIsolated { mapView.bounds.size }
        let hasValidBounds = currentBoundsSize.width > 0 && currentBoundsSize.height > 0
        let isStable = hasValidBounds && currentBoundsSize == previousBoundsSize
        guard isStable else {
            guard retryCount < self.boundsFitMaxRetryCount else {
                AppLogger.view.log(.error, "지도 bounds fit 재시도 초과: mapView 프레임이 안정화되지 않음(마지막 크기: \(currentBoundsSize))")
                self.lastAppliedFitToken = token
                return
            }
            DispatchQueue.main.async { [weak self, weak mapView] in
                guard let self, let mapView else { return }
                self.applyBoundsFitIfNeeded(
                    token: token,
                    markers: markers,
                    on: mapView,
                    retryCount: retryCount + 1,
                    previousBoundsSize: hasValidBounds ? currentBoundsSize : nil
                )
            }
            return
        }

        self.lastAppliedFitToken = token

        let singleMarkerFitZoomLevel = self.singleMarkerFitZoomLevel
        let boundsFitPadding = self.boundsFitPadding
        let boundsFitAnimationDuration = self.boundsFitAnimationDuration

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
            cameraUpdate.animation = .easeOut
            cameraUpdate.animationDuration = boundsFitAnimationDuration
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
            self.markerAppearances[marker.id] = (marker.icon, marker.color, marker.index)
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
    private let appearanceProvider: (String) -> (icon: TabiIcon, color: TabiColor, index: Int?)?

    init(
        onMarkerTapped: @escaping (String) -> Void,
        titleProvider: @escaping (String) -> String?,
        appearanceProvider: @escaping (String) -> (icon: TabiIcon, color: TabiColor, index: Int?)?
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
                marker.iconImage = TabiMapMarkerImageFactory.image(icon: appearance.icon, color: appearance.color, index: appearance.index)
            }
        }

        marker.touchHandler = { [weak self] _ in
            self?.onMarkerTapped(markerID)
            return true
        }
    }
}
