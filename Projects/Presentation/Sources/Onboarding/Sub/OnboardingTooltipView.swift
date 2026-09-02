//
//  OnboardingTooltipView.swift
//  Presentation
//
//  Created by Claude on 8/30/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 스포트라이트 홀 옆에 표시되는 유도 말풍선.
/// 홀이 화면 위쪽 절반에 있으면 말풍선을 아래에(꼬리가 위를 가리킴),
/// 홀이 아래쪽 절반에 있으면 말풍선을 위에(꼬리가 아래를 가리킴) 배치하고, 좌우 화면 경계 안으로 클램프한다.
/// 말풍선 너비를 고정값으로 결정해 런타임 자체 측정 없이도 위치를 정확히 계산한다
struct OnboardingTooltipView: View {
    fileprivate enum TailEdge {
        case top
        case bottom
    }

    let text: String
    let highlightRect: CGRect
    let containerSize: CGSize

    var body: some View {
        ZStack(alignment: self.showsBelow ? .topLeading : .bottomLeading) {
            Color.clear

            self.bubble()
                .offset(x: self.leftX, y: self.offsetY)
        }
        .frame(width: self.containerSize.width, height: self.containerSize.height)
        .allowsHitTesting(false)
    }
}

// MARK: - View

private extension OnboardingTooltipView {
    func bubble() -> some View {
        VStack(spacing: 0) {
            if self.tailEdge == .top {
                self.tail(pointingUp: true)
                    .offset(x: self.tailOffsetX)
            }

            TabiLabel(title: self.text, style: .bodyMBold, color: .tabiOnColor)
                .multilineTextAlignment(.center)
                .frame(width: self.bubbleWidth - 32)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(TabiColor.tabiPrimary)
                .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))

            if self.tailEdge == .bottom {
                self.tail(pointingUp: false)
                    .offset(x: self.tailOffsetX)
            }
        }
    }

    func tail(pointingUp: Bool) -> some View {
        OnboardingTooltipTail(pointingUp: pointingUp)
            .fill(TabiColor.tabiPrimary)
            .frame(width: 16, height: 8)
    }
}

// MARK: - Method

private extension OnboardingTooltipView {
    var bubbleWidth: CGFloat {
        min(260, max(160, self.containerSize.width - 40))
    }

    var showsBelow: Bool {
        self.highlightRect.midY < self.containerSize.height / 2
    }

    var tailEdge: TailEdge {
        self.showsBelow ? .top : .bottom
    }

    var leftX: CGFloat {
        min(
            max(self.highlightRect.midX - self.bubbleWidth / 2, 20),
            self.containerSize.width - self.bubbleWidth - 20
        )
    }

    var offsetY: CGFloat {
        self.showsBelow
            ? self.highlightRect.maxY + 12
            : self.highlightRect.minY - 12 - self.containerSize.height
    }

    /// 말풍선이 화면 경계에 부딪혀 클램프되어도, 꼬리는 항상 강조 대상의 중심(`highlightRect.midX`)을
    /// 가리키도록 말풍선 로컬 좌표계 기준 위치를 계산한다(말풍선 중앙 대비 오프셋, 모서리 밖으로 나가지
    /// 않도록 tail 폭의 절반만큼 여백을 둔다)
    var tailOffsetX: CGFloat {
        let tailHalfWidth: CGFloat = 8
        let targetX = min(
            max(self.highlightRect.midX - self.leftX, tailHalfWidth),
            self.bubbleWidth - tailHalfWidth
        )
        return targetX - self.bubbleWidth / 2
    }
}

private struct OnboardingTooltipTail: Shape {
    let pointingUp: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if self.pointingUp {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}
