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
    @Binding var isZoomed: Bool

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(self.scale)
                .offset(self.offset)
                .gesture(self.dragGesture(in: proxy.size), including: self.scale > Self.minScale ? .all : .subviews)
                .gesture(self.magnificationGesture(in: proxy.size))
                .onChange(of: self.scale) { _, newValue in
                    self.isZoomed = newValue > Self.minScale
                }
                .onChange(of: self.isActive) { _, isActive in
                    guard isActive == false else { return }
                    self.resetTransform()
                }
        }
    }
}

// MARK: - Gesture

private extension ZoomableImageView {
    func magnificationGesture(in size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                self.scale = self.clampedScale(self.lastScale * value)
            }
            .onEnded { _ in
                self.lastScale = self.scale
                self.offset = self.clampedOffset(self.offset, scale: self.scale, containerSize: size)
                self.lastOffset = self.offset
                if self.scale == Self.minScale {
                    self.resetTransform()
                }
            }
    }

    func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let candidate = CGSize(
                    width: self.lastOffset.width + value.translation.width,
                    height: self.lastOffset.height + value.translation.height
                )
                self.offset = self.clampedOffset(candidate, scale: self.scale, containerSize: size)
            }
            .onEnded { _ in
                self.lastOffset = self.offset
            }
    }

    func clampedScale(_ value: CGFloat) -> CGFloat {
        min(max(value, Self.minScale), Self.maxScale)
    }

    func clampedOffset(_ offset: CGSize, scale: CGFloat, containerSize: CGSize) -> CGSize {
        let maxOffsetX = max(0, containerSize.width * (scale - 1) / 2)
        let maxOffsetY = max(0, containerSize.height * (scale - 1) / 2)
        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }

    func resetTransform() {
        withAnimation(.tabiFast) {
            self.scale = 1.0
            self.lastScale = 1.0
            self.offset = .zero
            self.lastOffset = .zero
        }
    }
}
