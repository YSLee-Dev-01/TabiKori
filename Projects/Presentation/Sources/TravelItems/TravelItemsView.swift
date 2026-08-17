//
//  TravelItemsView.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

/// 툴박스 탭 루트 화면. 준비물 마스터 리스트를 보여주고 하단 버튼으로 플랜에 저장한다
public struct TravelItemsView: View {

    @Bindable private var store: StoreOf<TravelItemsFeature>

    public init(store: StoreOf<TravelItemsFeature>) {
        self.store = store
    }

    public var body: some View {
        self.content()
            .safeAreaBar(edge: .top) {
                TabiNavigationBar(title: Strings.TravelItems.title)
            }
            .safeAreaBar(edge: .bottom) {
                TabiButton(
                    Strings.TravelItems.saveToPlanButton,
                    style: .primary,
                    isExpanded: true
                ) {
                    self.store.send(.saveToPlanButtonTapped)
                }
                .disabled(self.store.isLoading || self.store.hasLoadFailed || self.store.items.isEmpty)
                .padding(.horizontal, 20)
            }
            .sheet(item: self.$store.scope(state: \.planPickerState, action: \.planPicker)) { store in
                TravelItemsPlanPickerView(store: store)
            }
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension TravelItemsView {
    @ViewBuilder
    func content() -> some View {
        if self.store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.hasLoadFailed {
            TabiRetryableEmptyState(description: Strings.TravelItems.loadFailedDescription) {
                self.store.send(.retryButtonTapped)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(self.store.items) { item in
                    TravelItemRow(item: item)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    let mockUseCase: TestTravelItemUseCase = {
        let useCase = TestTravelItemUseCase()
        useCase.masterItems = [
            TravelItem(id: "passport", order: 0, title: "パスポート", note: "有効期限を確認"),
            TravelItem(id: "charger", order: 1, title: "充電器", note: nil)
        ]
        return useCase
    }()

    TravelItemsView(
        store: Store(
            initialState: TravelItemsFeature.State(),
            reducer: { TravelItemsFeature() },
            withDependencies: { dependency in
                dependency.travelItemUseCase = mockUseCase
            }
        )
    )
}
