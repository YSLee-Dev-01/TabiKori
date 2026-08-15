//
//  TabiMapMarkerPinView.swift
//  DesignSystem
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

struct TabiMapMarkerPinView: View {
    let icon: TabiIcon
    let color: TabiColor
    let index: Int?

    var body: some View {
        Circle()
            .fill(self.color)
            .overlay {
                Circle()
                    .stroke(TabiColor.tabiOnColor, lineWidth: 2)
            }
            .overlay {
                if let index {
                    Text("\(index)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(TabiColor.tabiOnColor)
                } else {
                    Image(self.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TabiColor.tabiOnColor)
                }
            }
            .frame(width: 30, height: 30)
    }
}
