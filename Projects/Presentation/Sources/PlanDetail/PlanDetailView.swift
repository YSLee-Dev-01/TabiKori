//
//  PlanDetailView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

/// 일정 상세 화면. NavigationBar와 일자 선택 탭, 선택된 날짜의 스팟 목록(타임라인 + 스와이프 삭제)을 표시한다
public struct PlanDetailView: View {

    @Bindable private var store: StoreOf<PlanDetailFeature>

    @Environment(\.dismiss) private var dismiss

    @State private var isMovingForward: Bool = true
    @State private var scrolledDayIndex: Int?

    public init(store: StoreOf<PlanDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if self.store.isFullOverview == false {
                self.dayTabScroll(plan: self.store.plan)
            }

            if self.store.isFullOverview {
                // 안쪽 VStack이 전체보기 진입/이탈(모드 전환)의 제거·삽입 단위를 담당해 페이드만 적용하고,
                // 지도의 자체 transition(상단 슬라이드)은 같은 모드 안에서 visibleDayIndex만 바뀔 때 별도로 적용된다
                VStack(alignment: .leading, spacing: 10) {
                    self.mapSection()
                        .id(self.mapSectionIdentity(dayIndex: self.store.visibleDayIndex))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    self.fullOverviewList(plan: self.store.plan)
                }
                .transition(.opacity)
            } else {
                // 안쪽 VStack이 일자 탐색(selectedDayIndex)만의 제거·삽입 단위를 담당해 좌우 슬라이드를 적용하고,
                // 모드 전환으로 이 가지 전체가 사라질 때는 바깥 VStack의 페이드만 적용된다
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 10) {
                        self.dayHeader(plan: self.store.plan)

                        self.mapSection()

                        self.spotList()
                    }
                    .id(self.store.selectedDayIndex)
                    .transition(self.dayTransition)
                }
                .transition(.opacity)
            }

            if self.store.isEditing {
                self.editActionButtons()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.tabiStandard, value: self.store.selectedDayIndex)
        .animation(.tabiStandard, value: self.store.isEditing)
        .animation(.tabiStandard, value: self.store.isFullOverview)
        .animation(.tabiStandard, value: self.store.visibleDayIndex)
        .navigationTitle("\(self.store.plan.title) · \(self.store.plan.displayRegionTitle)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .tint(Color.getTabiColor(.tabiPrimary))
            }
            if self.store.isEditing == false {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.store.send(.fullOverviewToggleTapped)
                    } label: {
                        Image(systemName: self.store.isFullOverview ? "rectangle.grid.1x2.fill" : "rectangle.grid.1x2")
                    }
                    .tint(Color.getTabiColor(.tabiPrimary))
                    .accessibilityLabel(
                        self.store.isFullOverview ? Strings.Plan.dayOverviewToggleTitle : Strings.Plan.fullOverviewToggleTitle
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(Strings.Plan.editMenuTitle) {
                            self.store.send(.editButtonTapped)
                        }
                        .disabled(self.store.isFullOverview)
                        Button(Strings.Plan.planEditMenuTitle) {
                            self.store.send(.planEditMenuButtonTapped)
                        }
                        if let shareFileURL = self.store.shareFileURL {
                            ShareLink(item: shareFileURL) {
                                Text(Strings.Plan.exportMenuTitle)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .tint(Color.getTabiColor(.tabiPrimary))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .interactivePopGestureEnabled(true)
        .sheet(item: self.$store.scope(state: \.addSpotState, action: \.addSpot)) { store in
            PlanDetailAddSpotView(store: store)
        }
        .sheet(item: self.$store.scope(state: \.editPlanState, action: \.editPlan)) { store in
            PlanDetailEditView(store: store)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            self.store.send(.onAppear)
        }
        .onChange(of: self.store.isFullOverview) { _, isFullOverview in
            guard isFullOverview else { return }
            self.scrolledDayIndex = self.store.visibleDayIndex
        }
    }
}

// MARK: - DayHeaderOffsetPreferenceKey

private struct DayHeaderOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

// MARK: - View

private extension PlanDetailView {
    static let fullOverviewScrollSpace = "PlanDetailFullOverviewScroll"
    static let dayHeaderVisibilityThreshold: CGFloat = 1

    func dayTabScroll(plan: TravelPlan) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(plan.dayDates.enumerated()), id: \.offset) { offset, _ in
                    TabiChip(
                        Strings.Plan.dayChipTitle(offset + 1),
                        isSelected: self.store.selectedDayIndex == offset
                    ) {
                        self.handleDayChipTapped(offset)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .padding(.top, 20)
        .disabled(self.store.isEditing)
    }

    func handleDayChipTapped(_ offset: Int) {
        guard offset != self.store.selectedDayIndex else { return }
        self.isMovingForward = offset >= self.store.selectedDayIndex
        // 방향 플래그 변경과 selectedDayIndex 변경이 같은 렌더 프레임에서 처리되면
        // 사라지는 뷰의 removal transition이 직전 프레임의 방향을 그대로 사용해버림.
        // DispatchQueue.main.async는 같은 화면 갱신 프레임 안에서 실행될 수 있어
        // 이를 보장하지 못하므로, 실제 프레임 경계(CADisplayLink)를 기다린 뒤 전송
        _ = PlanDetailNextFrameTrigger { [store = self.store] in
            store.send(.dayButtonTapped(index: offset))
        }
    }

    func dayHeader(plan: TravelPlan) -> some View {
        Group {
            if let dateTitle = self.selectedDayDateTitle(plan: plan) {
                PlanDetailDayHeader(
                    dateTitle: dateTitle,
                    spotCountTitle: self.spotCountTitle,
                    onTravelItemsTapped: { self.store.send(.travelItemsButtonTapped) }
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
    }

    var dayTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: self.isMovingForward ? .trailing : .leading),
            removal: .move(edge: self.isMovingForward ? .leading : .trailing)
        )
    }

    var selectedDayMarkers: [TabiMapMarker] {
        self.store.mapMarkerSpots.enumerated().compactMap { offset, spot in
            spot.toMapMarker(index: offset + 1)
        }
    }

    @ViewBuilder
    func mapSection() -> some View {
        if self.selectedDayMarkers.isEmpty {
            PlanDetailMapEmptyState()
        } else {
            PlanDetailMapSection(markers: self.selectedDayMarkers, fitToken: self.store.dayMapFitToken)
        }
    }

    /// 스팟이 없는 일자끼리 세션이 넘어갈 때는 지도 영역이 항상 동일한 빈 상태이므로,
    /// 굳이 sameness를 깨고 애니메이션을 재생하지 않도록 빈 상태끼리는 같은 identity(-1)를 공유한다
    func mapSectionIdentity(dayIndex: Int) -> Int {
        self.selectedDayMarkers.isEmpty ? -1 : dayIndex
    }

    func selectedDayDateTitle(plan: TravelPlan) -> String? {
        self.dayDateTitle(plan: plan, dayIndex: self.store.selectedDayIndex)
    }

    func dayDateTitle(plan: TravelPlan, dayIndex: Int) -> String? {
        guard plan.dayDates.indices.contains(dayIndex) else { return nil }
        return plan.dayDates[dayIndex].planDayHeaderTitle
    }

    // Store는 @dynamicMemberLookup으로 State의 프로퍼티(KeyPath)만 노출하므로,
    // State.spots(forDay:) 같은 파라미터를 받는 메서드는 store를 통해 직접 호출할 수 없어 View에서 동일 로직을 사용한다
    func spots(forDay dayIndex: Int) -> [TravelPlanDetailSpot] {
        guard let spots = self.store.travelPlanDetail?.spots else { return [] }
        return spots
            .filter { $0.dayIndex == dayIndex }
            .sorted { $0.order < $1.order }
    }

    var spotCountTitle: String {
        Self.spotCountTitle(count: self.store.displayedSpots.count)
    }

    static func spotCountTitle(count: Int) -> String {
        count == 0 ? Strings.Plan.spotCountZero : Strings.Plan.spotCountTitle(count)
    }

    func spotList() -> some View {
        List {
            if self.store.displayedSpots.isEmpty {
                PlanDetailSpotEmptyState()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            } else {
                let spots = self.store.displayedSpots
                ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                    PlanDetailSpotRow(
                        spot: spot,
                        index: index + 1,
                        isFirst: index == 0,
                        isLast: index == spots.count - 1,
                        isEditing: self.store.isEditing
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard self.store.isEditing == false else { return }
                        self.store.send(.spotRowTapped(spot))
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if self.store.isEditing == false {
                            Button(role: .destructive) {
                                self.store.send(.spotDeleteButtonTapped(id: spot.id))
                            } label: {
                                Text(Strings.Common.delete)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    self.store.send(.spotDeletedInEditMode(at: indexSet))
                }
                .onMove { source, destination in
                    self.store.send(.spotMovedInEditMode(source: source, destination: destination))
                }
            }

            if self.store.isEditing == false {
                PlanDetailAddSpotButton {
                    self.store.send(.addSpotButtonTapped)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(self.store.isEditing ? .active : .inactive))
    }

    /// 모든 일자를 세션(Section)으로 구분해 하나의 스크롤 뷰에 표시한다.
    /// `scrollPosition(id:)`은 전체보기 진입 시 이전에 보던 일자로 프로그래매틱 스크롤하는 데만 쓰고,
    /// 실제 스크롤 중 최상단에 보이는 세션 추적은 `List` Section 단위로는 read-back이 보장되지 않아
    /// 각 헤더의 위치를 GeometryReader로 직접 측정해 판단한다.
    /// 마지막 일자의 스팟이 적으면 그 아래로 스크롤할 콘텐츠가 부족해 헤더가 상단 임계선까지 올라오지 못해
    /// 마지막 일자가 세션 추적에 걸리지 않는 문제가 있어, `onScrollGeometryChange`로 스크롤이 바닥에
    /// 닿았는지를 직접 감지해 그 경우 헤더 임계값 판정과 무관하게 마지막 일자를 강제로 선택한다
    func fullOverviewList(plan: TravelPlan) -> some View {
        List {
            ForEach(Array(plan.dayDates.indices), id: \.self) { dayIndex in
                let spots = self.spots(forDay: dayIndex)
                Section {
                    if spots.isEmpty {
                        PlanDetailSpotEmptyState()
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    } else {
                        ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                            PlanDetailSpotRow(
                                spot: spot,
                                index: index + 1,
                                isFirst: index == 0,
                                isLast: index == spots.count - 1,
                                isEditing: false
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.store.send(.spotRowTapped(spot))
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                        }
                    }
                } header: {
                    if let dateTitle = self.dayDateTitle(plan: plan, dayIndex: dayIndex) {
                        PlanDetailDayHeader(
                            dateTitle: dateTitle,
                            spotCountTitle: Self.spotCountTitle(count: spots.count)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        .listRowInsets(EdgeInsets())
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: DayHeaderOffsetPreferenceKey.self,
                                    value: [dayIndex: proxy.frame(in: .named(Self.fullOverviewScrollSpace)).minY]
                                )
                            }
                        )
                    }
                }
                .id(dayIndex)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.bottom, 32, for: .scrollContent)
        .coordinateSpace(name: Self.fullOverviewScrollSpace)
        .scrollPosition(id: self.$scrolledDayIndex, anchor: .top)
        .onPreferenceChange(DayHeaderOffsetPreferenceKey.self) { offsets in
            self.handleDayHeaderOffsetsChanged(offsets)
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            self.isScrollAtBottom(geometry)
        } action: { _, isAtBottom in
            guard isAtBottom, let lastDayIndex = plan.dayDates.indices.last else { return }
            self.store.send(.visibleDayIndexChanged(lastDayIndex))
        }
    }

    /// 상단 임계값을 통과한(스크롤된) 헤더 중 가장 아래쪽(가장 최근에 통과한) 일자를 현재 보이는 세션으로 판단한다.
    /// 아직 어떤 헤더도 임계값을 통과하지 않은 초기 상태에서는 가장 위에 있는(첫) 일자를 사용한다
    func handleDayHeaderOffsetsChanged(_ offsets: [Int: CGFloat]) {
        let passedHeaders = offsets.filter { $0.value <= Self.dayHeaderVisibilityThreshold }
        let visibleDay = passedHeaders.max { $0.value < $1.value }?.key
            ?? offsets.min { $0.value < $1.value }?.key
        guard let visibleDay else { return }
        self.store.send(.visibleDayIndexChanged(visibleDay))
    }

    /// 실제로 스크롤 가능한 콘텐츠가 있는 상태에서, 스크롤이 최대치(바닥)에 도달했는지 판단한다.
    /// 콘텐츠가 뷰포트보다 짧아 애초에 스크롤이 불가능한 경우(초기 offset이 곧 최대 offset)는
    /// 제외해, 첫 일자가 기본으로 보이는 초기 상태를 마지막 일자로 잘못 덮어쓰지 않게 한다
    func isScrollAtBottom(_ geometry: ScrollGeometry) -> Bool {
        let maxOffsetY = geometry.contentSize.height + geometry.contentInsets.bottom - geometry.containerSize.height
        guard maxOffsetY > Self.dayHeaderVisibilityThreshold else { return false }
        return geometry.contentOffset.y >= maxOffsetY - Self.dayHeaderVisibilityThreshold
    }

    func editActionButtons() -> some View {
        HStack(spacing: 12) {
            TabiButton(Strings.Plan.editCancelButton, style: .ghost, isExpanded: true) {
                self.store.send(.editCancelButtonTapped)
            }
            TabiButton(Strings.Plan.editSaveButton, style: .primary, isExpanded: true, isLoading: self.store.isSaving) {
                self.store.send(.editSaveButtonTapped)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    let mockDetailUseCase: TestTravelPlanDetailUseCase = {
        let useCase = TestTravelPlanDetailUseCase()
        useCase.details = [.mock]
        return useCase
    }()

    NavigationStack {
        PlanDetailView(
            store: Store(
                initialState: PlanDetailFeature.State(plan: .mock),
                reducer: { PlanDetailFeature() },
                withDependencies: { dependency in
                    dependency.travelPlanDetailUseCase = mockDetailUseCase
                }
            )
        )
    }
}
