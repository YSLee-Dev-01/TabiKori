//
//  AnnouncementDTO.swift
//  Data
//
//  Created by Claude on 9/3/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

/// 팝업 공지 / 홈 시트 공지 공용 DTO (RTDB {id: dict} 구조에서 파싱)
struct AnnouncementDTO {
    let id: String
    let title: String
    let subtitle: String
    let content: String
    let startDate: String
    let endDate: String?

    init?(id: String, dict: [String: Any]) {
        guard let title = dict["title"] as? String,
              let subtitle = dict["subtitle"] as? String,
              let content = dict["content"] as? String,
              let startDate = dict["startDate"] as? String else {
            return nil
        }
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.startDate = startDate
        self.endDate = dict["endDate"] as? String
    }
}

// MARK: - Mapping

extension AnnouncementDTO {
    func toEntity() -> Announcement? {
        guard let startDate = self.startDate.toAnnouncementDate() else { return nil }
        let endDate = self.endDate?.toAnnouncementDate()
        return Announcement(
            id: self.id,
            title: self.title,
            subtitle: self.subtitle,
            content: self.content,
            startDate: startDate,
            endDate: endDate
        )
    }
}
