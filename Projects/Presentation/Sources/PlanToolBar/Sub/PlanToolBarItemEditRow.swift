//
//  PlanToolBarItemEditRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

/// 준비물 편집모드 행. 제목을 TextField로 노출해 이름 수정이 가능하다. 삭제는 List의 .onDelete로 처리
struct PlanToolBarItemEditRow: View {
    @Binding var title: String
    let note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TabiTextField(placeholder: Strings.ToolBar.addItemPlaceholder, text: self.$title)
            if let note, note.isEmpty == false {
                TabiLabel(title: note, style: .captionM, color: .tabiTextTertiary)
                    .padding(.leading, 14)
            }
        }
    }
}
