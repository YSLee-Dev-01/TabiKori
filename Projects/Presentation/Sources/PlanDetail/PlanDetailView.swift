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
    @State private var isModeSwitchTransition: Bool = false

    public init(store: StoreOf<PlanDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if self.store.isFullOverview == false {
                self.dayTabScroll(plan: self.store.plan)
            }

            if self.store.isFullOverview {
                self.mapSection()
                    .id(self.mapSectionIdentity(dayIndex: self.store.visibleDayIndex))
                    .transition(self.fullOverviewMapTransition)
                self.fullOverviewList(plan: self.store.plan)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    self.dayHeader(plan: self.store.plan)

                    self.mapSection()

                    self.spotList()
                }
                .id(self.store.selectedDayIndex)
                .transition(self.dayTransition)
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
                        self.handleFullOverviewToggleTapped()
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
                    spotCountTitle: self.spotCountTitle
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
    }

    /// 전체보기 진입/이탈(모드 전환) 중에는 좌우 슬라이드 대신 페이드를 사용하고,
    /// 같은 모드 안에서 일자를 탐색할 때만 좌우 슬라이드를 사용한다
    var dayTransition: AnyTransition {
        guard self.isModeSwitchTransition == false else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: self.isMovingForward ? .trailing : .leading),
            removal: .move(edge: self.isMovingForward ? .leading : .trailing)
        )
    }

    var fullOverviewMapTransition: AnyTransition {
        self.isModeSwitchTransition ? .opacity : .move(edge: .top).combined(with: .opacity)
    }

    func handleFullOverviewToggleTapped() {
        self.isModeSwitchTransition = true
        self.store.send(.fullOverviewToggleTapped)
        // isModeSwitchTransition을 곧바로 되돌리면 모드 전환 렌더와 같은 프레임에 묶여
        // dayTransition/fullOverviewMapTransition이 이미 원래 방향 애니메이션으로 평가될 수 있으므로,
        // 전환이 실제로 캡처된 다음 프레임에 되돌린다
        _ = PlanDetailNextFrameTrigger { [isModeSwitchTransition = self.$isModeSwitchTransition] in
            isModeSwitchTransition.wrappedValue = false
        }
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
    /// 각 헤더의 위치를 GeometryReader로 직접 측정해 판단한다
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
        .coordinateSpace(name: Self.fullOverviewScrollSpace)
        .scrollPosition(id: self.$scrolledDayIndex, anchor: .top)
        .onPreferenceChange(DayHeaderOffsetPreferenceKey.self) { offsets in
            self.handleDayHeaderOffsetsChanged(offsets)
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
