//
//  BookmarkModel.swift
//  Data
//
//  Created by 이윤수 on 7/28/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class BookmarkModel {
    @Attribute(.unique) var contentId: String
    var title: String
    var thumbnailURLString: String?
    var contentTypeRaw: String
    var latitude: Double
    var longitude: Double
    var savedAt: Date
    var isCustom: Bool = false
    var address: String?

    init(
        contentId: String,
        title: String,
        thumbnailURLString: String?,
        contentTypeRaw: String,
        latitude: Double,
        longitude: Double,
        savedAt: Date,
        isCustom: Bool = false,
        address: String? = nil
    ) {
        self.contentId = contentId
        self.title = title
        self.thumbnailURLString = thumbnailURLString
        self.contentTypeRaw = contentTypeRaw
        self.latitude = latitude
        self.longitude = longitude
        self.savedAt = savedAt
        self.isCustom = isCustom
        self.address = address
    }
}
