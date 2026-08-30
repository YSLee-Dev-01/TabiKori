//
//  PlanWidgetView.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import WidgetKit

import Domain
import Resource

struct PlanWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: PlanWidgetEntry

    var body: some View {
        Group {
            if let item = self.entry.item {
                switch self.family {
                case .systemMedium: self.mediumContent(item)
                default: self.smallContent(item)
                }
            } else {
                self.emptyContent
            }
        }
        .containerBackground(for: .widget) {
            Color.getTabiColor(.tabiBackground)
        }
        .widgetURL(self.entry.item.map { WidgetDeepLink.planDetail($0.id).url } ?? nil)
    }
}

// MARK: - View

private extension PlanWidgetView {
    func smallContent(_ item: PlanWidgetSnapshotItem) -> some View {
        VStack(alignment: .leading, spacing: WidgetStyle.contentSpacing) {
            Text(item.emoji)
                .font(.system(size: 28))

            Spacer(minLength: 0)

            Text(item.title)
                .font(WidgetFont.pretendard(.semiBold, size: 15))
                .foregroundStyle(Color.getTabiColor(.tabiTextPrimary))
                .lineLimit(2)

            Text(self.badgeTitle(item))
                .font(WidgetFont.pretendard(size: 12))
                .foregroundStyle(Color.getTabiColor(.tabiTextSecondary))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WidgetStyle.contentPadding)
    }

    func mediumContent(_ item: PlanWidgetSnapshotItem) -> some View {
        HStack(alignment: .top, spacing: WidgetStyle.contentSpacing * 2) {
            Text(item.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: WidgetStyle.contentSpacing) {
                Text(item.title)
                    .font(WidgetFont.pretendard(.semiBold, size: 16))
                    .foregroundStyle(Color.getTabiColor(.tabiTextPrimary))
                    .lineLimit(1)

                Text(item.regionTitle)
                    .font(WidgetFont.pretendard(size: 13))
                    .foregroundStyle(Color.getTabiColor(.tabiTextSecondary))

                Text(self.badgeTitle(item))
                    .font(WidgetFont.pretendard(.semiBold, size: 13))
                    .foregroundStyle(Color.getTabiColor(.tabiPrimary))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WidgetStyle.contentPadding)
    }

    var emptyContent: some View {
        Text(Strings.Widget.planEmptyTitle)
            .font(WidgetFont.pretendard(size: 13))
            .foregroundStyle(Color.getTabiColor(.tabiTextSecondary))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(WidgetStyle.contentPadding)
    }

    func badgeTitle(_ item: PlanWidgetSnapshotItem) -> String {
        if let dayIndex = self.entry.dayIndex {
            return Strings.Plan.dayChipTitle(dayIndex + 1)
        }
        let daysUntilStart = self.entry.daysUntilStart ?? item.daysUntilStart(on: self.entry.date)
        if daysUntilStart <= 0 {
            return Strings.Widget.planStartsToday
        }
        return Strings.Widget.planDaysUntilStart(daysUntilStart)
    }
}
