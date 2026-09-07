//
//  RegionSpotHeroView.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Domain
import Resource

struct RegionSpotHeroView: View {
    static let coordinateSpaceName = "regionSpotScroll"

    private static let heroHeight: CGFloat = 280

    let image: TabiImage?

    var body: some View {
        if let image {
            GeometryReader { proxy in
                let minY = proxy.frame(in: .named(Self.coordinateSpaceName)).minY
                let height = minY > 0 ? Self.heroHeight + minY : Self.heroHeight

                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .clipped()
                    .offset(y: minY > 0 ? -minY : 0)
            }
            .frame(height: Self.heroHeight)
        }
    }
}
