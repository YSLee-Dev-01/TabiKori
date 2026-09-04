//
//  HomeSheetAnnounceRepositoryProtocol.swift
//  Domain
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public protocol HomeSheetAnnounceRepositoryProtocol: Sendable {
    func fetchAnnouncements() async throws -> [Announcement]
}
