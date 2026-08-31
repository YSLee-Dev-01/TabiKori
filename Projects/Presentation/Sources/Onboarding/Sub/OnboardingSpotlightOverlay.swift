//
//  OnboardingSpotlightOverlay.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 대상 요소만 하이라이트 홀로 뚫어 보여주고 나머지 영역은 딤 처리 + 탭 차단하는 코치마크 오버레이.
/// 홀 내부에는 히트테스트 가능한 요소가 없으므로 아래의 실제 버튼이 탭을 직접 받는다
struct OnboardingSpotlightOverlay: View {
    let highlightRect: CGRect
    let containerSize: CGSize
    let coachMark: OnboardingCoachMark

    private var expandedRect: CGRect {
        self.highlightRect.insetBy(dx: -self.coachMark.padding, dy: -self.coachMark.padding)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            self.dimLayer()
            self.blockingBands()
            self.holeOutline()
            self.tooltip()
        }
        .frame(width: self.containerSize.width, height: self.containerSize.height)
        .animation(.tabiStandard, value: self.highlightRect)
    }
}

// MARK: - View

private extension OnboardingSpotlightOverlay {
    func dimLayer() -> some View {
        Rectangle()
            .fill(TabiColor.tabiScrim.opacity(0.6))
            .overlay {
                RoundedRectangle(cornerRadius: self.coachMark.cornerRadius)
                    .frame(width: self.expandedRect.width, height: self.expandedRect.height)
                    .position(x: self.expandedRect.midX, y: self.expandedRect.midY)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .allowsHitTesting(false)
    }

    func holeOutline() -> some View {
        RoundedRectangle(cornerRadius: self.coachMark.cornerRadius)
            .stroke(TabiColor.tabiPrimary, lineWidth: 2)
            .frame(width: self.expandedRect.width, height: self.expandedRect.height)
            .position(x: self.expandedRect.midX, y: self.expandedRect.midY)
            .allowsHitTesting(false)
    }

    func blockingBands() -> some View {
        ZStack(alignment: .topLeading) {
            self.blockingBand(
                width: self.containerSize.width,
                height: max(0, self.expandedRect.minY),
                x: self.containerSize.width / 2,
                y: max(0, self.expandedRect.minY) / 2
            )
            self.blockingBand(
                width: self.containerSize.width,
                height: max(0, self.containerSize.height - self.expandedRect.maxY),
                x: self.containerSize.width / 2,
                y: self.expandedRect.maxY + max(0, self.containerSize.height - self.expandedRect.maxY) / 2
            )
            self.blockingBand(
                width: max(0, self.expandedRect.minX),
                height: self.expandedRect.height,
                x: max(0, self.expandedRect.minX) / 2,
                y: self.expandedRect.midY
            )
            self.blockingBand(
                width: max(0, self.containerSize.width - self.expandedRect.maxX),
                height: self.expandedRect.height,
                x: self.expandedRect.maxX + max(0, self.containerSize.width - self.expandedRect.maxX) / 2,
                y: self.expandedRect.midY
            )
        }
    }

    func blockingBand(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .frame(width: width, height: height)
            .position(x: x, y: y)
            .onTapGesture {}
    }

    func tooltip() -> some View {
        OnboardingTooltipView(
            text: self.coachMark.tooltip,
            highlightRect: self.expandedRect,
            containerSize: self.containerSize
        )
    }
}
