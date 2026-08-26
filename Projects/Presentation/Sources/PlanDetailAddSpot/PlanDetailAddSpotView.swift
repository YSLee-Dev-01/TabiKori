//
//  PlanDetailAddSpotView.swift
//  Presentation
//
//  Created by 이윤수 on 8/5/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
@preconcurrency import Translation

import ComposableArchitecture
import Core
import DesignSystem
import Domain
import Resource

/// PlanDetail "+" 버튼으로 여는 하단 시트. Step 1(스팟 선택)과 Step 2(시각 설정)를 전환하며 보여준다
struct PlanDetailAddSpotView: View {
    @Bindable private var store: StoreOf<PlanDetailAddSpotFeature>

    @State private var selectedDetent: PresentationDetent = .medium
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isAddressTitleFocused: Bool
    @FocusState private var isAddressFieldFocused: Bool
    @State private var translationConfiguration: TranslationSession.Configuration?

    init(store: StoreOf<PlanDetailAddSpotFeature>) {
        self.store = store
    }

    var body: some View {
        VStack(spacing: 0) {
            self.header()
            self.stepContent()
                .animation(.tabiStandard, value: self.store.step)
        }
        .presentationDetents([.medium, .large], selection: self.$selectedDetent)
        .presentationDragIndicator(.visible)
        .alert($store.scope(state: \.alert, action: \.alert))
        .onChange(of: self.isSearchFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
        .onChange(of: self.isAddressTitleFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
        .onChange(of: self.isAddressFieldFocused) { _, isFocused in
            guard isFocused else { return }
            self.selectedDetent = .large
        }
        .onAppear {
            self.store.send(.onAppear)
        }
        .onChange(of: self.store.pendingTranslationQuery) { _, newValue in
            guard newValue != nil else { return }
            // TranslationSession.Configuration은 Equatable이라 동일한 source/target으로 새 인스턴스를 만들어도
            // 이전 값과 같다고 판단되어 .translationTask가 재실행되지 않는다. 이미 Configuration이 있다면
            // invalidate()로 명시적으로 무효화해야 동일 언어쌍으로도 번역이 다시 실행된다
            guard self.translationConfiguration != nil else {
                self.translationConfiguration = TranslationSession.Configuration(
                    source: Locale.Language(languageCode: .japanese),
                    target: Locale.Language(languageCode: .korean)
                )
                return
            }
            self.translationConfiguration?.invalidate()
        }
        .translationTask(self.translationConfiguration) { session in
            guard let query = self.store.pendingTranslationQuery else { return }
            do {
                let response = try await session.translate(query)
                self.store.send(.translationResultReceived(response.targetText))
            } catch {
                AppLogger.view.log(.error, "検索語の翻訳に失敗: \(error.localizedDescription)")
                self.store.send(.translationFailed)
            }
        }
    }
}

// MARK: - View

private extension PlanDetailAddSpotView {
    func header() -> some View {
        HStack(spacing: 12) {
            if self.store.step == .configuringTime {
                Button {
                    self.store.send(.backButtonTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(TabiColor.tabiTextPrimary)
                }
            }
            TabiLabel(title: Strings.Plan.spotAddButtonTitle, style: .titleS, color: .tabiTextPrimary)
            Spacer()
            Button {
                self.store.send(.closeButtonTapped)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(TabiColor.tabiTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(TabiColor.tabiSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(TabiPressStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    func stepContent() -> some View {
        switch self.store.step {
        case .selectingSpot:
            self.selectingSpotView()
                .transition(.move(edge: .leading))

        case .configuringTime:
            TabiItineraryTimeConfigView(
                planTitle: self.store.selectedSpot?.japaneseTitle ?? "",
                dayTitle: Strings.Plan.dayChipTitle(self.store.dayIndex + 1),
                dateTitle: self.store.date.planDayHeaderTitle,
                startTime: self.$store.startTime,
                endTime: self.$store.endTime,
                durationMinutes: self.store.durationMinutes,
                isTimeUnset: self.$store.isTimeUnset,
                isSaveEnabled: self.store.isSaveEnabled,
                isSaving: self.store.isSaving,
                onSaveTapped: { self.store.send(.saveButtonTapped) }
            )
            .transition(.move(edge: .trailing))
        }
    }

    func selectingSpotView() -> some View {
        VStack(spacing: 16) {
            PlanDetailAddSpotTabBar(selectedTab: self.store.tab) { tab in
                self.store.send(.tabSelected(tab))
            }
            .padding(.horizontal, 20)

            switch self.store.tab {
            case .search:
                PlanDetailAddSpotSearchListView(
                    keyword: self.$store.searchKeyword,
                    subwayResults: self.store.subwayResults,
                    results: self.store.searchResults,
                    isLoading: self.store.isSearchLoading,
                    hasSearched: self.store.hasSearched,
                    isAutoTranslateSearchEnabled: self.store.isAutoTranslateSearchEnabled,
                    focus: self.$isSearchFocused,
                    onSubmit: { self.store.send(.searchSubmitted) },
                    onSpotTapped: { self.store.send(.spotRowTapped($0)) },
                    onSubwayStationTapped: { self.store.send(.subwayStationTapped($0)) },
                    onTranslateTapped: { self.store.send(.translateSearchButtonTapped) }
                )

            case .address:
                PlanDetailAddSpotAddressView(
                    title: self.$store.addressTitle,
                    address: self.$store.addressInput,
                    selectedCategory: self.store.addressSelectedCategory,
                    previewCoordinate: self.store.addressPreviewCoordinate,
                    previewFitToken: self.store.addressPreviewFitToken,
                    isGeocoding: self.store.isAddressGeocoding,
                    isConfirmEnabled: self.store.isAddressConfirmEnabled,
                    titleFocus: self.$isAddressTitleFocused,
                    addressFocus: self.$isAddressFieldFocused,
                    onAddressSubmit: { self.store.send(.addressSubmitted) },
                    onCategorySelected: { self.store.send(.addressCategorySelected($0)) },
                    onConfirmTapped: { self.store.send(.addressConfirmTapped) }
                )

            case .bookmark:
                PlanDetailAddSpotBookmarkListView(
                    bookmarks: self.store.bookmarks,
                    isLoading: self.store.isBookmarkLoading,
                    onSpotTapped: { self.store.send(.spotRowTapped($0)) }
                )
            }
        }
    }
}

#Preview {
    let mockTouristSpotUseCase: TestTouristSpotUseCase = {
        let useCase = TestTouristSpotUseCase()
        useCase.searchResults = []
        return useCase
    }()
    let mockBookmarkUseCase: TestBookmarkUseCase = {
        let useCase = TestBookmarkUseCase()
        useCase.bookmarks = []
        return useCase
    }()
    let mockDetailUseCase: TestTravelPlanDetailUseCase = {
        let useCase = TestTravelPlanDetailUseCase()
        useCase.details = [.mock]
        return useCase
    }()

    PlanDetailAddSpotView(
        store: Store(
            initialState: PlanDetailAddSpotFeature.State(
                planId: TravelPlan.mock.id,
                dayIndex: 0,
                date: Date(),
                detail: .mock
            ),
            reducer: { PlanDetailAddSpotFeature() },
            withDependencies: { dependency in
                dependency.touristSpotUseCase = mockTouristSpotUseCase
                dependency.bookmarkUseCase = mockBookmarkUseCase
                dependency.travelPlanDetailUseCase = mockDetailUseCase
            }
        )
    )
}
