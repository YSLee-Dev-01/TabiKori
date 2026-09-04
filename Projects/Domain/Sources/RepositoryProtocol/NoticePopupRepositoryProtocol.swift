//
//  NoticePopupRepositoryProtocol.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol NoticePopupRepositoryProtocol: Sendable {
    func fetchAnnouncements() async throws -> [Announcement]
    func isDismissedToday(id: String) -> Bool
    func markDismissedToday(id: String)
}
