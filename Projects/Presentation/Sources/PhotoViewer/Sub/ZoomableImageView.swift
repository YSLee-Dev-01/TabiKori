//
//  ZoomableImageView.swift
//  Presentation
//
//  Created by 이윤수 on 7/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Kingfisher
import Resource

struct ZoomableImageView: View {
    private static let minScale: CGFloat = 1.0
    private static let maxScale: CGFloat = 4.0

    let imageURL: URL?
    let isActive: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        KFImage(self.imageURL)
            .placeholder {
                Color.getTabiColor(.tabiBorder).opacity(0.3)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundStyle(TabiColor.tabiTextTertiary)
                    }
            }
            .resizable()
            .scaledToFit()
            .scaleEffect(self.scale)
            .gesture(self.magnificationGesture)
            .onChange(of: self.isActive) { _, isActive in
                guard isActive == false else { return }
                withAnimation(.tabiFast) {
                    self.scale = 1.0
                    self.lastScale = 1.0
                }
            }
    }
}

// MARK: - Gesture

private extension ZoomableImageView {
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                self.scale = self.clampedScale(self.lastScale * value)
            }
            .onEnded { _ in
                self.lastScale = self.scale
            }
    }

    func clampedScale(_ value: CGFloat) -> CGFloat {
        min(max(value, Self.minScale), Self.maxScale)
    }
}
