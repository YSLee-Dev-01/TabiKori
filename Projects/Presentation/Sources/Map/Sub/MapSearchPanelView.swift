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
}

struct MapSearchPanelView<Content: View>: View {

    // MARK: - Properties

    private let stage: MapPanelStage
    private let collapsedHeight: CGFloat
    private let halfHeight: CGFloat
    private let fullHeight: CGFloat
    private let onStageChanged: (MapPanelStage) -> Void
    private let onDismiss: () -> Void
    private let content: Content

    @GestureState private var dragTranslation: CGFloat = 0

    private var baseHeight: CGFloat {
        switch self.stage {
        case .collapsed: return self.collapsedHeight
        case .half: return self.halfHeight
        case .full: return self.fullHeight
        }
    }

    private var currentHeight: CGFloat {
        max(0, self.baseHeight - self.dragTranslation)
    }

    // MARK: - Init

    init(
        stage: MapPanelStage,
        collapsedHeight: CGFloat,
        halfHeight: CGFloat,
        fullHeight: CGFloat,
        onStageChanged: @escaping (MapPanelStage) -> Void,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.stage = stage
        self.collapsedHeight = collapsedHeight
        self.halfHeight = halfHeight
        self.fullHeight = fullHeight
        self.onStageChanged = onStageChanged
        self.onDismiss = onDismiss
        self.content = content()
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            self.dragHandle()
            self.content
        }
        .frame(maxWidth: .infinity)
        .frame(height: self.currentHeight)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: .tabiRadiusXl, topTrailingRadius: .tabiRadiusXl)
                .fill(TabiColor.tabiSurface)
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .animation(.tabiSpring, value: self.stage)
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
            .updating(self.$dragTranslation) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                self.handleDragEnded(predictedTranslation: value.predictedEndTranslation.height)
            }
    }
}

// MARK: - Method

private extension MapSearchPanelView {
    func handleDragEnded(predictedTranslation: CGFloat) {
        let finalHeight = max(0, self.baseHeight - predictedTranslation)
        guard finalHeight >= self.collapsedHeight / 2 else {
            self.onDismiss()
            return
        }

        let stages: [(stage: MapPanelStage, height: CGFloat)] = [
            (.collapsed, self.collapsedHeight),
            (.half, self.halfHeight),
            (.full, self.fullHeight)
        ]
        let nearestStage = stages.min { lhs, rhs in
            abs(lhs.height - finalHeight) < abs(rhs.height - finalHeight)
        }?.stage ?? self.stage

        self.onStageChanged(nearestStage)
    }
}
