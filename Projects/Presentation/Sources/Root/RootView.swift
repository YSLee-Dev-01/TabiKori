//
//  RootView.swift
//  Presentation
//
//  Created by 이윤수 on 6/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Domain
import DesignSystem
import Resource

public struct RootView: View {

    @State private var store: StoreOf<RootFeature>

    public init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            if let tabBarStore = self.store.scope(state: \.tabBarState, action: \.tabBar) {
                TabBarView(store: tabBarStore)
            } else {
                #if DEBUG
                Button {
                    self.store.send(.testBtnTapped)
                } label: {
                    Text(Strings.Root.onboardingCompleteButton)
                }
                #endif
            }
        }
        .onAppear {
            self.store.send(.onAppear)
        }
        .tabiToast(
            message: self.store.currentToast?.message,
            style: self.toastStyle(for: self.store.currentToast?.type),
            actionButtonTitle: self.store.currentToast?.actionButtonTitle,
            onActionTapped: { self.store.send(.toastActionButtonTapped) }
        )
    }
}

// MARK: - Method

private extension RootView {
    func toastStyle(for type: ToastType?) -> TabiToast.Style {
        switch type {
        case .success: return .success
        case .info: return .info
        case .error, .none: return .error
        }
    }
}

#Preview {
    RootView(store: .init(
        initialState: .init(),
        reducer: {
            RootFeature()
        }))
}
