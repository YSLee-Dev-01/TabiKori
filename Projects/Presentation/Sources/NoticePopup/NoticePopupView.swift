//
//  NoticePopupView.swift
//  Presentation
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain

public struct NoticePopupView: View {

    @Bindable private var store: StoreOf<NoticePopupFeature>

    public init(store: StoreOf<NoticePopupFeature>) {
        self.store = store
    }

    public var body: some View {
        TabiAnnouncementView(
            title: self.store.announcement.title,
            subtitle: self.store.announcement.subtitle,
            content: self.store.announcement.content,
            doNotShowTodayOption: .init(
                isChecked: self.store.isDoNotShowTodayChecked,
                onToggle: { self.store.send(.doNotShowTodayToggled) }
            ),
            onClose: { self.store.send(.closeButtonTapped) }
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
