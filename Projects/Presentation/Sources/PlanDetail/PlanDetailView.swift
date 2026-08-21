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
    @State private var isFullOverviewScrollAtBottom: Bool = false
    @State private var isDayHeaderHidden: Bool = false

    public init(store: StoreOf<PlanDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if self.store.isFullOverview == false {
                // 스크롤 방향에 따라 이 블록 전체(날짜 헤더 + 일자 칩)를 숨기고/보인다.
                // dayHeaderRow 자체의 좌우 day 전환 트랜지션(dayTransition)과 겹치지 않도록,
                // 숨김/보임은 별도로 frame(height:)+opacity를 사용해 수직으로만 접는다
                VStack(alignment: .leading, spacing: 10) {
                    // toolBarButtons()는 일자 전환 트랜지션(dayTransition) 영역 밖에 배치해,
                    // 일자를 이동해도 버튼 위치는 고정되고 날짜 텍스트(dayHeaderRow)만 슬라이드되도록 한다
                    HStack(alignment: .center, spacing: 8) {
                        self.dayHeaderRow(plan: self.store.plan)
                            .id(self.store.selectedDayIndex)
                            .transition(self.dayTransition)
                            .layoutPriority(1)
                        Spacer(minLength: 4)
                        self.toolBarButtons()
                            .fixedSize()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    self.dayTabScroll(plan: self.store.plan)
                }
                .frame(height: self.isDayHeaderHidden ? 0 : nil)
                .opacity(self.isDayHeaderHidden ? 0 : 1)
                .clipped()
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
                        self.mapSection()

                        self.spotList()
                    }
                    .id(self.store.selectedDayIndex)
                    // List(spotList)는 스크롤 배경이 투명(scrollContentBackground(.hidden))이라,
                    // 전환 중 옛 일자 콘텐츠와 새 일자 콘텐츠가 겹쳐 비치는 잔상이 생긴다.
                    // 불투명 배경으로 새로 들어오는 콘텐츠가 나가는 콘텐츠를 가리도록 하고,
                    // clipped()로 슬라이드 도중 프레임 밖으로 삐져나온 부분을 잘라낸다
                    .background(TabiColor.tabiBackground)
                    .transition(self.dayTransition)
                    .clipped()
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
        .animation(.tabiStandard, value: self.isDayHeaderHidden)
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
                        Button(Strings.Plan.planDeleteMenuTitle, role: .destructive) {
                            self.store.send(.deleteMenuButtonTapped)
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
        .sheet(item: self.$store.scope(state: \.timeEditState, action: \.timeEdit)) { store in
            PlanDetailTimeEditView(store: store)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            self.store.send(.onAppear)
        }
        .onChange(of: self.store.isFullOverview) { _, isFullOverview in
            self.isDayHeaderHidden = false
            guard isFullOverview else { return }
            self.scrolledDayIndex = self.store.visibleDayIndex
        }
        .onChange(of: self.store.selectedDayIndex) { _, _ in
            self.isDayHeaderHidden = false
        }
        .onChange(of: self.store.pendingSelectedDayIndexClamp) { _, target in
            // 일정 편집(기간 단축)으로 selectedDayIndex가 범위를 벗어났을 때, day chip 탭과 동일한
            // 두 프레임 분리 경로(changeSelectedDay)로 보정해 좌우 전환 방향을 올바르게 계산한다
            guard let target else { return }
            self.changeSelectedDay(
                from: self.store.selectedDayIndex,
                to: target,
                action: .dayButtonTapped(index: target)
            )
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
    /// spotList 스크롤 오프셋 변화가 이 값을 넘어야 날짜 헤더 숨김/표시 상태를 바꾼다.
    /// 너무 작으면 미세한 스크롤 흔들림에도 헤더가 깜빡여 임계값을 둔다
    static let dayHeaderScrollThreshold: CGFloat = 12

    func dayTabScroll(plan: TravelPlan) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(plan.dayDates.enumerated()), id: \.offset) { offset, _ in
                        TabiChip(
                            Strings.Plan.dayChipTitle(offset + 1),
                            isSelected: self.store.selectedDayIndex == offset
                        ) {
                            self.handleDayChipTapped(offset)
                        }
                        .id(offset)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .disabled(self.store.isEditing)
            .onAppear {
                // 홈 화면 등에서 initialDayIndex로 진입했을 때, 선택된 일자 칩이 화면 가운데 오도록 정렬한다.
                // 첫 번째 칩(index 0)은 스크롤 시작점이라 anchor: .center를 줘도 좌측에 그대로 붙어(회귀 없음)
                proxy.scrollTo(self.store.selectedDayIndex, anchor: .center)
            }
        }
    }

    func toolBarButtons() -> some View {
        HStack(spacing: 8) {
            self.capsuleButton(systemImageName: "shippingbox", title: Strings.ToolBar.planDetailEntryTitle) {
                self.store.send(.toolBarButtonTapped)
            }
            self.capsuleButton(systemImageName: "cart", title: Strings.Plan.shoppingListButtonTitle) {
                self.store.send(.shoppingListButtonTapped)
            }
        }
    }

    func capsuleButton(systemImageName: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImageName)
                TabiLabel(title: title, style: .captionM, color: .tabiTextSecondary)
            }
            .foregroundStyle(TabiColor.tabiTextSecondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(TabiColor.tabiSurface)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(TabiColor.tabiBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    func handleDayChipTapped(_ offset: Int) {
        guard offset != self.store.selectedDayIndex else { return }
        self.changeSelectedDay(from: self.store.selectedDayIndex, to: offset, action: .dayButtonTapped(index: offset))
    }

    func handleFullOverviewToggleTapped() {
        guard self.store.isFullOverview else {
            self.store.send(.fullOverviewToggleTapped)
            return
        }
        // 전체보기 종료 시 selectedDayIndex가 visibleDayIndex로 점프하므로(PlanDetailFeature의
        // fullOverviewToggleTapped 참고), day chip 탭과 동일하게 방향 플래그를 먼저 커밋한 뒤
        // 다음 프레임에 실제 전환 액션을 보낸다
        self.changeSelectedDay(
            from: self.store.selectedDayIndex,
            to: self.store.visibleDayIndex,
            action: .fullOverviewToggleTapped
        )
    }

    /// 일자 전환 좌우 애니메이션 방향(isMovingForward)과 실제 selectedDayIndex 변경을 서로 다른
    /// 렌더 프레임으로 분리해 보낸다. 두 변경이 같은 렌더 트랜잭션에서 처리되면 사라지는 뷰의
    /// removal transition이 직전 프레임에 커밋된(스테일) 방향을 그대로 사용해버리는 SwiftUI 특성 때문에
    /// (DispatchQueue.main.async로는 프레임 분리를 보장하지 못해 CADisplayLink 기반
    /// PlanDetailNextFrameTrigger를 사용), selectedDayIndex를 변경하는 모든 경로(day chip 탭,
    /// 전체보기 종료, dayCount 축소 보정)가 이 메서드를 거쳐야 한다
    func changeSelectedDay(from currentIndex: Int, to newIndex: Int, action: PlanDetailFeature.Action) {
        guard newIndex != currentIndex else {
            self.store.send(action)
            return
        }
        self.isMovingForward = newIndex >= currentIndex
        _ = PlanDetailNextFrameTrigger { [store = self.store] in
            store.send(action)
        }
    }

    /// 단일 일자 뷰 전용: 일자 정보(PlanDetailDayHeader)만 노출한다.
    /// 준비물/쇼핑리스트 버튼(toolBarButtons)은 일자 전환 트랜지션이 걸리지 않도록 상위(body)에서 별도로 배치된다.
    /// 전체보기(fullOverviewList)의 Section 헤더는 날짜 정보만 유지해야 하므로 별도로 인라인 구성됨
    func dayHeaderRow(plan: TravelPlan) -> some View {
        Group {
            if let dateTitle = self.selectedDayDateTitle(plan: plan) {
                PlanDetailDayHeader(dateTitle: dateTitle, spotCountTitle: nil)
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
            PlanDetailMapSection(markers: self.selectedDayMarkers, fitToken: self.store.dayMapFitToken) {
                self.store.send(.fullMapButtonTapped)
            }
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
                        if self.store.isEditing {
                            self.store.send(.spotEditRowTapped(spot))
                        } else {
                            self.store.send(.spotRowTapped(spot))
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .swipeActions(edge: .trailing) {
                        if self.store.isEditing == false {
                            Button(role: .destructive) {
                                self.store.send(.spotDeleteButtonTapped(id: spot.id))
                            } label: {
                                Label(Strings.Common.delete, systemImage: "trash")
                            }
                            // PlanDetailView는 TabBarView의 TabView(.tint(tabiPrimary)) 스코프 밖(NavigationStack destination)에 있어
                            // 스와이프 삭제 버튼이 기본 시스템 red로 표시됨. Bookmark(TabView 하위, tabiPrimary 상속)와 색상을 맞추기 위해 명시적으로 tint 지정
                            .tint(Color.getTabiColor(.tabiPrimary))
                        }
                    }
                }
                .onDelete { indexSet in
                    self.store.send(.spotDeletedInEditMode(at: indexSet))
                }
                // `.moveDisabled(true)`는 onMove 콜백 호출만 막을 뿐, 롱프레스 재정렬 제스처
                // 인식기 자체는 List에 여전히 등록돼 있어 같은 행의 .onTapGesture/.swipeActions와
                // 충돌해 편집모드 진입 전(state.editingSpots가 빈 배열)에도 크래시가 발생했다.
                // onMove(perform:)는 옵셔널 클로저를 받으므로, 편집모드가 아닐 땐 nil을 넘겨
                // 재정렬 제스처 인식기 자체를 등록하지 않도록 해 근본 원인을 제거한다
                .onMove(perform: self.store.isEditing ? { source, destination in
                    self.store.send(.spotMovedInEditMode(source: source, destination: destination))
                } : nil)
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
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldOffsetY, newOffsetY in
            self.handleSpotListScrollChanged(oldOffsetY: oldOffsetY, newOffsetY: newOffsetY)
        }
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
        // 지도 섹션 높이(200pt) + 여유 버퍼만큼 여백을 늘려, 마지막 일자의 스팟이 적어 콘텐츠가 짧을 때도
        // 스크롤이 바닥까지 도달할 수 있게 해 isScrollAtBottom(...) 감지가 안정적으로 동작하도록 한다
        .contentMargins(.bottom, 220, for: .scrollContent)
        .coordinateSpace(name: Self.fullOverviewScrollSpace)
        .scrollPosition(id: self.$scrolledDayIndex, anchor: .top)
        .onPreferenceChange(DayHeaderOffsetPreferenceKey.self) { offsets in
            self.handleDayHeaderOffsetsChanged(offsets)
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            self.isScrollAtBottom(geometry)
        } action: { _, isAtBottom in
            self.isFullOverviewScrollAtBottom = isAtBottom
            guard isAtBottom, let lastDayIndex = plan.dayDates.indices.last else { return }
            self.store.send(.visibleDayIndexChanged(lastDayIndex))
        }
    }

    /// 상단 임계값을 통과한(스크롤된) 헤더 중 가장 아래쪽(가장 최근에 통과한) 일자를 현재 보이는 세션으로 판단한다.
    /// 아직 어떤 헤더도 임계값을 통과하지 않은 초기 상태에서는 가장 위에 있는(첫) 일자를 사용한다.
    /// 마지막 일자의 스팟이 적으면 그 헤더는 구조적으로 상단 임계선을 절대 통과할 수 없어, 스크롤이
    /// 바닥에 닿아 있는 동안(isFullOverviewScrollAtBottom)에는 이 판정이 isScrollAtBottom 폴백이
    /// 고른 마지막 일자를 곧바로 이전 일자로 덮어써버리는 경쟁이 발생한다 — 바닥에 닿아있는 동안은
    /// 이 판정을 건너뛰어 우선순위를 폴백에 양보하고, 사용자가 다시 위로 스크롤해 바닥을 벗어나면
    /// (isFullOverviewScrollAtBottom이 다시 false가 되며) 헤더 기반 판정이 정상 재개된다
    func handleDayHeaderOffsetsChanged(_ offsets: [Int: CGFloat]) {
        guard self.isFullOverviewScrollAtBottom == false else { return }
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

    /// 단일 일자 상세(spotList) 스크롤 방향에 따라 상단 날짜 헤더 영역의 숨김/표시를 전환한다.
    /// 콘텐츠가 위로 올라가면(오프셋 증가) 숨기고, 아래로 내려가면(오프셋 감소) 다시 표시한다.
    /// 최상단 부근(오버스크롤 포함)에서는 임계값과 무관하게 항상 표시해, 스크롤을 끝까지 올렸을 때
    /// 헤더가 숨겨진 채로 남아있지 않도록 한다
    func handleSpotListScrollChanged(oldOffsetY: CGFloat, newOffsetY: CGFloat) {
        guard newOffsetY > Self.dayHeaderScrollThreshold else {
            self.isDayHeaderHidden = false
            return
        }
        let delta = newOffsetY - oldOffsetY
        guard abs(delta) > Self.dayHeaderScrollThreshold else { return }
        self.isDayHeaderHidden = delta > 0
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
