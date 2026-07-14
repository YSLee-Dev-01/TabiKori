//
//  DetailPhotosTabView.swift
//  Presentation
//
//  Created by 이윤수 on 7/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Kingfisher

struct DetailPhotosTabView: View {
    let images: [TouristSpotImage]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(self.images, id: \.imageURLString) { image in
                self.photoCell(image)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - View

private extension DetailPhotosTabView {
    func photoCell(_ image: TouristSpotImage) -> some View {
        GeometryReader { proxy in
            KFImage(image.thumbnailURL)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: .tabiRadiusMd))
        .contentShape(Rectangle())
    }
}
