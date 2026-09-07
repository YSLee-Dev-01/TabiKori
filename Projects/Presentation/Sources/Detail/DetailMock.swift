//
//  DetailMock.swift
//  Presentation
//
//  Created by 이윤수 on 7/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain

extension TouristSpotDetail {
    static let mock = TouristSpotDetail(
        id: "264337",
        title: "景福宮（경복궁）",
        contentType: .sightseeing,
        tel: "+82-2-3700-3900",
        homepageURLString: "http://www.royalpalace.go.kr",
        imageURLString: nil,
        address: "ソウル特別市鍾路区社稷路161",
        coordinate: Coordinate(latitude: 37.5796, longitude: 126.9770),
        overview: "朝鮮王朝の正宮として1395年に創建された。勤政殿、慶会楼、香遠亭など数多くの歴史的建造物があり、韓国の宮殿建築美の粋を今に伝えている。"
    )
}

extension TouristSpotIntro {
    static let mock: TouristSpotIntro = .sightseeing(
        SightseeingIntro(
            contact: "+82-2-3700-3900",
            openTime: "09:00〜18:00（火曜日休館）",
            restDate: "毎週火曜日",
            parking: "駐車可能（有料）",
            openDate: "1395年",
            experienceGuide: "韓服着用時は無料入場",
            experienceAgeRange: "全年齢",
            useSeason: "四季を通じて",
            accommodationCount: nil
        )
    )
}

extension Array where Element == TouristSpotImage {
    static let mock: [TouristSpotImage] = [
        TouristSpotImage(
            imageURLString: "https://images.unsplash.com/photo-1599033769063-fcd3ef816810?w=1080",
            thumbnailURLString: "https://images.unsplash.com/photo-1599033769063-fcd3ef816810?w=400",
            name: "景福宮正門"
        ),
        TouristSpotImage(
            imageURLString: "https://images.unsplash.com/photo-1448523183439-d2ac62aca997?w=1080",
            thumbnailURLString: "https://images.unsplash.com/photo-1448523183439-d2ac62aca997?w=400",
            name: "景福宮内部"
        ),
        TouristSpotImage(
            imageURLString: "https://images.unsplash.com/photo-1602479185195-32f5cd203559?w=1080",
            thumbnailURLString: "https://images.unsplash.com/photo-1602479185195-32f5cd203559?w=400",
            name: "景福宮夜景"
        ),
    ]
}
