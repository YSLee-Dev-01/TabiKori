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
    public enum Detail {}
    public enum Map {}
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
    /// 문화시설
    static let contentTypeCulturalFacility = "文化施設"
    /// 레포츠
    static let contentTypeLeisure = "レジャー"
    /// 교통
    static let contentTypeTransportation = "交通"
    /// 전체
    static let contentTypeAll = "すべて"
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
    /// 일본 여행 배너 설명
    static let japanTravelBannerDescription = "旅行をもっと楽しむために、プランを作成してみましょう。"
    /// 일본 여행 배너 출발 라벨
    static let japanTravelBannerFromLabel = "FROM"
    /// 일본 여행 배너 출발 국가
    static let japanTravelBannerFromCountry = "JPN"
    /// 일본 여행 배너 도착 라벨
    static let japanTravelBannerToLabel = "TO"
    /// 일본 여행 배너 도착 국가
    static let japanTravelBannerToCountry = "KOR"
    /// 일본 여행 배너 하단 라벨
    static let japanTravelBannerPlanLabel = "TRAVEL PLAN"
    /// 인기 관광 스팟 섹션 제목
    static let popularSpotsTitle = "人気の観光スポット"
    /// 주변 관광지 섹션 제목
    static let nearbyTouristSpotsTitle = "近くの観光地"
    /// 주변 맛집 섹션 제목
    static let nearbyRestaurantsTitle = "近くの飲食店"
    /// 주변 관광지 empty 제목
    static let nearbyTouristSpotEmptyTitle = "観光地が見つかりませんでした"
    /// 주변 관광지 empty 설명
    static let nearbyTouristSpotEmptyDescription = "周辺に観光スポットはありません。"
    /// 주변 음식점 empty 제목
    static let nearbyRestaurantEmptyTitle = "飲食店が見つかりませんでした"
    /// 주변 음식점 empty 설명
    static let nearbyRestaurantEmptyDescription = "周辺に飲食店はありません。"
    /// 한국 배너 부제목 (서울)
    static let inKoreaBannerSubtitle = "ソウルにいますね！"
    /// 플랜으로 이동 버튼
    static let moveToPlanButton = "プランへ移動"
    /// 환율 기준 시각 (%@: 날짜/시간)
    nonisolated(unsafe) static let exchangeRateUpdatedAtTitle: ((String) -> String) = {
        "為替レート基準時刻: \($0)"
    }
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
    static let map = "マップ"
    /// 여행 계획
    static let plan = "旅程"
    /// 저장
    static let bookmark = "保存"
}

public extension Strings.Map {
    /// 지도 네비게이션 subtitle
    static let navigationSubtitle = "🔍 検索"
    /// 검색 placeholder
    static let searchPlaceholder = "スポットを検索"
    /// 검색 취소
    static let searchCancel = "キャンセル"
    /// 검색 안내 설명 (빈 상태)
    static let searchEmptyDescription = "地名やスポット名で検索できます"
    /// 검색 결과 없음 제목
    static let searchResultEmptyTitle = "検索結果が見つかりませんでした"
    /// 검색 결과 없음 설명
    static let searchResultEmptyDescription = "別のキーワードで検索してみてください"
    /// 최근 검색 기록 placeholder 설명 (임시)
    static let recentSearchPlaceholderDescription = "最近の検索履歴がここに表示されます"
    /// 최근검색 타이틀
    static let recentSearchTitle = "最近の検索"
}

public extension Strings.Detail {
    /// 정보 탭
    static let tabInfo = "情報"
    /// 사진 탭
    static let tabPhotos = "写真"
    /// 지도 탭
    static let tabMap = "地図"
    /// 지도 섹션 제목
    static let sectionMap = "地図"
    /// 영업시간
    static let infoOpenTime = "営業時間"
    /// 정기휴일
    static let infoRestDate = "定休日"
    /// 전화번호
    static let infoPhone = "電話番号"
    /// 주차
    static let infoParking = "駐車場"
    /// 주소
    static let infoAddress = "住所"
    /// 홈페이지
    static let infoHomepage = "ホームページ"
    /// 체험안내
    static let infoExperienceGuide = "体験案内"
    /// 체험가능연령
    static let infoExperienceAgeRange = "体験可能年齢"
    /// 이용시기
    static let infoUseSeason = "利用時期"
    /// 일정에 추가 버튼
    static let ctaAddToItinerary = "旅程に追加"
    /// 지도보기 버튼
    static let viewInMap = "地図で見る"
    /// 지도 준비 중
    static let mapComingSoon = "地図準備中"
}
