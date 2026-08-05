//
//  FestivalFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

/// `FestivalFeature`에서 현재 캘린더 편집 대상이 되는 날짜 필드
public enum FestivalDateField: Equatable, Hashable, Sendable {
    case start
    case end
}

@Reducer
public struct FestivalFeature: Sendable {

    @Dependency(\.festivalUseCase) var festivalUseCase

    @ObservableState
    public struct State: Equatable {
        var startDate: Date? = Calendar.current.date(
            byAdding: .day,
            value: -FestivalSearchPeriod.defaultDurationDays,
            to: Calendar.current.startOfDay(for: Date())
        )
        var endDate: Date? = nil
        var activeDateField: FestivalDateField? = nil
        var regions: [LDongRegion] = []
        var selectedRegionCode: String? = nil
        var festivals: [Festival] = []
        var isLoading: Bool = false
        fileprivate var hasLoadedRegions: Bool = false
        fileprivate var hasLoadedInitialFestivals: Bool = false

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case dateFieldTapped(FestivalDateField)
        case regionChipTapped(String?)
        case festivalTapped(Festival)
        case festivalsResult([Festival])
        case regionsResult([LDongRegion])
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.startDate):
                state.isLoading = true
                return self.searchEffect(state: state)

            case .binding(\.endDate):
                state.isLoading = true
                return self.searchEffect(state: state)

            case .binding:
                return .none

            case .onAppear:
                var effects: [Effect<Action>] = []

                if state.hasLoadedRegions == false {
                    state.hasLoadedRegions = true
                    effects.append(self.fetchRegionsEffect())
                }

                if state.hasLoadedInitialFestivals == false {
                    state.hasLoadedInitialFestivals = true
                    state.isLoading = true
                    effects.append(self.searchEffect(state: state))
                }

                return .merge(effects)

            case .dateFieldTapped(let field):
                state.activeDateField = state.activeDateField == field ? nil : field
                return .none

            case .regionChipTapped(let regionCode):
                state.selectedRegionCode = state.selectedRegionCode == regionCode ? nil : regionCode
                state.isLoading = true
                return self.searchEffect(state: state)

            case .festivalTapped:
                return .none

            case .festivalsResult(let festivals):
                state.festivals = festivals
                state.isLoading = false
                return .none

            case .regionsResult(let regions):
                state.regions = regions
                return .none
            }
        }
    }
}

// MARK: - CancelID

private enum CancelID {
    case festivalSearch
}

// MARK: - Method

private extension FestivalFeature {
    func searchEffect(state: State) -> Effect<Action> {
        guard let startDate = state.startDate else {
            return .send(.festivalsResult([]))
        }
        let endDate = state.endDate
        let regionCode = state.selectedRegionCode

        return .run { [festivalUseCase = self.festivalUseCase] send in
            do {
                let festivals = try await festivalUseCase.fetchFestivals(
                    startDate: startDate,
                    endDate: endDate,
                    regionCode: regionCode,
                    pageNo: 1
                )
                await send(.festivalsResult(festivals))
            } catch {
                guard !Task.isCancelled else {
                    AppLogger.view.log(.debug, "행사 검색 취소됨")
                    return
                }
                AppLogger.view.log(.error, "행사 검색 실패: \(error.localizedDescription)")
                await send(.festivalsResult([]))
            }
        }
        .cancellable(id: CancelID.festivalSearch, cancelInFlight: true)
    }

    func fetchRegionsEffect() -> Effect<Action> {
        .run { [festivalUseCase = self.festivalUseCase] send in
            do {
                let regions = try await festivalUseCase.fetchRegions()
                await send(.regionsResult(regions))
            } catch {
                AppLogger.view.log(.error, "지역 목록 조회 실패: \(error.localizedDescription)")
                await send(.regionsResult([]))
            }
        }
    }
}
