//
//  DetailHeroView.swift
//  Presentation
//
//  Created by 이윤수 on 7/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Kingfisher
import Resource

struct DetailHeroView: View {
    private static let heroHeight: CGFloat = 340

    let images: [TouristSpotImage]
    let fallbackImageURL: URL?
    @Binding var currentIndex: Int
    let onImageTapped: (Int) -> Void

    var body: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("detailScroll")).minY
            let height = minY > 0 ? Self.heroHeight + minY : Self.heroHeight

            ZStack {
                if self.images.isEmpty {
                    self.fallbackImage(height: height)
                        .transition(.opacity)
                } else {
                    self.imagePager(height: height)
                        .transition(.opacity)
                }
                self.bottomGradient(height: height)
                self.topGradient(height: height)
            }
            .animation(.tabiStandard, value: self.images.isEmpty)
            .frame(height: height)
            .offset(y: minY > 0 ? -minY : 0)
            .overlay(alignment: .bottom) {
                TabiPageIndicator(count: self.images.count, currentIndex: self.currentIndex)
                    .padding(.bottom, 16)
            }
        }
        .frame(height: Self.heroHeight)
    }
}

// MARK: - View

private extension DetailHeroView {
    func imagePager(height: CGFloat) -> some View {
        TabView(selection: self.$currentIndex) {
            ForEach(Array(self.images.enumerated()), id: \.element.imageURLString) { index, image in
                KFImage(image.imageURL)
                    .placeholder {
                        Color.getTabiColor(.tabiBorder).opacity(0.3)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 28))
                                    .foregroundStyle(TabiColor.tabiTextTertiary)
                            }
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture { self.onImageTapped(index) }
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    func fallbackImage(height: CGFloat) -> some View {
        KFImage(self.fallbackImageURL)
            .placeholder {
                Color.getTabiColor(.tabiBorder).opacity(0.3)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(TabiColor.tabiTextTertiary)
                    }
            }
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
    }

    func bottomGradient(height: CGFloat) -> some View {
        LinearGradient(
            colors: [.clear, Color.getTabiColor(.tabiBackground).opacity(0.7)],
            startPoint: UnitPoint(x: 0.5, y: 0.55),
            endPoint: .bottom
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }

    func topGradient(height: CGFloat) -> some View {
        LinearGradient(
            colors: [Color.black.opacity(0.3), .clear],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.35)
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }
}
