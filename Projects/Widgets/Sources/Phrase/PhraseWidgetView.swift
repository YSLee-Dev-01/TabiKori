//
//  PhraseWidgetView.swift
//  Widget
//
//  Created by 이윤수 on 8/29/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import WidgetKit

import Domain
import Resource

struct PhraseWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: PhraseWidgetEntry

    var body: some View {
        Group {
            if let phrase = self.entry.phrase {
                switch self.family {
                case .systemMedium: self.mediumContent(phrase)
                default: self.smallContent(phrase)
                }
            } else {
                self.emptyContent
            }
        }
        .containerBackground(for: .widget) {
            Color.getTabiColor(.tabiBackground)
        }
        .widgetURL(WidgetDeepLink.koreanPhraseList.url)
    }
}

// MARK: - View

private extension PhraseWidgetView {
    func smallContent(_ phrase: PhraseWidgetSnapshotItem) -> some View {
        VStack(alignment: .leading, spacing: WidgetStyle.contentSpacing) {
            Text(phrase.korean)
                .font(WidgetFont.pretendard(.semiBold, size: 17))
                .foregroundStyle(Color.getTabiColor(.tabiTextPrimary))
                .lineLimit(2)

            Text(phrase.japanese)
                .font(WidgetFont.pretendard(size: 13))
                .foregroundStyle(Color.getTabiColor(.tabiTextSecondary))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WidgetStyle.contentPadding)
    }

    func mediumContent(_ phrase: PhraseWidgetSnapshotItem) -> some View {
        VStack(alignment: .leading, spacing: WidgetStyle.contentSpacing) {
            Text(phrase.korean)
                .font(WidgetFont.pretendard(.semiBold, size: 20))
                .foregroundStyle(Color.getTabiColor(.tabiTextPrimary))
                .lineLimit(1)

            Text(phrase.japanese)
                .font(WidgetFont.pretendard(size: 15))
                .foregroundStyle(Color.getTabiColor(.tabiTextSecondary))
                .lineLimit(1)

            if let pronunciation = phrase.pronunciation, !pronunciation.isEmpty {
                Text(pronunciation)
                    .font(WidgetFont.pretendard(size: 13))
                    .foregroundStyle(Color.getTabiColor(.tabiTextTertiary))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WidgetStyle.contentPadding)
    }

    var emptyContent: some View {
        Text(Strings.Widget.phraseEmptyTitle)
            .font(WidgetFont.pretendard(size: 13))
            .foregroundStyle(Color.getTabiColor(.tabiTextSecondary))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(WidgetStyle.contentPadding)
    }
}
