//
//  KoreanPhraseRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain

struct KoreanPhraseRow: View {
    let phrase: KoreanPhrase
    let onTap: () -> Void

    var body: some View {
        Button(action: self.onTap) {
            TabiCard {
                VStack(alignment: .leading, spacing: 4) {
                    TabiLabel(title: self.phrase.korean, style: .bodyMBold, color: .tabiTextPrimary)
                    TabiLabel(title: self.phrase.japanese, style: .bodyS, color: .tabiTextSecondary)
                    if let pronunciation = self.phrase.pronunciation, pronunciation.isEmpty == false {
                        TabiLabel(title: pronunciation, style: .captionM, color: .tabiTextTertiary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(TabiPressStyle())
    }
}
