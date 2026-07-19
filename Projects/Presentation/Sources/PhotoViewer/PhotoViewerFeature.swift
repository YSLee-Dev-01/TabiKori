//
//  PhotoViewerFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain

@Reducer
public struct PhotoViewerFeature {

    @ObservableState
    public struct State: Equatable {
        let images: [TouristSpotImage]
        let title: String
        var currentIndex: Int

        public init(images: [TouristSpotImage], startIndex: Int, title: String) {
            self.images = images
            self.title = title
            self.currentIndex = images.indices.contains(startIndex) ? startIndex : 0
        }
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
    }
}
