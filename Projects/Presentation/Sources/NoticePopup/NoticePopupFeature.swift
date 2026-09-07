//
//  NoticePopupFeature.swift
//  Presentation
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain

@Reducer
public struct NoticePopupFeature: Sendable {

    @Dependency(\.noticePopupUseCase) var noticePopupUseCase
    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        var announcement: Announcement
        var isDoNotShowTodayChecked: Bool = false

        public init(announcement: Announcement) {
            self.announcement = announcement
        }
    }

    public enum Action: Equatable {
        case doNotShowTodayToggled
        case closeButtonTapped
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .doNotShowTodayToggled:
                state.isDoNotShowTodayChecked.toggle()
                return .none

            case .closeButtonTapped:
                return self.closeEffect(
                    shouldMarkDismissed: state.isDoNotShowTodayChecked,
                    announcementId: state.announcement.id
                )
            }
        }
    }
}

// MARK: - Method

private extension NoticePopupFeature {
    func closeEffect(shouldMarkDismissed: Bool, announcementId: String) -> Effect<Action> {
        .run { [noticePopupUseCase = self.noticePopupUseCase, dismiss = self.dismiss] _ in
            if shouldMarkDismissed {
                noticePopupUseCase.markDismissedToday(id: announcementId)
            }
            await dismiss()
        }
    }
}
