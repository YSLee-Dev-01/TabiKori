//
//  TabiPageIndicator.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/20/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

public struct TabiPageIndicator: View {
    private let count: Int
    private let currentIndex: Int

    public init(count: Int, currentIndex: Int) {
        self.count = count
        self.currentIndex = currentIndex
    }

    public var body: some View {
        if self.count > 1 {
            HStack(spacing: 6) {
                ForEach(0..<self.count, id: \.self) { index in
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
        }
    }
}
