//
//  TabiAnnouncementView.swift
//  DesignSystem
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

/// 팝업 공지(Root) / 홈 화면 시트 공지(Home)에서 공용으로 사용하는 공지 표시 컴포넌트.
/// Domain을 의존하지 않기 위해 title/subtitle/content를 원시 String으로 받는다.
public struct TabiAnnouncementView: View {

    public struct DoNotShowTodayOption {
        let isChecked: Bool
        let onToggle: () -> Void

        public init(isChecked: Bool, onToggle: @escaping () -> Void) {
            self.isChecked = isChecked
            self.onToggle = onToggle
        }
    }

    private let title: String
    private let subtitle: String
    private let content: String
    private let doNotShowTodayOption: DoNotShowTodayOption?
    private let onClose: () -> Void

    public init(
        title: String,
        subtitle: String,
        content: String,
        doNotShowTodayOption: DoNotShowTodayOption? = nil,
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.doNotShowTodayOption = doNotShowTodayOption
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                TabiLabel(title: self.title, style: .titleM, color: .tabiTextPrimary)

                if self.subtitle.isEmpty == false {
                    TabiLabel(title: self.subtitle, style: .bodyS, color: .tabiTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                TabiLabel(title: self.content, style: .bodyM, color: .tabiTextPrimary, isExpanded: true)
            }

            VStack(spacing: 12) {
                if let doNotShowTodayOption = self.doNotShowTodayOption {
                    self.doNotShowTodayRow(doNotShowTodayOption)
                }

                TabiButton(Strings.Notice.closeButtonTitle, style: .primary, isExpanded: true) {
                    self.onClose()
                }
            }
        }
        .padding(24)
    }
}

// MARK: - View

private extension TabiAnnouncementView {
    func doNotShowTodayRow(_ option: DoNotShowTodayOption) -> some View {
        Button {
            option.onToggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: option.isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(option.isChecked ? TabiColor.tabiPrimary : TabiColor.tabiTextTertiary)

                TabiLabel(title: Strings.Notice.doNotShowTodayLabel, style: .bodyS, color: .tabiTextSecondary)

                Spacer()
            }
        }
        .buttonStyle(TabiPressStyle())
    }
}
