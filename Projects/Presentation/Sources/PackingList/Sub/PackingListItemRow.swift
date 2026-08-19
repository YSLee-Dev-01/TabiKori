//
//  PackingListItemRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain

struct PackingListItemRow: View {
    let item: ToolBarItem
    let onTap: () -> Void

    var body: some View {
        Button(action: self.onTap) {
            TabiCard {
                VStack(alignment: .leading, spacing: 4) {
                    TabiLabel(title: self.item.title, style: .bodyMBold, color: .tabiTextPrimary)
                    if let note = self.item.note, note.isEmpty == false {
                        TabiLabel(title: note, style: .captionM, color: .tabiTextSecondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(TabiPressStyle())
    }
}
