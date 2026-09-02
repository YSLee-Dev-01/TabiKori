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

/// `DetailFeature`를 그대로 위임하되, `addToItineraryButtonTapped`만 `DetailFeature`에 전달하지 않고 여기서
/// 직접 소비해 온보딩 진행 콜백만 호출한다(시트를 프레젠팅했다가 바로 닫으면 전환 애니메이션이 깜빡여서,
/// 애초에 `addToItineraryState`가 채워지지 않도록 액션 자체를 가로막는다). `saveButtonTapped`를 포함한
/// 나머지 액션은 전부 `DetailFeature`에 그대로 위임해 로직을 변형하지 않는다
private struct OnboardingDetailProgressReducer: Reducer {
    let onSaveTapped: () -> Void
    let onAddTapped: () -> Void

    private let detailFeature = DetailFeature()

    func reduce(into state: inout DetailFeature.State, action: DetailFeature.Action) -> Effect<DetailFeature.Action> {
        switch action {
        case .saveButtonTapped:
            let effect = self.detailFeature.reduce(into: &state, action: action)
            self.onSaveTapped()
            return effect

        case .addToItineraryButtonTapped:
            self.onAddTapped()
            return .none

        default:
            return self.detailFeature.reduce(into: &state, action: action)
        }
    }
}
