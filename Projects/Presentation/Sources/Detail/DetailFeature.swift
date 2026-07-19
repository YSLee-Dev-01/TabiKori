//
//  DetailFeature.swift
//  Presentation
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Domain
import Resource

public enum DetailTab: String, CaseIterable, Equatable {
    case info
    case photos
    case map

    var label: String {
        switch self {
        case .info: return Strings.Detail.tabInfo
        case .photos: return Strings.Detail.tabPhotos
        case .map: return Strings.Detail.tabMap
        }
    }
}

@Reducer
public struct DetailFeature {

    @ObservableState
    public struct State: Equatable {
        let touristSpot: TouristSpot
        var detail: TouristSpotDetail = .mock
        var intro: TouristSpotIntro = .mock
        var images: [TouristSpotImage] = .mock
        var selectedTab: DetailTab = .info
        var isSaved: Bool = false
        var currentImageIndex: Int = 0
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case tabSelected(DetailTab)
        case saveButtonTapped
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none
            case .saveButtonTapped:
                state.isSaved.toggle()
                return .none
            case .binding:
                return .none
            }
        }
    }
}
