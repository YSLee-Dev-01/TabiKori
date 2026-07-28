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
public final class BookmarkModel {
    public var contentId: String
    public var title: String
    public var thumbnailURLString: String?
    public var contentTypeRaw: String
    public var latitude: Double
    public var longitude: Double
    public var savedAt: Date

    public init(
        contentId: String,
        title: String,
        thumbnailURLString: String?,
        contentTypeRaw: String,
        latitude: Double,
        longitude: Double,
        savedAt: Date
    ) {
        self.contentId = contentId
        self.title = title
        self.thumbnailURLString = thumbnailURLString
        self.contentTypeRaw = contentTypeRaw
        self.latitude = latitude
        self.longitude = longitude
        self.savedAt = savedAt
    }
}
