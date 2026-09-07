//
//  TouristSpotImage.swift
//  Domain
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core

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
        return self.imageURLString.secureURL
    }

    public var thumbnailURL: URL? {
        return self.thumbnailURLString.secureURL
    }
}
