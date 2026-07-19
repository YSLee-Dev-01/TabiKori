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

    var body: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named("detailScroll")).minY
            let height = minY > 0 ? Self.heroHeight + minY : Self.heroHeight

            ZStack {
                if self.images.isEmpty {
                    self.fallbackImage(height: height)
                } else {
                    self.imagePager(height: height)
                }
                self.bottomGradient(height: height)
                self.topGradient(height: height)
            }
            .frame(height: height)
            .offset(y: minY > 0 ? -minY : 0)
            .overlay(alignment: .bottom) { self.pageIndicator() }
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

    @ViewBuilder
    func pageIndicator() -> some View {
        if self.images.count > 1 {
            HStack(spacing: 6) {
                ForEach(Array(self.images.enumerated()), id: \.element.imageURLString) { index, _ in
                    Circle()
                        .fill(
                            index == self.currentIndex
                                ? Color.getTabiColor(.tabiPrimary)
                                : Color.white.opacity(0.6)
                        )
                        .frame(
                            width: index == self.currentIndex ? 6 : 5,
                            height: index == self.currentIndex ? 6 : 5
                        )
                }
            }
            .padding(.bottom, 16)
        }
    }
}
