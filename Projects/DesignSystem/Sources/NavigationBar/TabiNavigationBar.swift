//
//  TabiNavigationBar.swift
//  DesignSystem
//
//  Created by 이윤수 on 6/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI
import Resource

public struct TabiNavigationBar<Trailing: View>: View {

    private let subtitle: String?
    private let title: String
    private let trailing: Trailing

    public init(
        subtitle: String? = nil,
        title: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.subtitle = subtitle
        self.title = title
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                if let subtitle = self.subtitle {
                    TabiLabel(title: subtitle, style: .bodyMBold, color: .tabiTextPrimary)
                }

                TabiLabel(title: self.title, style: .titleL, color: .tabiTextPrimary)
            }

            Spacer()

            self.trailing
        }
        .padding(.horizontal, 20)
    }
}
