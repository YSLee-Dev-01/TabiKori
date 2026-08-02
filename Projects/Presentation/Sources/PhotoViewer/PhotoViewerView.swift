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
    
    fileprivate var currentIndexBinding: Binding<Int?> {
        Binding(
            get: { self.store.currentIndex },
            set: { newValue in
                guard let newValue else { return }
                self.store.currentIndex = newValue
            }
        )
    }


    init(store: StoreOf<PhotoViewerFeature>) {
        self.store = store
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            self.pager()
                .ignoresSafeArea()
        }
        .overlay(alignment: .bottom) {
            TabiPageIndicator(count: self.store.images.count, currentIndex: self.store.currentIndex)
                .padding(.bottom, 16)
        }
        .navigationTitle(self.store.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .interactivePopGestureEnabled(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .tint(Color.getTabiColor(.tabiPrimary))
            }
        }
    }
}

// MARK: - View

private extension PhotoViewerView {
    func pager() -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(self.store.images.enumerated()), id: \.offset) { index, image in
                    ZoomableImageView(imageURL: image.imageURL, isActive: index == self.store.currentIndex)
                        .containerRelativeFrame(.horizontal)
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: self.currentIndexBinding)
        .scrollIndicators(.hidden)
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
