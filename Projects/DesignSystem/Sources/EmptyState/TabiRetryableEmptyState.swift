//
//  TabiRetryableEmptyState.swift
//  DesignSystem
//
//  Created by 이윤수 on 8/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import Resource

/// 조회 실패·재시도 가능한 빈 상태에서 아이콘 + 설명 + 재시도 버튼을 함께 보여주는 공용 컴포넌트
public struct TabiRetryableEmptyState: View {

    private let systemImageName: String
    private let description: String
    private let onRetry: () -> Void

    public init(
        systemImageName: String = "exclamationmark.triangle",
        description: String,
        onRetry: @escaping () -> Void
    ) {
        self.systemImageName = systemImageName
        self.description = description
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: 16) {
            TabiEmptyState(
                systemImageName: self.systemImageName,
                description: self.description,
                style: .card
            )
            TabiButton(Strings.RegionSpot.retryButtonTitle, style: .ghost, action: self.onRetry)
        }
    }
}
