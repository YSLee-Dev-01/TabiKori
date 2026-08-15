//
//  MapSearchPanelView.swift
//  Presentation
//
//  Created by 이윤수 on 7/31/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

private enum MapSearchPanelLayout {
    static let dragHandleSize = CGSize(width: 36, height: 4)
    static let dragHandleTouchPadding: CGFloat = 20

    // 올릴 때는 더 민감하게 반응하도록 낮은 임계값 사용
    static let upwardMinimumDrag: CGFloat = 24
    static let upwardFlickVelocity: CGFloat = 350

    // 내릴 때는 더 신중하게 반응하도록 높은 임계값 사용 (핸들 터치 패딩보다 반드시 커야 우발적 터치와 구분됨)
    static let downwardMinimumDrag: CGFloat = 44
    static let downwardFlickVelocity: CGFloat = 900
}

struct MapSearchPanelView<Content: View>: View {

    // MARK: - Properties

    private let stage: MapPanelStage
    private let collapsedHeight: CGFloat
    private let halfHeight: CGFloat
    private let fullHeight: CGFloat
    private let onStageChanged: (MapPanelStage) -> Void
    private let onDismiss: () -> Void
    private let onDragStarted: () -> Void
    private let onDragEnded: () -> Void
    private let content: Content

    @State private var displayedStage: MapPanelStage
    @GestureState(resetTransaction: Transaction(animation: .tabiSpring)) private var dragOffset: CGFloat = 0
    @GestureState private var isDragActive: Bool = false

    private var baseHeight: CGFloat {
        switch self.displayedStage {
        case .collapsed: return self.collapsedHeight
        case .half: return self.halfHeight
        case .full: return self.fullHeight
        }
    }

    private var currentHeight: CGFloat {
        min(self.fullHeight, max(0, self.baseHeight - self.dragOffset))
    }

    private var hiddenOffset: CGFloat {
        max(0, self.fullHeight - self.currentHeight)
    }

    private var dragHandleTotalHeight: CGFloat {
        MapSearchPanelLayout.dragHandleSize.height + MapSearchPanelLayout.dragHandleTouchPadding * 2
    }

    // MARK: - Init

    init(
        stage: MapPanelStage,
        collapsedHeight: CGFloat,
        halfHeight: CGFloat,
        fullHeight: CGFloat,
        onStageChanged: @escaping (MapPanelStage) -> Void,
        onDismiss: @escaping () -> Void,
        onDragStarted: @escaping () -> Void = {},
        onDragEnded: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.stage = stage
        self.collapsedHeight = collapsedHeight
        self.halfHeight = halfHeight
        self.fullHeight = fullHeight
        self.onStageChanged = onStageChanged
        self.onDismiss = onDismiss
        self.onDragStarted = onDragStarted
        self.onDragEnded = onDragEnded
        self.content = content()
        self._displayedStage = State(initialValue: stage)
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            self.dragHandle()
            self.content
                // content 영역을 fullHeight 기준으로 고정하면 Spacer로 중앙 정렬하는 하위 뷰
                // (emptyView 등)가 항상 fullHeight 기준으로 중앙을 계산해, half/collapsed처럼
                // 실제로 더 작게 보이는 단계에서는 그 중앙 지점이 화면 밖으로 밀려 보이지 않는다.
                // 컨텐츠에는 현재 단계의 실제 표시 높이(currentHeight)를 별도로 전달해 그
                // 값 기준으로 중앙 정렬되도록 한다
                .frame(height: max(0, self.currentHeight - self.dragHandleTotalHeight), alignment: .top)
        }
        .frame(maxWidth: .infinity)
        // 바깥 컨테이너는 fullHeight로 고정하고 offset(hiddenOffset)으로만 reveal한다.
        // 컨테이너 높이 자체를 currentHeight로 재계산하면 등장 시 부모의
        // .transition(.move(edge: .bottom))이 계산하는 삽입 지오메트리와 경합해
        // 슬라이드업 애니메이션이 보이지 않게 된다
        .frame(height: self.fullHeight, alignment: .top)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: .tabiRadiusXl, topTrailingRadius: .tabiRadiusXl)
                .fill(TabiColor.tabiSurface)
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .offset(y: self.hiddenOffset)
        .animation(.tabiSpring, value: self.displayedStage)
        .onChange(of: self.isDragActive) { _, newValue in
            if newValue {
                self.onDragStarted()
            } else {
                self.onDragEnded()
            }
        }
        .onChange(of: self.stage) { _, newValue in
            guard self.isDragActive == false, newValue != self.displayedStage else { return }
            self.displayedStage = newValue
        }
    }
}

// MARK: - View

private extension MapSearchPanelView {
    func dragHandle() -> some View {
        Capsule()
            .fill(TabiColor.tabiBorder)
            .frame(width: MapSearchPanelLayout.dragHandleSize.width, height: MapSearchPanelLayout.dragHandleSize.height)
            .padding(.vertical, MapSearchPanelLayout.dragHandleTouchPadding)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(self.dragGesture())
    }

    func dragGesture() -> some Gesture {
        // .global 좌표계 사용: 시트 자신이 이 제스처의 결과로 움직이므로,
        // .local(뷰 기준) 좌표계를 쓰면 translation 측정 기준이 매 프레임 같이 움직여
        // 오차가 누적되는 피드백 루프가 발생해 미세 드래그 시 떨림으로 나타난다
        DragGesture(coordinateSpace: .global)
            .updating(self.$dragOffset) { value, state, _ in
                state = value.translation.height
            }
            .updating(self.$isDragActive) { _, state, _ in
                state = true
            }
            .onEnded { value in
                self.handleDragEnded(translation: value.translation.height, velocity: value.velocity.height)
            }
    }
}

// MARK: - Method

private extension MapSearchPanelView {
    func handleDragEnded(translation: CGFloat, velocity: CGFloat) {
        if translation > 0 {
            self.handleDownwardDragEnded(translation: translation, velocity: velocity)
        } else {
            self.handleUpwardDragEnded(translation: translation, velocity: velocity)
        }
    }

    func handleUpwardDragEnded(translation: CGFloat, velocity: CGFloat) {
        let shouldAdvance = translation <= -MapSearchPanelLayout.upwardMinimumDrag
            || velocity <= -MapSearchPanelLayout.upwardFlickVelocity
        guard shouldAdvance else { return }

        guard let nextStage = self.nextHigherStage(from: self.displayedStage) else { return }

        self.displayedStage = nextStage
        self.onStageChanged(nextStage)
    }

    func handleDownwardDragEnded(translation: CGFloat, velocity: CGFloat) {
        let shouldAdvance = translation >= MapSearchPanelLayout.downwardMinimumDrag
            || velocity >= MapSearchPanelLayout.downwardFlickVelocity
        guard shouldAdvance else { return }

        guard let nextStage = self.nextLowerStage(from: self.displayedStage) else {
            self.onDismiss()
            return
        }

        // .collapsed는 지도 드래그(mapDragged) 등 시스템 트리거로만 진입해야 하므로,
        // 사용자가 half에서 아래로 드래그해 .collapsed에 도달하려는 시도는 dismiss로 대체한다
        guard nextStage != .collapsed else {
            self.onDismiss()
            return
        }

        self.displayedStage = nextStage
        self.onStageChanged(nextStage)
    }

    func nextLowerStage(from stage: MapPanelStage) -> MapPanelStage? {
        switch stage {
        case .full: return .half
        case .half: return .collapsed
        case .collapsed: return nil
        }
    }

    func nextHigherStage(from stage: MapPanelStage) -> MapPanelStage? {
        switch stage {
        case .collapsed: return .half
        case .half: return .full
        case .full: return nil
        }
    }
}
