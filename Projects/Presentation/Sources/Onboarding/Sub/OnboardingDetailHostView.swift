//
//  OnboardingDetailHostView.swift
//  Presentation
//
//  Created by Claude on 9/2/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Domain

/// 온보딩 관광지 상세 스텝에서 실제 `DetailFeature`/`DetailView`를 그대로 렌더링한다. `OnboardingMock.detailSpot`을
/// 초기 State로 채우고, 해당 스팟의 상세/소개/이미지 정보를 `TestTouristSpotUseCase`에 직접 주입해 실제 네트워크
/// 호출 없이 상세 화면을 곧바로 노출한다. 저장 버튼 탭(`DetailFeature.Action.saveButtonTapped`)과 일정 추가 버튼 탭
/// (`DetailFeature.Action.addToItineraryButtonTapped`)만 가로채 온보딩 진행 신호로 전달한다
struct OnboardingDetailHostView: View {

    @State private var store: StoreOf<DetailFeature>
    @Namespace private var namespace

    init(onSaveTapped: @escaping () -> Void, onAddTapped: @escaping () -> Void) {
        self._store = State(initialValue: Store(
            initialState: DetailFeature.State(touristSpot: OnboardingMock.detailSpot),
            reducer: { OnboardingDetailProgressReducer(onSaveTapped: onSaveTapped, onAddTapped: onAddTapped) },
            withDependencies: { dependency in
                let touristSpotUseCase = TestTouristSpotUseCase()
                touristSpotUseCase.detail = OnboardingMock.detailSpotDetail
                touristSpotUseCase.intro = OnboardingMock.detailSpotIntro
                touristSpotUseCase.images = OnboardingMock.detailSpotImages
                dependency.touristSpotUseCase = touristSpotUseCase

                dependency.naverMapUseCase = TestNaverMapUseCase()
                dependency.bookmarkUseCase = TestBookmarkUseCase()
                dependency.toastCenter = TestToastCenter()
                dependency.analyticsCenter = TestAnalyticsCenter()
            }
        ))
    }

    var body: some View {
        DetailView(store: self.store, namespace: self.namespace)
    }
}

// MARK: - OnboardingDetailProgressReducer

/// `DetailFeature`를 그대로 조립하되, `saveButtonTapped`/`addToItineraryButtonTapped` 액션만 옆에서 관찰해
/// 온보딩 진행 콜백을 호출하는 얇은 래퍼 Reducer. `DetailFeature`의 State/Action/로직은 전혀 변형하지 않는다
private struct OnboardingDetailProgressReducer: Reducer {
    let onSaveTapped: () -> Void
    let onAddTapped: () -> Void

    var body: some ReducerOf<DetailFeature> {
        DetailFeature()
        Reduce { _, action in
            switch action {
            case .saveButtonTapped:
                self.onSaveTapped()
            case .addToItineraryButtonTapped:
                self.onAddTapped()
            default:
                break
            }
            return .none
        }
    }
}
