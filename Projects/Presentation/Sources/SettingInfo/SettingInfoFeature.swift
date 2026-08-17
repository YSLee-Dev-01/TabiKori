//
//  SettingInfoFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture

@Reducer
public struct SettingInfoFeature: Sendable {

    @Dependency(\.dismiss) var dismiss

    @ObservableState
    public struct State: Equatable {
        let contentType: SettingInfoContentType

        public init(contentType: SettingInfoContentType) {
            self.contentType = contentType
        }
    }

    public enum Action: Equatable {
        case closeTapped
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .closeTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }
            }
        }
    }
}
