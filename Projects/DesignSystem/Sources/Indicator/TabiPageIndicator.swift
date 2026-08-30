//
//  TabiPageIndicator.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/20/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

public struct TabiPageIndicator: View {
    private static let spacing: CGFloat = 6
    private static let maxRows = 2

    private let count: Int
    private let currentIndex: Int
    private let inactiveColor: Color

    public init(count: Int, currentIndex: Int, inactiveColor: Color = .white.opacity(0.6)) {
        self.count = count
        self.currentIndex = currentIndex
        self.inactiveColor = inactiveColor
    }

    public var body: some View {
        if self.count > 1 {
            WrappingDotLayout(spacing: Self.spacing, maxRows: Self.maxRows) {
                ForEach(0..<self.count, id: \.self) { index in
                    self.dot(isSelected: index == self.currentIndex)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - View

private extension TabiPageIndicator {
    func dot(isSelected: Bool) -> some View {
        Circle()
            .fill(
                isSelected
                    ? Color.getTabiColor(.tabiPrimary)
                    : self.inactiveColor
            )
            .frame(
                width: isSelected ? 6 : 5,
                height: isSelected ? 6 : 5
            )
    }
}

// MARK: - WrappingDotLayout

/// 점(dot) 개수가 한 줄 너비를 초과하면 최대 `maxRows` 줄로 나눠 배치하는 Layout.
/// 부모가 제안한 너비(`ProposedViewSize`)를 기준으로 줄바꿈 지점을 계산한다
private struct WrappingDotLayout: Layout {
    let spacing: CGFloat
    let maxRows: Int

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = self.makeRows(subviews: subviews, maxWidth: proposal.width ?? .infinity)
        let rowHeights = rows.map { row in row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0 }
        let totalHeight = rowHeights.reduce(0, +) + CGFloat(max(rows.count - 1, 0)) * self.spacing
        let totalWidth = rows.map { self.rowWidth($0, subviews: subviews) }.max() ?? 0
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = self.makeRows(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            let rowWidth = self.rowWidth(row, subviews: subviews)
            var x = bounds.minX + (bounds.width - rowWidth) / 2
            for index in row {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + self.spacing
            }
            y += rowHeight + self.spacing
        }
    }
}

// MARK: - Method

private extension WrappingDotLayout {
    func makeRows(subviews: Subviews, maxWidth: CGFloat) -> [[Int]] {
        guard maxWidth.isFinite, maxWidth > 0 else { return [Array(subviews.indices)] }

        var rows: [[Int]] = [[]]
        var currentRowWidth: CGFloat = 0

        for index in subviews.indices {
            let itemWidth = subviews[index].sizeThatFits(.unspecified).width
            let candidateWidth = currentRowWidth == 0 ? itemWidth : currentRowWidth + self.spacing + itemWidth

            if candidateWidth > maxWidth, rows.count < self.maxRows, !rows[rows.count - 1].isEmpty {
                rows.append([index])
                currentRowWidth = itemWidth
            } else {
                rows[rows.count - 1].append(index)
                currentRowWidth = candidateWidth
            }
        }

        return rows
    }

    func rowWidth(_ row: [Int], subviews: Subviews) -> CGFloat {
        let itemsWidth = row.reduce(CGFloat(0)) { partial, index in partial + subviews[index].sizeThatFits(.unspecified).width }
        return itemsWidth + CGFloat(max(row.count - 1, 0)) * self.spacing
    }
}
