//
//  TestHomeSheetAnnounceUseCase.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestHomeSheetAnnounceUseCase: HomeSheetAnnounceUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var activeAnnouncement: Announcement?

    // MARK: - Method

    public func fetchActiveAnnouncement() async throws -> Announcement? {
        return self.activeAnnouncement
    }
}
