//
//  DetailView.swift
//  Presentation
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import Domain

struct DetailView: View {
    let store: StoreOf<DetailFeature>
    let namespace: Namespace.ID

    var body: some View {
        Text("DetailView")
            .navigationTransition(.zoom(sourceID: self.store.touristSpot.id, in: self.namespace))
    }
}

#Preview {
    @Previewable @Namespace var namespace

    DetailView(
        store: Store(
            initialState: DetailFeature.State(
                touristSpot: TouristSpot(
                    id: "1",
                    title: "샘플 관광지",
                    thumbnailURLString: nil,
                    distanceMeters: nil,
                    contentType: .sightseeing
                )
            ),
            reducer: { DetailFeature() }
        ),
        namespace: namespace
    )
}
