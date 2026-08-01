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
    static let fastFlickVelocityThreshold: CGFloat = 800
    static let minimumMeaningfulDrag: CGFloat = 12
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
    @State private var dragOffset: CGFloat = 0
    @State private var settleTrigger: Int = 0
    @State private var isDragging: Bool = false

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
        .animation(.tabiSpring, value: self.settleTrigger)
        .onChange(of: self.stage) { _, newValue in
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
        DragGesture()
            .onChanged { value in
                if self.isDragging == false {
                    self.isDragging = true
                    self.onDragStarted()
                }
                self.dragOffset = value.translation.height
            }
            .onEnded { value in
                self.isDragging = false
                self.onDragEnded()
                self.handleDragEnded(translation: value.translation.height, velocity: value.velocity.height)
            }
    }
}

// MARK: - Method

private extension MapSearchPanelView {
    func handleDragEnded(translation: CGFloat, velocity: CGFloat) {
        self.dragOffset = 0

        if translation > 0 {
            self.handleDownwardDragEnded(translation: translation, velocity: velocity)
        } else {
            self.handleUpwardDragEnded(translation: translation, velocity: velocity)
        }
    }

    func handleUpwardDragEnded(translation: CGFloat, velocity: CGFloat) {
        guard velocity > -MapSearchPanelLayout.fastFlickVelocityThreshold else {
            let nextStage = self.nextHigherStage(from: self.displayedStage) ?? self.displayedStage
            self.displayedStage = nextStage
            self.settleTrigger += 1
            self.onStageChanged(nextStage)
            return
        }

        guard translation <= -MapSearchPanelLayout.minimumMeaningfulDrag else {
            self.settleTrigger += 1
            return
        }

        guard let nextStage = self.nextHigherStage(from: self.displayedStage) else {
            self.settleTrigger += 1
            return
        }

        self.displayedStage = nextStage
        self.settleTrigger += 1
        self.onStageChanged(nextStage)
    }

    func handleDownwardDragEnded(translation: CGFloat, velocity: CGFloat) {
        guard velocity < MapSearchPanelLayout.fastFlickVelocityThreshold else {
            self.settleTrigger += 1
            self.onDismiss()
            return
        }

        guard translation >= MapSearchPanelLayout.minimumMeaningfulDrag else {
            self.settleTrigger += 1
            return
        }

        guard let nextStage = self.nextLowerStage(from: self.displayedStage) else {
            self.settleTrigger += 1
            self.onDismiss()
            return
        }

        self.displayedStage = nextStage
        self.settleTrigger += 1
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
