//
//  ToolBarView.swift
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
public struct ToolBarView: View {

    @Bindable private var store: StoreOf<ToolBarFeature>

    public init(store: StoreOf<ToolBarFeature>) {
        self.store = store
    }

    public var body: some View {
        self.content()
            .safeAreaBar(edge: .top) {
                TabiNavigationBar(title: Strings.ToolBar.title)
            }
            .safeAreaBar(edge: .bottom) {
                TabiButton(
                    Strings.ToolBar.saveToPlanButton,
                    style: .primary,
                    isExpanded: true
                ) {
                    self.store.send(.saveToPlanButtonTapped)
                }
                .disabled(self.store.isLoading || self.store.hasLoadFailed || self.store.items.isEmpty)
                .padding(.horizontal, 20)
            }
            .sheet(item: self.$store.scope(state: \.planPickerState, action: \.planPicker)) { store in
                ToolBarPlanPickerView(store: store)
            }
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension ToolBarView {
    @ViewBuilder
    func content() -> some View {
        if self.store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.hasLoadFailed {
            TabiRetryableEmptyState(description: Strings.ToolBar.loadFailedDescription) {
                self.store.send(.retryButtonTapped)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if self.store.items.isEmpty {
                    ToolBarEmptyState()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                } else {
                    ForEach(self.store.items) { item in
                        ToolBarItemRow(item: item)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    let mockUseCase: TestToolBarItemUseCase = {
        let useCase = TestToolBarItemUseCase()
        useCase.masterItems = [
            ToolBarItem(id: "passport", order: 0, title: "パスポート", note: "有効期限を確認"),
            ToolBarItem(id: "charger", order: 1, title: "充電器", note: nil)
        ]
        return useCase
    }()

    ToolBarView(
        store: Store(
            initialState: ToolBarFeature.State(),
            reducer: { ToolBarFeature() },
            withDependencies: { dependency in
                dependency.toolBarItemUseCase = mockUseCase
            }
        )
    )
}
