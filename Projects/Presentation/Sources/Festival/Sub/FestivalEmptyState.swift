//
//  FestivalEmptyState.swift
//  Presentation
//
//  Created by 이윤수 on 8/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Resource

struct FestivalEmptyState: View {

    var body: some View {
        TabiEmptyState(
            systemImageName: "calendar.badge.exclamationmark",
            title: Strings.Festival.emptyTitle,
            description: Strings.Festival.emptyDescription,
            style: .card
        )
    }
}
