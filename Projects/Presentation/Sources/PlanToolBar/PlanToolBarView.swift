//
//  PlanToolBarView.swift
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

/// 플랜에 저장된 준비물 체크리스트 화면. PlanDetail 일자 헤더의 "준비물" 버튼에서 push된다.
/// 상단 +버튼으로 항목 추가, 편집 버튼으로 삭제/이름 수정이 가능하다
public struct PlanToolBarView: View {

    @Bindable private var store: StoreOf<PlanToolBarFeature>

    @FocusState private var isAddFieldFocused: Bool

    public init(store: StoreOf<PlanToolBarFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            self.content()

            if self.store.isEditing {
                self.editActionButtons()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.tabiStandard, value: self.store.isEditing)
        .animation(.tabiStandard, value: self.store.isAdding)
        .navigationTitle(Strings.ToolBar.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.store.send(.addButtonTapped)
                } label: {
                    Image(systemName: self.store.isAdding ? "xmark" : "plus")
                }
                .tint(Color.getTabiColor(.tabiPrimary))
                .accessibilityLabel(
                    self.store.isAdding ? Strings.ToolBar.closeAddButtonAccessibilityLabel : Strings.ToolBar.addButtonAccessibilityLabel
                )
                .disabled(self.store.isLoading)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    self.store.send(.editButtonTapped)
                } label: {
                    Image(systemName: "pencil")
                }
                .tint(Color.getTabiColor(.tabiPrimary))
                .accessibilityLabel(Strings.ToolBar.editButtonAccessibilityLabel)
                .disabled(self.store.isLoading || self.store.items.isEmpty)
            }
        }
        .onChange(of: self.store.isAdding) { _, isAdding in
            self.isAddFieldFocused = isAdding
        }
        .onAppear {
            self.store.send(.onAppear)
        }
    }
}

// MARK: - View

private extension PlanToolBarView {
    @ViewBuilder
    func content() -> some View {
        if self.store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if self.store.items.isEmpty && self.store.isAdding == false {
            TabiEmptyState(
                systemImageName: "shippingbox",
                title: Strings.ToolBar.savedEmptyTitle,
                description: Strings.ToolBar.savedEmptyDescription,
                style: .card
            )
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            self.list()
        }
    }

    func list() -> some View {
        List {
            Section {
                // 체크 행 ↔ 편집 행을 별개의 ForEach로 분기하면 List 셀 재사용 시 일부 행이
                // 새 콘텐츠(텍스트필드)를 반영하지 못하는 문제가 있어, 하나의 ForEach/행 타입을
                // 유지한 채 PlanToolBarItemRow 내부에서만 isEditing에 따라 표시를 바꾼다
                ForEach(self.$store.items) { $item in
                    PlanToolBarItemRow(item: $item, isEditing: self.store.isEditing) {
                        self.store.send(.itemTapped(id: $item.wrappedValue.id))
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
                .onDelete { indexSet in
                    self.store.send(.editItemDeleted(at: indexSet))
                }

                if self.store.isAdding {
                    TabiTextField(
                        placeholder: Strings.ToolBar.addItemPlaceholder,
                        text: self.$store.newItemTitle,
                        focus: self.$isAddFieldFocused,
                        submitLabel: .done,
                        onSubmit: { self.store.send(.newItemSubmitted) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
            } header: {
                TabiLabel(
                    title: Strings.ToolBar.checkedCountTitle(self.store.checkedCount, self.store.items.count),
                    style: .captionMBold,
                    color: .tabiTextSecondary
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                // List Section 헤더는 .plain 스타일에서도 자체 기본 inset을 추가로 적용해 row(listRowInsets leading 20)보다
                // 더 들어가 보임 — fullOverviewList() 헤더와 동일하게 listRowInsets를 0으로 지정해 기본 inset을 제거하고
                // 위 .padding(.horizontal, 20)만으로 실제 좌측 여백을 결정하게 함
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(self.store.isEditing ? .active : .inactive))
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
    let mockUseCase: TestToolBarItemUseCase = {
        let useCase = TestToolBarItemUseCase()
        useCase.savedItems = [
            ToolBarPlanItem(id: UUID(), planId: TravelPlan.mock.id, order: 0, title: "パスポート", note: "有効期限を確認", isChecked: true),
            ToolBarPlanItem(id: UUID(), planId: TravelPlan.mock.id, order: 1, title: "充電器", note: nil, isChecked: false)
        ]
        return useCase
    }()

    NavigationStack {
        PlanToolBarView(
            store: Store(
                initialState: PlanToolBarFeature.State(plan: .mock),
                reducer: { PlanToolBarFeature() },
                withDependencies: { dependency in
                    dependency.toolBarItemUseCase = mockUseCase
                }
            )
        )
    }
}
