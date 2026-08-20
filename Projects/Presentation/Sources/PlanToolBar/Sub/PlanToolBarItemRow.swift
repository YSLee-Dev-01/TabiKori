//
//  PlanToolBarItemRow.swift
//  Presentation
//
//  Created by 이윤수 on 8/18/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

/// 준비물 항목 행. 편집모드 여부에 따라 같은 셀 안에서 체크 표시 ↔ 텍스트필드 편집으로 내용만 전환된다.
/// 체크 행과 편집 행을 별개의 ForEach로 분리하면 List가 셀 재사용 시 일부 행에 새 콘텐츠를 반영하지 못하는
/// 문제가 있어, 하나의 행 타입/식별자를 유지한 채 내부에서만 분기한다
struct PlanToolBarItemRow: View {
    @Binding var item: ToolBarPlanItem
    let isEditing: Bool
    /// true인 동안(추가모드)은 체크박스를 숨기고 탭 인터랙션도 비활성화한다
    let isAdding: Bool
    let onTap: () -> Void

    var body: some View {
        Group {
            if self.isEditing {
                self.editContent()
            } else {
                self.checkContent()
            }
        }
        .animation(.tabiStandard, value: self.isEditing)
    }
}

// MARK: - View

private extension PlanToolBarItemRow {
    func checkContent() -> some View {
        Button(action: self.onTap) {
            HStack(spacing: 12) {
                if self.isAdding == false {
                    Image(systemName: self.item.isChecked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(self.item.isChecked ? TabiColor.tabiPrimary : TabiColor.tabiTextTertiary)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 4) {
                    TabiLabel(
                        title: self.item.title,
                        style: .bodyMBold,
                        color: self.item.isChecked ? .tabiTextTertiary : .tabiTextPrimary
                    )
                    if let note = self.item.note, note.isEmpty == false {
                        TabiLabel(title: note, style: .captionM, color: .tabiTextTertiary)
                    }
                }

                Spacer()
            }
            .animation(.tabiFast, value: self.item.isChecked)
        }
        .buttonStyle(TabiPressStyle())
        .disabled(self.isAdding)
    }

    func editContent() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TabiTextField(placeholder: Strings.ToolBar.addItemPlaceholder, text: self.$item.title)

            if self.item.note != nil {
                HStack(spacing: 8) {
                    Color.clear
                        .frame(width: 44)
                    TabiTextField(placeholder: Strings.ToolBar.noteFieldPlaceholder, text: self.noteBinding)
                }
                .padding(.leading, 14)
            }
        }
    }

    var noteBinding: Binding<String> {
        Binding(
            get: { self.item.note ?? "" },
            set: { self.item.note = $0.isEmpty ? nil : $0 }
        )
    }
}
