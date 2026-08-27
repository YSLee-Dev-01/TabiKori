//
//  MapView.swift
//  Presentation
//
//  Created by 이윤수 on 7/21/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import UIKit

import ComposableArchitecture
import Core
import DesignSystem
import Domain
import Resource

/// 검색 텍스트필드/언어 안내멘트의 실제 프레임을 시트 위치 계산에서 공유하기 위한 좌표공간 이름
private enum MapViewCoordinateSpace {
    static let root = "MapView.root"
}

public struct MapView: View {

    @Bindable private var store: StoreOf<MapFeature>
    @FocusState private var isSearchFieldFocused: Bool
    @Namespace private var searchFieldNamespace
    @State private var mapContainerHeight: CGFloat = 0
    @State private var topBarHeight: CGFloat = 0
    @State private var tabBarHeight: CGFloat = 0
    @State private var keyboardHeight: CGFloat = 0
    @State private var lastTappedSpotID: String?
    @State private var isPanelDragging: Bool = false
    // 검색 텍스트필드/언어 안내멘트의 실제 렌더링 하단 Y좌표(mapRoot 좌표공간 기준). topBarHeight
    // 같은 집계 높이를 거치지 않고 이 값을 직접 시트 높이 계산에 사용해, 안내멘트가 조건부로
    // 나타나는 프레임에서 시트 위치가 한 프레임 지연되어 안내멘트를 가리는 문제를 없앤다
    @State private var searchFieldBottomY: CGFloat = 0
    @State private var languageGuideBottomY: CGFloat = 0

    /// 시트 상단과 기준 뷰(안내멘트/텍스트필드) 하단 사이에 둘 여백
    private let sheetTopMargin: CGFloat = 10

    fileprivate var baseFullHeight: CGFloat { max(0, self.mapContainerHeight - self.topBarHeight) }
    fileprivate var baseHalfHeight: CGFloat { min(self.baseFullHeight, self.mapContainerHeight * 0.42) }
    fileprivate var baseCollapsedHeight: CGFloat { min(self.baseHalfHeight, 140) }
    fileprivate var isKeyboardVisible: Bool { self.keyboardHeight > 0 }

    /// 검색 중(typing) 시트 상단이 위치해야 할 실측 Y좌표. 키보드가 올라와 안내멘트가 노출된 상태라면
    /// 안내멘트 하단에서 sheetTopMargin만큼, 그렇지 않다면 검색 텍스트필드 하단에서 sheetTopMargin만큼
    /// 떨어진 위치를 가리킨다
    fileprivate var typingPanelTopY: CGFloat {
        let baseY = (self.isKeyboardVisible && self.languageGuideBottomY > 0) ? self.languageGuideBottomY : self.searchFieldBottomY
        return baseY > 0 ? baseY + self.sheetTopMargin : baseY
    }
    fileprivate var typingFullHeight: CGFloat {
        self.searchFieldBottomY > 0 ? max(0, self.mapContainerHeight - self.typingPanelTopY) : self.baseFullHeight
    }

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack(alignment: .top) {
            self.mapBackground()
                .safeAreaBar(edge: .top) {
                    self.topBar()
                }
        }
        .coordinateSpace(name: MapViewCoordinateSpace.root)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            self.mapContainerHeight = newValue
        }
        // 탭바가 실제로 차지하는 높이를 UIKit 레벨에서 직접 측정하는 프로브.
        // SwiftUI의 safeAreaInsets(.bottom)는 이 뷰의 프레임 자체가 TabView 콘텐츠 영역 경계(탭바 상단)에서
        // 이미 멈춰 있어 항상 0으로 측정되어 신뢰할 수 없었다. responder 체인을 타고 올라가 실제
        // UITabBarController를 찾아 tabBar.frame.height를 직접 읽으면 safeArea 전파 방식과 무관하게
        // 정확한 값을 얻을 수 있다
        .background(alignment: .bottom) {
            TabBarHeightReader(height: self.$tabBarHeight)
                .frame(width: 0, height: 0)
        }
        .overlay(alignment: .bottom) {
            self.searchPanelOverlay()
        }
        .animation(.tabiStandard, value: self.store.searchQuery.isEmpty)
        .animation(.tabiStandard, value: self.store.mode)
        .animation(.tabiStandard, value: self.store.showsResearchButton)
        .animation(.tabiStandard, value: self.isKeyboardVisible)
        // typingFullHeight(시트 full 높이)가 참조하는 실측값들이 서로 다른 타이밍(NotificationCenter/
        // onGeometryChange)에 갱신되며 애니메이션 컨텍스트 없이 스냅되면, 시트가 순간적으로
        // 아래로 내려갔다 다시 올라오는 것처럼 보일 수 있다. 세 값 모두 명시적으로 애니메이션에 포함시켜
        // 갱신 타이밍이 달라도 항상 같은 곡선으로 부드럽게 반영되도록 한다
        .animation(.tabiStandard, value: self.keyboardHeight)
        .animation(.tabiStandard, value: self.languageGuideBottomY)
        .animation(.tabiStandard, value: self.searchFieldBottomY)
        .onChange(of: self.store.mode) { _, mode in
            self.isSearchFieldFocused = mode == .typing
        }
        // 안내멘트가 사라지는 시점(키보드가 내려가거나 typing 모드를 벗어남)에 이전 측정값이
        // 남아 typingPanelTopY 계산에 잘못 쓰이지 않도록 즉시 초기화한다
        .onChange(of: self.store.mode == .typing && self.isKeyboardVisible) { _, isGuideVisible in
            guard isGuideVisible == false else { return }
            withAnimation(.tabiStandard) {
                self.languageGuideBottomY = 0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            print("SHEET_DEBUG keyboardWillChangeFrame isPanelDragging=\(self.isPanelDragging)"); fflush(stdout)
            guard self.isPanelDragging == false else { return }
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let screenHeight = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.screen.bounds.height }
                .first ?? self.mapContainerHeight
            self.keyboardHeight = max(0, screenHeight - frame.origin.y)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            print("SHEET_DEBUG keyboardWillHide isPanelDragging=\(self.isPanelDragging)"); fflush(stdout)
            guard self.isPanelDragging == false else { return }
            self.keyboardHeight = 0
        }
        .onAppear {
            self.store.send(.onAppear)
            // 홈 화면 검색바 경유 진입처럼 이 뷰가 mode == .typing 상태로 처음 마운트되는 경우,
            // .onChange(of: store.mode)는 마운트 이후의 "변화"에만 반응해 포커스가 걸리지 않는다.
            // 마운트 시점의 상태를 한 틱 뒤에 다시 동기화해 이 경우에도 키보드가 올라오게 한다
            DispatchQueue.main.async {
                self.isSearchFieldFocused = self.store.mode == .typing
            }
        }
        .translateSearchTask(
            pendingQuery: self.store.translateSearch.pendingTranslationQuery,
            onResult: { self.store.send(.translateSearch(.translationResultReceived($0))) },
            onFailure: { self.store.send(.translateSearch(.translationFailed)) }
        )
    }
}

// MARK: - TouristSpot View Extension

private extension TouristSpot {
    var toMapMarker: TabiMapMarker? {
        guard self.coordinate.isValid else { return nil }
        return TabiMapMarker(
            id: self.id,
            latitude: self.coordinate.latitude,
            longitude: self.coordinate.longitude,
            title: self.title.removingBracketedTags.removingHangul.truncated(to: 15),
            icon: self.contentType.icon,
            color: self.contentType.color
        )
    }
}

// MARK: - SubwayStation View Extension

private extension SubwayStation {
    /// selectStation()으로 geocode된 이후 만들어지는 TouristSpot.id("subway_\(stationCode)")와 동일한 형식을 미리 사용해
    /// 탭 직후 스크롤 위치(lastTappedSpotID)를 일관되게 유지한다
    var mapListID: String { "subway_\(self.stationCode)" }
}

// MARK: - TabBarHeightReader

/// responder 체인을 타고 올라가 실제 UITabBarController를 찾아 tabBar.frame.height를 바인딩으로 보고하는
/// 투명 프로브. SwiftUI의 safeAreaInsets는 TabView 콘텐츠 뷰 자체의 프레임이 탭바 상단에서 멈춰 있어
/// 탭바 높이를 안정적으로 알려주지 못하므로, UIKit 레벨에서 직접 측정한다
private struct TabBarHeightReader: UIViewRepresentable {
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        self.measure(from: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        self.measure(from: uiView)
    }

    private func measure(from view: UIView) {
        DispatchQueue.main.async {
            guard let tabBarController = view.findTabBarController() else { return }
            let measuredHeight = tabBarController.tabBar.frame.height
            guard measuredHeight != self.height else { return }
            self.height = measuredHeight
        }
    }
}

private extension UIView {
    /// UIHostingController가 UITabBarController의 자식으로 붙는 SwiftUI 계층에서는 view 계층이 아닌
    /// responder 체인(next)을 타고 올라가야 UITabBarController를 안정적으로 찾을 수 있다
    func findTabBarController() -> UITabBarController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let tabBarController = current as? UITabBarController {
                return tabBarController
            }
            responder = current.next
        }
        return nil
    }
}

// MARK: - MapSearchLoadingDots

private struct MapSearchLoadingDots: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { index in
                Circle()
                    .fill(TabiColor.tabiPrimary)
                    .frame(width: 5, height: 5)
                    .opacity(self.isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: self.isAnimating
                    )
            }
        }
        .onAppear {
            self.isAnimating = true
        }
    }
}

// MARK: - View

private extension MapView {
    func mapBackground() -> some View {
        ZStack {
            Rectangle()
                .fill(TabiColor.tabiBackground)
                .ignoresSafeArea()

            Group {
                if self.store.hasResolvedInitialCenter {
                    TabiMapView(
                        centerLatitude: self.store.centerLatitude,
                        centerLongitude: self.store.centerLongitude,
                        markers: self.store.searchResults.compactMap(\.toMapMarker),
                        isClusteringEnabled: false,
                        showsLocationButton: self.store.showsUserLocation,
                        followsUserLocation: false,
                        bottomContentInset: self.tabBarHeight,
                        boundsFitToken: self.store.searchResultFitToken,
                        onMapTapped: { _, _ in },
                        onMarkerTapped: { id in
                            guard let spot = self.store.searchResults.first(where: { $0.id == id }) else { return }
                            self.selectSearchResult(spot)
                        },
                        onMapDragged: {
                            withAnimation(.tabiStandard) {
                                _ = self.store.send(.mapDragged)
                            }
                        },
                        onCameraIdle: { latitude, longitude, radiusMeters in
                            self.store.send(.mapCenterChanged(Coordinate(latitude: latitude, longitude: longitude), radiusMeters: radiusMeters))
                        }
                    )
                    .ignoresSafeArea()
                } else {
                    ProgressView()
                }
            }
        }
    }

    func recentSearchContent() -> some View {
        Group {
            if self.store.recentSearches.isEmpty {
                MapRecentSearchPlaceholderView(keyboardHeight: self.keyboardHeight)
            } else {
                MapRecentSearchListView(
                    histories: self.store.recentSearches,
                    onTapped: { history in
                        self.store.send(.recentSearchTapped(history))
                    },
                    onDeleteTapped: { history in
                        self.store.send(.recentSearchDeleteTapped(history))
                    }
                )
                // full 단계에서 시트가 SafeArea 하단까지 붙어 탭바 뒤로 이어지므로,
                // 리스트 마지막 항목이 탭바에 가려지지 않도록 탭바 높이만큼 하단 여백을 둔다
                .contentMargins(.bottom, self.tabBarHeight, for: .scrollContent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    func searchPanelOverlay() -> some View {
        if self.store.mode == .typing || self.store.mode == .result {
            self.searchPanel()
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    func searchPanel() -> some View {
        let _ = { print("SHEET_DEBUG mode=\(self.store.mode) stage=\(self.store.panelStage) kbVisible=\(self.isKeyboardVisible) kbH=\(self.keyboardHeight) isPanelDragging=\(self.isPanelDragging) mapH=\(self.mapContainerHeight) topBarH=\(self.topBarHeight) fieldBottomY=\(self.searchFieldBottomY) guideBottomY=\(self.languageGuideBottomY) topY=\(self.typingPanelTopY) fullH=\(self.typingFullHeight) baseFullH=\(self.baseFullHeight)"); fflush(stdout) }()
        return MapSearchPanelView(
            stage: self.store.panelStage,
            collapsedHeight: self.baseCollapsedHeight,
            halfHeight: self.baseHalfHeight,
            fullHeight: self.store.mode == .typing ? self.typingFullHeight : self.baseFullHeight,
            tabBarHeight: self.tabBarHeight,
            onStageChanged: { stage in self.store.send(.panelDragEnded(stage)) },
            onDismiss: { self.cancelSearch() },
            onDragStarted: {
                print("SHEET_DEBUG onDragStarted"); fflush(stdout)
                self.isPanelDragging = true
                self.isSearchFieldFocused = false
            },
            onDragEnded: {
                print("SHEET_DEBUG onDragEnded kbH=\(self.keyboardHeight)"); fflush(stdout)
                self.isPanelDragging = false
            }
        ) {
            if self.store.mode == .typing {
                self.recentSearchContent()
            } else {
                self.searchResultContent()
            }
        }
    }

    @ViewBuilder
    func searchResultContent() -> some View {
        if self.store.searchQuery.isEmpty && self.store.isCategorySearchActive == false {
            self.searchGuideState()
        } else if self.store.isSearchLoading {
            self.searchResultSkeletonList()
        } else if self.store.subwayResults.isEmpty && self.store.searchResults.isEmpty {
            self.searchResultEmptyState()
        } else {
            self.searchResultList()
        }
    }

    func searchGuideState() -> some View {
        TabiEmptyState(
            systemImageName: "magnifyingglass",
            description: Strings.Map.searchEmptyDescription
        )
    }

    func searchResultEmptyState() -> some View {
        VStack(spacing: 0) {
            TabiEmptyState(
                systemImageName: "mappin.slash",
                title: Strings.Map.searchResultEmptyTitle,
                description: Strings.Map.searchResultEmptyDescription
            )
            // 가장 작은 collapsed 단계에서는 문구가 들어갈 공간이 부족해 노출하지 않는다
            if self.store.panelStage != .collapsed {
                self.languageGuideBadge()
                    .padding(.horizontal, 20)
                    // full 단계에서 시트 박스 자체가 탭바 높이만큼 화면 밖으로 bleed되므로,
                    // 콘텐츠 하단에 위치한 이 안내 문구가 탭바 뒤로 가려지지 않도록 동일하게 보정한다
                    .padding(.bottom, 8 + self.tabBarHeight)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func searchResultSkeletonList() -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0 ..< 6, id: \.self) { index in
                    if index > 0 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                    self.searchResultSkeletonRow()
                }
            }
            // full 단계에서 시트가 SafeArea 하단까지 붙어 탭바 뒤로 이어지므로,
            // 리스트 마지막 항목이 탭바에 가려지지 않도록 탭바 높이만큼 하단 여백을 둔다
            .contentMargins(.bottom, self.tabBarHeight, for: .scrollContent)
        }
        .scrollDisabled(true)
        .allowsHitTesting(false)
    }

    func searchResultSkeletonRow() -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: .tabiRadiusMd)
                .fill(TabiColor.tabiBorder.opacity(0.3))
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(TabiColor.tabiBorder.opacity(0.3))
                    .frame(width: 120, height: 16)
                Capsule()
                    .fill(TabiColor.tabiBorder.opacity(0.3))
                    .frame(width: 55, height: 20)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(TabiColor.tabiBorder.opacity(0.2))
                .frame(width: 40, height: 14)
        }
        .padding(16)
    }

    func searchResultList() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(self.store.subwayResults.enumerated()), id: \.element.stationCode) { index, station in
                        if index > 0 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                        MapSubwayStationRowView(station: station) {
                            self.selectSubwayStation(station)
                        }
                        .id(station.mapListID)
                    }

                    if self.store.subwayResults.isEmpty == false, self.store.searchResults.isEmpty == false {
                        Divider()
                            .padding(.horizontal, 16)
                    }

                    ForEach(Array(self.store.searchResults.enumerated()), id: \.element.id) { index, spot in
                        if index > 0 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                        MapSearchResultRowView(spot: spot) {
                            self.selectSearchResult(spot)
                        }
                        .id(spot.id)
                        .onAppear {
                            guard spot.id == self.store.searchResults.last?.id else { return }
                            self.store.send(.searchNextPageTriggered)
                        }
                    }

                    if self.store.isSearchNextPageLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
            }
            // full 단계에서 시트가 SafeArea 하단까지 붙어 탭바 뒤로 이어지므로,
            // 리스트 마지막 항목이 탭바에 가려지지 않도록 탭바 높이만큼 하단 여백을 둔다
            .contentMargins(.bottom, self.tabBarHeight, for: .scrollContent)
            .onAppear {
                guard let id = self.lastTappedSpotID else { return }
                // sheet가 재생성되는 시점에 동기 scrollTo를 호출하면 "state changes lost" 레이스 컨디션이 발생해 한 틱 지연
                DispatchQueue.main.async {
                    proxy.scrollTo(id, anchor: .top)
                }
            }
        }
    }

    func topBar() -> some View {
        VStack(spacing: 12) {
            TabiNavigationBar(
                title: Strings.Tabbar.map
            )

            HStack(spacing: 12) {
                switch self.store.mode {
                case .map:
                    TabiSearchField(
                        placeholder: Strings.Map.searchPlaceholder,
                        style: .glass
                    ) {
                        withAnimation(.tabiStandard) {
                            _ = self.store.send(.searchFieldTapped)
                        }
                    }
                    .matchedGeometryEffect(id: "mapSearchField", in: self.searchFieldNamespace)

                case .typing:
                    TabiSearchField(
                        placeholder: Strings.Map.searchPlaceholder,
                        text: self.$store.searchQuery,
                        focus: self.$isSearchFieldFocused,
                        style: .glass,
                        onSubmit: {
                            self.lastTappedSpotID = nil
                            self.store.send(.searchSubmitted)
                        }
                    )
                    .matchedGeometryEffect(id: "mapSearchField", in: self.searchFieldNamespace)

                    if self.store.showsTranslateSearchButton {
                        self.translateSearchButton()
                    }

                    self.searchCancelButton()

                case .result:
                    TabiSearchField(
                        placeholder: self.store.activeCategoryLabel ?? (self.store.searchQuery.isEmpty ? Strings.Map.searchPlaceholder : self.store.searchQuery),
                        style: .glass
                    ) {
                        self.store.send(.searchFieldTapped)
                    }
                    .matchedGeometryEffect(id: "mapSearchField", in: self.searchFieldNamespace)

                    self.searchCancelButton()
                }
            }
            .padding(.horizontal, 20)
            // 검색 텍스트필드 행의 실제 하단 Y좌표를 직접 측정한다. 키보드가 내려가 있을 때
            // 시트 상단이 이 위치 바로 아래에 오도록 하는 기준값으로 쓰인다
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.frame(in: .named(MapViewCoordinateSpace.root)).maxY
            } action: { newValue in
                self.searchFieldBottomY = newValue
            }

            // 키보드가 실제로 올라와 검색어를 입력 중일 때만 안내를 노출한다
            if self.store.mode == .typing && self.isKeyboardVisible {
                self.languageGuideBadge()
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                    // 안내멘트의 실제 하단 Y좌표를 직접 측정한다. 키보드가 올라와 있을 때
                    // 시트 상단이 이 위치 바로 아래(안내멘트를 가리지 않고 바로 이어지는 위치)에 오도록 하는 기준값으로 쓰인다
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .named(MapViewCoordinateSpace.root)).maxY
                    } action: { newValue in
                        self.languageGuideBottomY = newValue
                    }
            }

            if self.store.mode == .map {
                self.categoryChips()
            }

            if self.store.mode == .result && self.store.isSearchLoading {
                self.searchLoadingIndicator()
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else if self.store.showsResearchButton {
                self.researchButton()
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.bottom, 16)
        .background {
            LinearGradient(
                colors: [
                    Color.getTabiColor(.tabiBackground),
                    Color.getTabiColor(.tabiBackground).opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.container, edges: .top)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            // 새로고침 버튼 등 topBar 구성 요소가 트랜지션되며 높이가 바뀔 때, 이 값에 의존하는
            // 시트 최대 높이(baseFullHeight)가 같은 곡선으로 함께 애니메이션되도록 명시적으로 감싼다.
            // 감싸지 않으면 이 값의 변경이 애니메이션 컨텍스트 없이 그대로 반영되어 시트 높이가
            // topBar 트랜지션과 어긋나게 스냅되거나 갱신이 지연되어 보일 수 있다
            withAnimation(.tabiStandard) {
                self.topBarHeight = newValue
            }
        }
    }

    func researchButton() -> some View {
        HStack {
            Spacer()
            TabiButton(
                Strings.Map.researchAtCurrentLocation,
                style: .glass(on: .surface)
            ) {
                self.store.send(.researchAtCurrentLocationTapped)
            }
            Spacer()
        }
    }

    func searchLoadingIndicator() -> some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                TabiLabel(title: Strings.Map.loading, style: .bodyMBold, color: .tabiPrimary)
                MapSearchLoadingDots()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .glassEffect(.regular, in: .rect(cornerRadius: .tabiRadiusSm))
            Spacer()
        }
    }

    func languageGuideBadge() -> some View {
        HStack {
            Spacer(minLength: 0)
            TabiLabel(
                title: Strings.Map.searchLanguageGuide,
                style: .captionM,
                color: .tabiTextSecondary,
                alignment: .center
            )
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .glassEffect(.regular, in: .rect(cornerRadius: .tabiRadiusSm))
            Spacer(minLength: 0)
        }
    }

    func searchCancelButton() -> some View {
        Button {
            self.cancelSearch()
        } label: {
            TabiLabel(title: Strings.Map.searchCancel, style: .bodyM, color: .tabiTextSecondary)
        }
    }

    func translateSearchButton() -> some View {
        TabiCircleIconButton(systemName: TabiIcon.translate.rawValue) {
            self.store.send(.translateSearch(.translateButtonRequested(query: self.store.searchQuery)))
        }
        .accessibilityLabel(Strings.Map.translateSearchButtonAccessibilityLabel)
    }

    func categoryChips() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(CategoryType.allItems, id: \.self) { item in
                    self.categoryChip(item)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    func categoryChip(_ item: CategoryType) -> some View {
        Button {
            withAnimation(.tabiStandard) {
                _ = self.store.send(.categorySelected(item, coordinate: nil))
            }
        } label: {
            HStack(spacing: 6) {
                Image(item.icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(item.color)

                TabiLabel(title: item.label, style: .captionMBold, color: item.color)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(TabiColor.tabiSurface)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(TabiColor.tabiBorder, lineWidth: 1)
            }
        }
        .buttonStyle(TabiPressStyle())
    }

    func selectSearchResult(_ spot: TouristSpot) {
        self.lastTappedSpotID = spot.id
        self.store.send(.searchResultTapped(spot))
    }

    func selectSubwayStation(_ station: SubwayStation) {
        self.lastTappedSpotID = station.mapListID
        self.store.send(.subwayStationTapped(station))
    }
}

// MARK: - Method

private extension MapView {
    func cancelSearch() {
        self.lastTappedSpotID = nil
        self.isSearchFieldFocused = false
        withAnimation(.tabiStandard) {
            _ = self.store.send(.searchCancelTapped)
        }
    }
}
