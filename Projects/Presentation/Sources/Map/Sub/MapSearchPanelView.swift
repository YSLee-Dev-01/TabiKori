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
        max(0, self.baseHeight - self.dragOffset)
    }

    private var hiddenOffset: CGFloat {
        max(0, self.fullHeight - self.currentHeight)
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
        }
        .frame(maxWidth: .infinity)
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
