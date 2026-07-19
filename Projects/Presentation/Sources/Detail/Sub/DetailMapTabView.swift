//
//  DetailMapTabView.swift
//  Presentation
//
//  Created by 이윤수 on 7/19/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct DetailMapTabView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: .tabiRadiusLg)
                .fill(Color(red: 0.94, green: 0.91, blue: 0.87))
                .frame(height: 240)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "map")
                            .font(.system(size: 28))
                        TabiLabel(title: Strings.Detail.mapComingSoon, style: .captionM, color: .tabiTextTertiary)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: .tabiRadiusLg)
                        .stroke(TabiColor.tabiBorder.opacity(0.4), lineWidth: 1)
                }
            HStack {
                Spacer()
                TabiButton(
                    Strings.Detail.openInMaps,
                    style: .secondary,
                    icon: Image(systemName: "arrow.up.right.square")
                ) {}
                .disabled(true)
            }
        }
        .padding(.horizontal, 20)
    }
}
