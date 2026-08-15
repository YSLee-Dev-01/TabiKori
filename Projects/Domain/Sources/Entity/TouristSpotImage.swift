//
//  TouristSpotImage.swift
//  Domain
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public struct TouristSpotImage: Equatable, Sendable {
    public let imageURLString: String
    public let thumbnailURLString: String
    public let name: String

    public init(
        imageURLString: String,
        thumbnailURLString: String,
        name: String
    ) {
        self.imageURLString = imageURLString
        self.thumbnailURLString = thumbnailURLString
        self.name = name
    }

    public var imageURL: URL? {
        return URL(string: self.imageURLString)
    }

    public var thumbnailURL: URL? {
        return URL(string: self.thumbnailURLString)
    }
}
