//
//  PlanView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

public struct PlanView: View {

    @Bindable private var store: StoreOf<PlanFeature>

    public init(store: StoreOf<PlanFeature>) {
        self.store = store
    }

    public var body: some View {
        self.planList()
            .safeAreaBar(edge: .top) {
                TabiNavigationBar(title: Strings.Plan.title) {
                    self.planMenuButtons()
                }
            }
            .sheet(item: self.$store.scope(state: \.addPlanState, action: \.addPlan)) { store in
                AddTravelPlanView(store: store)
            }
            .sheet(item: self.$store.scope(state: \.editPlanState, action: \.editPlan)) { store in
                PlanDetailEditView(store: store)
            }
            .fileImporter(
                isPresented: Binding(
                    get: { self.store.isImporterPresented },
                    set: { self.store.send(.importerPresentationChanged($0)) }
                ),
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    self.store.send(.importFileSelected(url))
                case .failure:
                    self.store.send(.importFileSelected(nil))
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .animation(.tabiStandard, value: self.store.isEditing)
            .onAppear {
                self.store.send(.onAppear)
            }
    }
}

// MARK: - View

private extension PlanView {
    func planMenuButtons() -> some View {
        HStack(spacing: 10) {
            if self.store.isEditing {
                Button {
                    self.store.send(.editModeToggleTapped)
                } label: {
                    TabiGlassIconLabel(systemName: "xmark", size: .ml, foregroundColor: .tabiPrimary)
                }
            } else {
                Button {
                    self.store.send(.addButtonTapped)
                } label: {
                    TabiGlassIconLabel(systemName: "plus", size: .ml, foregroundColor: .tabiPrimary)
                }

                Menu {
                    Button(Strings.Plan.editMenuTitle) {
                        self.store.send(.editModeToggleTapped)
                    }
                    Button(Strings.Plan.importMenuTitle) {
                        self.store.send(.importButtonTapped)
                    }
                } label: {
                    TabiGlassIconLabel(systemName: "ellipsis", size: .ml, foregroundColor: .tabiPrimary)
                }
            }
        }
    }

    func planList() -> some View {
        GeometryReader { proxy in
            List {
                if self.store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: proxy.size.height)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                } else if self.store.plans.isEmpty {
                    PlanEmptyState()
                        .frame(height: proxy.size.height)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                } else {
                    self.section(.ongoing, plans: self.store.ongoingPlans)
                    self.section(.upcoming, plans: self.store.upcomingPlans)
                    self.section(.past, plans: self.store.pastPlans)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(self.store.isEditing ? .active : .inactive))
        }
    }

    @ViewBuilder
    func section(_ section: PlanSection, plans: [TravelPlan]) -> some View {
        if !plans.isEmpty {
            Section {
                ForEach(plans) { plan in
                    PlanCardView(
                        plan: plan,
                        spotCount: self.store.spotCounts[plan.id] ?? 0,
                        onTapped: {
                            if self.store.isEditing {
                                self.store.send(.planEditCellTapped(plan: plan))
                            } else {
                                self.store.send(.planTapped(plan: plan))
                            }
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowSeparator(.hidden)
                    // 브라우징 중에는 항상 동일한 커스텀 스와이프 삭제("削除" + tabiPrimary tint)를 노출한다.
                    // 편집모드(.onDelete 기반 네이티브 좌측 "-" 버튼)가 활성화되면 List가 자체적으로
                    // 이 swipeActions 대신 네이티브 편집 컨트롤을 보여주므로 별도 조건 분기가 필요 없다
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            self.store.send(.planDeleteButtonTapped(id: plan.id))
                        } label: {
                            Text(Strings.Common.delete)
                        }
                        .tint(Color.getTabiColor(.tabiPrimary))
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        self.store.send(.planDeleteButtonTapped(id: plans[index].id))
                    }
                }
            } header: {
                TabiLabel(title: section.title, style: .bodyMBold, color: .tabiTextPrimary)
            }
        }
    }
}
