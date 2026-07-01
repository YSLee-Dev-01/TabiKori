//
//  Strings.swift
//  Resource
//
//  Created by 이윤수 on 6/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum Strings {
    public enum Common {}
    public enum Tabbar {}
    public enum Home {}
    public enum Region {}
}

public extension Strings.Common {
    /// 타비코리
    static let tabicori = "タビコリ"
    
    /// 카테고리
    static let categoryTitle = "カテゴリー"
    /// 관광지
    static let categorySightseeing = "観光地"
    /// 음식점
    static let categoryFood = "飲食店"
    /// 숙박
    static let categoryHotel = "宿泊"
    /// 축제
    static let categoryFestival = "お祭り"
    /// 쇼핑
    static let categoryShopping = "ショッピング"
    /// 자연
    static let categoryNature = "自然"
    
}

public extension Strings.Home {
    /// %d월의 추천
    nonisolated(unsafe) static let festivalRecommendationTitle: ((Int) -> String) = {
        "\($0)月のおすすめ"
    }
    /// 이벤트·축제
    static let eventFestivalTitle = "イベント・お祭り"
    /// 상세보기
    static let detailViewTitle = "詳細を見る"
    /// 위치 배너 제목
    static let locationBannerTitle = "位置情報へのアクセス"
    /// 위치 배너 설명
    static let locationBannerDescription = "近くのスポットを表示するには、位置情報の利用を許可してください。"
    /// 위치 배너 버튼
    static let locationBannerButton = "設定を開く"
    /// 일본 여행 배너 제목
    static let japanTravelBannerTitle = "日本にいますね！"
    /// 일본 여행 배너 설명
    static let japanTravelBannerDescription = "旅行をもっと楽しむために、プランを作成してみましょう。"
    /// 일본 여행 배너 버튼
    static let japanTravelBannerButton = "プランを作成する"
    /// 인기 관광 스팟 섹션 제목
    static let popularSpotsTitle = "人気の観光スポット"
    /// 전체보기
    static let seeAll = "すべて見る"
}

public extension Strings.Region {
    /// 서울
    static let seoul = "ソウル"
    /// 부산
    static let busan = "釜山"
    /// 제주
    static let jeju = "済州"
    /// 경주
    static let gyeongju = "慶州"
    /// 여수
    static let yeosu = "麗水"
    /// 강릉
    static let gangneung = "江陵"
    /// 전주
    static let jeonju = "全州"

    /// 서울 (한국어)
    static let seoulKo = "서울"
    /// 부산 (한국어)
    static let busanKo = "부산"
    /// 제주 (한국어)
    static let jejuKo = "제주"
    /// 경주 (한국어)
    static let gyeongjuKo = "경주"
    /// 여수 (한국어)
    static let yeosuKo = "여수"
    /// 강릉 (한국어)
    static let gangneungKo = "강릉"
    /// 전주 (한국어)
    static let jeonjuKo = "전주"
}

public extension Strings.Tabbar {
    /// 홈
    static let home = "ホーム"
    /// 지도
    static let map = "地図"
    /// 여행 계획
    static let plan = "旅程"
    /// 저장
    static let save = "保存"
    /// 검색
    static let search = "検索"
}
