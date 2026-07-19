//
//  PhotoViewerView.swift
//  Presentation
//
//  Created by 이윤수 on 7/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Domain
import Resource

struct PhotoViewerView: View {
    @Bindable private var store: StoreOf<PhotoViewerFeature>

    @Environment(\.dismiss) private var dismiss

    init(store: StoreOf<PhotoViewerFeature>) {
        self.store = store
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            self.pager()
        }
        .overlay(alignment: .top) { self.topBar() }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - View

private extension PhotoViewerView {
    func pager() -> some View {
        TabView(selection: self.$store.currentIndex) {
            ForEach(Array(self.store.images.enumerated()), id: \.element.imageURLString) { index, image in
                ZoomableImageView(imageURL: image.imageURL, isActive: index == self.store.currentIndex)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    func topBar() -> some View {
        HStack(spacing: 12) {
            TabiGlassIconButton(systemName: "chevron.left") {
                self.dismiss()
            }
            TabiLabel(title: self.store.title, style: .titleS, color: .tabiOnColor)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

#Preview {
    PhotoViewerView(
        store: Store(
            initialState: PhotoViewerFeature.State(images: .mock, startIndex: 0, title: "景福宮"),
            reducer: { PhotoViewerFeature() }
        )
    )
}
