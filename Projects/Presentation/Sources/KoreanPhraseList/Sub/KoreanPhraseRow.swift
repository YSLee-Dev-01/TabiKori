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
import Resource

struct KoreanPhraseRow: View {
    let phrase: KoreanPhrase
    let onTap: () -> Void
    let onCopyTapped: () -> Void

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
        // 기본 탭 동작(가로모드 상세 진입)은 그대로 유지하고, 롱프레스 시에만 복사/크게보기 메뉴를 노출한다
        .contextMenu {
            Button(Strings.KoreanPhrase.copyMenuTitle, systemImage: "doc.on.doc") {
                self.onCopyTapped()
            }
            Button(Strings.KoreanPhrase.viewLargeMenuTitle, systemImage: "arrow.up.left.and.arrow.down.right") {
                self.onTap()
            }
        }
    }
}
