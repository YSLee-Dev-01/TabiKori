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
    public enum Onboarding {}
    public enum Tabbar {}
    public enum Home {}
    public enum Region {}
    public enum Detail {}
    public enum Map {}
    public enum Bookmark {}
    public enum Plan {}
    public enum Festival {}
    public enum AddToItinerary {}
    public enum AddCustomPlace {}
    public enum RegionSpot {}
    public enum Setting {}
    public enum ToolBar {}
    public enum KoreanPhrase {}
    public enum Shopping {}
    public enum Widget {}
    public enum AppUpdate {}
    public enum Notice {}
}

public extension Strings.Common {
    /// 타비코리
    static var tabicori: String {
        String(localized: "Common.tabicori", defaultValue: "タビコリ", table: "Localizable", bundle: .module)
    }

    /// 카테고리
    static var categoryTitle: String {
        String(localized: "Common.categoryTitle", defaultValue: "カテゴリー", table: "Localizable", bundle: .module)
    }
    /// 관광지
    static var categorySightseeing: String {
        String(localized: "Common.categorySightseeing", defaultValue: "観光地", table: "Localizable", bundle: .module)
    }
    /// 음식점
    static var categoryFood: String {
        String(localized: "Common.categoryFood", defaultValue: "飲食店", table: "Localizable", bundle: .module)
    }
    /// 숙박
    static var categoryHotel: String {
        String(localized: "Common.categoryHotel", defaultValue: "宿泊", table: "Localizable", bundle: .module)
    }
    /// 축제
    static var categoryFestival: String {
        String(localized: "Common.categoryFestival", defaultValue: "お祭り", table: "Localizable", bundle: .module)
    }
    /// 쇼핑
    static var categoryShopping: String {
        String(localized: "Common.categoryShopping", defaultValue: "ショッピング", table: "Localizable", bundle: .module)
    }
    /// 자연
    static var categoryNature: String {
        String(localized: "Common.categoryNature", defaultValue: "自然", table: "Localizable", bundle: .module)
    }
    /// 지하철
    static var categorySubway: String {
        String(localized: "Common.categorySubway", defaultValue: "地下鉄", table: "Localizable", bundle: .module)
    }
    /// 전체
    static var contentTypeAll: String {
        String(localized: "Common.contentTypeAll", defaultValue: "すべて", table: "Localizable", bundle: .module)
    }
    /// 삭제 (스와이프 액션)
    static var delete: String {
        String(localized: "Common.delete", defaultValue: "削除", table: "Localizable", bundle: .module)
    }
    /// 지하철역 검색 시 가타카나 입력 안내 문구
    static var subwayKatakanaGuide: String {
        String(localized: "Common.subwayKatakanaGuide", defaultValue: "韓国語またはカタカナで検索してください", table: "Localizable", bundle: .module)
    }
    /// 지하철역명 입력 후 검색 안내 문구
    static var subwaySearchEnterGuide: String {
        String(localized: "Common.subwaySearchEnterGuide", defaultValue: "Enterキーで検索してください", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Onboarding {
    /// 홈 체험 스텝 제목
    static var homeStepTitle: String {
        String(localized: "Onboarding.homeStepTitle", defaultValue: "ホームでできること", table: "Localizable", bundle: .module)
    }
    /// 홈 체험 스텝 설명
    static var homeStepDescription: String {
        String(localized: "Onboarding.homeStepDescription", defaultValue: "近くのスポットやおすすめ情報を一目で確認できます", table: "Localizable", bundle: .module)
    }
    /// 지도 체험 스텝 제목
    static var mapStepTitle: String {
        String(localized: "Onboarding.mapStepTitle", defaultValue: "地図でスポットを探そう", table: "Localizable", bundle: .module)
    }
    /// 지도 체험 스텝 설명
    static var mapStepDescription: String {
        String(localized: "Onboarding.mapStepDescription", defaultValue: "地図上で観光スポットを検索し、位置を確認できます", table: "Localizable", bundle: .module)
    }
    /// 관광지 상세 체험 스텝 제목
    static var detailStepTitle: String {
        String(localized: "Onboarding.detailStepTitle", defaultValue: "スポットの詳細を見てみよう", table: "Localizable", bundle: .module)
    }
    /// 관광지 상세 체험 스텝 설명
    static var detailStepDescription: String {
        String(localized: "Onboarding.detailStepDescription", defaultValue: "スポットを保存したり、旅行日程に追加したりできます", table: "Localizable", bundle: .module)
    }
    /// 일정 체험 스텝 제목
    static var planStepTitle: String {
        String(localized: "Onboarding.planStepTitle", defaultValue: "旅行日程を管理しよう", table: "Localizable", bundle: .module)
    }
    /// 일정 체험 스텝 설명
    static var planStepDescription: String {
        String(localized: "Onboarding.planStepDescription", defaultValue: "作成した旅行日程を一覧で管理できます", table: "Localizable", bundle: .module)
    }
    /// 일정상세 체험 스텝 제목
    static var planDetailStepTitle: String {
        String(localized: "Onboarding.planDetailStepTitle", defaultValue: "日程の詳細を確認しよう", table: "Localizable", bundle: .module)
    }
    /// 일정상세 체험 스텝 설명
    static var planDetailStepDescription: String {
        String(localized: "Onboarding.planDetailStepDescription", defaultValue: "日ごとのスポットと時間をタイムラインで確認できます", table: "Localizable", bundle: .module)
    }
    /// 약관동의 스텝 제목
    static var agreementStepTitle: String {
        String(localized: "Onboarding.agreementStepTitle", defaultValue: "利用を開始する前に", table: "Localizable", bundle: .module)
    }
    /// 약관동의 스텝 설명
    static var agreementStepDescription: String {
        String(localized: "Onboarding.agreementStepDescription", defaultValue: "プライバシーポリシーをご確認の上、同意してください", table: "Localizable", bundle: .module)
    }
    /// 시작하기 버튼
    static var startButtonTitle: String {
        String(localized: "Onboarding.startButtonTitle", defaultValue: "始める", table: "Localizable", bundle: .module)
    }
    /// 개인정보처리방침 보기 버튼
    static var viewPrivacyPolicyButtonTitle: String {
        String(localized: "Onboarding.viewPrivacyPolicyButtonTitle", defaultValue: "プライバシーポリシーを見る", table: "Localizable", bundle: .module)
    }
    /// 개인정보처리방침 동의 체크박스 라벨
    static var privacyPolicyAgreementLabel: String {
        String(localized: "Onboarding.privacyPolicyAgreementLabel", defaultValue: "プライバシーポリシーに同意します", table: "Localizable", bundle: .module)
    }
    /// 웹뷰 열람 전 안내 문구
    static var privacyPolicyUnviewedGuide: String {
        String(localized: "Onboarding.privacyPolicyUnviewedGuide", defaultValue: "プライバシーポリシーを確認すると同意できます", table: "Localizable", bundle: .module)
    }
    /// 개인정보처리방침 웹뷰 시트 타이틀
    static var privacyPolicyWebViewTitle: String {
        String(localized: "Onboarding.privacyPolicyWebViewTitle", defaultValue: "プライバシーポリシー", table: "Localizable", bundle: .module)
    }
    /// 웹뷰 로드 실패 설명 문구
    static var privacyPolicyLoadFailedDescription: String {
        String(localized: "Onboarding.privacyPolicyLoadFailedDescription", defaultValue: "通信状態を確認してもう一度お試しください", table: "Localizable", bundle: .module)
    }
    /// 홈 카테고리 칩 유도 코치마크 문구
    static var homeCategoryCoachMark: String {
        String(localized: "Onboarding.homeCategoryCoachMark", defaultValue: "カテゴリーで絞り込めます", table: "Localizable", bundle: .module)
    }
    /// 지도 검색 결과 카드 유도 코치마크 문구
    static var mapSearchResultCoachMark: String {
        String(localized: "Onboarding.mapSearchResultCoachMark", defaultValue: "タップで詳細が見られます", table: "Localizable", bundle: .module)
    }
    /// 관광지 상세 저장 버튼 유도 코치마크 문구
    static var detailSaveButtonCoachMark: String {
        String(localized: "Onboarding.detailSaveButtonCoachMark", defaultValue: "タップして保存できます", table: "Localizable", bundle: .module)
    }
    /// 관광지 상세 일정 추가 버튼 유도 코치마크 문구
    static var detailAddButtonCoachMark: String {
        String(localized: "Onboarding.detailAddButtonCoachMark", defaultValue: "日程に追加できます", table: "Localizable", bundle: .module)
    }
    /// 일정 카드 유도 코치마크 문구
    static var planCardCoachMark: String {
        String(localized: "Onboarding.planCardCoachMark", defaultValue: "日ごとの予定がわかります", table: "Localizable", bundle: .module)
    }
    /// 일정상세 Day 칩 유도 코치마크 문구
    static var planDetailDayChipCoachMark: String {
        String(localized: "Onboarding.planDetailDayChipCoachMark", defaultValue: "日付ごとに確認できます", table: "Localizable", bundle: .module)
    }
    /// 일정상세 지도 전체보기 버튼 유도 코치마크 문구
    static var planDetailFullMapButtonCoachMark: String {
        String(localized: "Onboarding.planDetailFullMapButtonCoachMark", defaultValue: "地図を全体表示で確認できます", table: "Localizable", bundle: .module)
    }
    /// 온보딩 웰컴 스텝 제목
    static var welcomeTitle: String {
        String(localized: "Onboarding.welcomeTitle", defaultValue: "タビコリをインストールしていただき、\nありがとうございます🎉", table: "Localizable", bundle: .module)
    }
    /// 온보딩 웰컴 스텝 설명
    static var welcomeDescription: String {
        String(localized: "Onboarding.welcomeDescription", defaultValue: "さっそく使い方をご案内します", table: "Localizable", bundle: .module)
    }
    /// 온보딩 웰컴 스텝 시작 버튼
    static var welcomeButtonTitle: String {
        String(localized: "Onboarding.welcomeButtonTitle", defaultValue: "使い方を見てみる", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Home {
    /// %d월의 추천
    static func festivalRecommendationTitle(_ month: Int) -> String {
        String(localized: "Home.festivalRecommendationTitle", defaultValue: "\(month)月のおすすめ", table: "Localizable", bundle: .module)
    }
    /// 이벤트·축제
    static var eventFestivalTitle: String {
        String(localized: "Home.eventFestivalTitle", defaultValue: "イベント・お祭り", table: "Localizable", bundle: .module)
    }
    /// 위치 배너 제목
    static var locationBannerTitle: String {
        String(localized: "Home.locationBannerTitle", defaultValue: "位置情報へのアクセス", table: "Localizable", bundle: .module)
    }
    /// 위치 배너 설명
    static var locationBannerDescription: String {
        String(localized: "Home.locationBannerDescription", defaultValue: "近くのスポットを表示するには、位置情報の利用を許可してください。", table: "Localizable", bundle: .module)
    }
    /// 일본 여행 배너 설명
    static var japanTravelBannerDescription: String {
        String(localized: "Home.japanTravelBannerDescription", defaultValue: "旅行をもっと楽しむために、プランを作成してみましょう。", table: "Localizable", bundle: .module)
    }
    /// 일본 여행 배너 출발 라벨
    static var japanTravelBannerFromLabel: String {
        String(localized: "Home.japanTravelBannerFromLabel", defaultValue: "FROM", table: "Localizable", bundle: .module)
    }
    /// 일본 여행 배너 출발 국가
    static var japanTravelBannerFromCountry: String {
        String(localized: "Home.japanTravelBannerFromCountry", defaultValue: "JPN", table: "Localizable", bundle: .module)
    }
    /// 일본 여행 배너 도착 라벨
    static var japanTravelBannerToLabel: String {
        String(localized: "Home.japanTravelBannerToLabel", defaultValue: "TO", table: "Localizable", bundle: .module)
    }
    /// 일본 여행 배너 도착 국가
    static var japanTravelBannerToCountry: String {
        String(localized: "Home.japanTravelBannerToCountry", defaultValue: "KOR", table: "Localizable", bundle: .module)
    }
    /// 일본 여행 배너 하단 라벨
    static var japanTravelBannerPlanLabel: String {
        String(localized: "Home.japanTravelBannerPlanLabel", defaultValue: "TRAVEL PLAN", table: "Localizable", bundle: .module)
    }
    /// 인기 관광 스팟 섹션 제목
    static var popularSpotsTitle: String {
        String(localized: "Home.popularSpotsTitle", defaultValue: "人気の観光スポット", table: "Localizable", bundle: .module)
    }
    /// 주변 관광지 섹션 제목
    static var nearbyTouristSpotsTitle: String {
        String(localized: "Home.nearbyTouristSpotsTitle", defaultValue: "近くの観光地", table: "Localizable", bundle: .module)
    }
    /// 주변 맛집 섹션 제목
    static var nearbyRestaurantsTitle: String {
        String(localized: "Home.nearbyRestaurantsTitle", defaultValue: "近くの飲食店", table: "Localizable", bundle: .module)
    }
    /// 주변 관광지 empty 제목
    static var nearbyTouristSpotEmptyTitle: String {
        String(localized: "Home.nearbyTouristSpotEmptyTitle", defaultValue: "観光地が見つかりませんでした", table: "Localizable", bundle: .module)
    }
    /// 주변 관광지 empty 설명
    static var nearbyTouristSpotEmptyDescription: String {
        String(localized: "Home.nearbyTouristSpotEmptyDescription", defaultValue: "周辺に観光スポットはありません。", table: "Localizable", bundle: .module)
    }
    /// 주변 음식점 empty 제목
    static var nearbyRestaurantEmptyTitle: String {
        String(localized: "Home.nearbyRestaurantEmptyTitle", defaultValue: "飲食店が見つかりませんでした", table: "Localizable", bundle: .module)
    }
    /// 주변 음식점 empty 설명
    static var nearbyRestaurantEmptyDescription: String {
        String(localized: "Home.nearbyRestaurantEmptyDescription", defaultValue: "周辺に飲食店はありません。", table: "Localizable", bundle: .module)
    }
    /// 한국 배너 부제목 (서울)
    static var inKoreaBannerSubtitle: String {
        String(localized: "Home.inKoreaBannerSubtitle", defaultValue: "ソウルにいますね！", table: "Localizable", bundle: .module)
    }
    /// 진행중인 플랜이 있을 때 한국 배너 부제목 (%@: 일차)
    static func inKoreaBannerOngoingPlanSubtitle(_ dayLabel: String) -> String {
        String(localized: "Home.inKoreaBannerOngoingPlanSubtitle", defaultValue: "\(dayLabel)の旅です！", table: "Localizable", bundle: .module)
    }
    /// 플랜으로 이동 버튼
    static var moveToPlanButton: String {
        String(localized: "Home.moveToPlanButton", defaultValue: "プランへ移動", table: "Localizable", bundle: .module)
    }
    /// 환율 기준 시각 (%@: 날짜/시간)
    static func exchangeRateUpdatedAtTitle(_ time: String) -> String {
        String(localized: "Home.exchangeRateUpdatedAtTitle", defaultValue: "為替レート基準時刻: \(time)", table: "Localizable", bundle: .module)
    }
    /// 축제 더보기 버튼
    static var festivalMoreButtonTitle: String {
        String(localized: "Home.festivalMoreButtonTitle", defaultValue: "もっと見る", table: "Localizable", bundle: .module)
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
    /// 기타
    static let etc = "その他"
    /// 기타 (한국어)
    static let etcKo = "기타"
}

public extension Strings.Tabbar {
    /// 홈
    static var home: String {
        String(localized: "Tabbar.home", defaultValue: "ホーム", table: "Localizable", bundle: .module)
    }
    /// 지도
    static var map: String {
        String(localized: "Tabbar.map", defaultValue: "マップ", table: "Localizable", bundle: .module)
    }
    /// 여행 계획
    static var plan: String {
        String(localized: "Tabbar.plan", defaultValue: "日程", table: "Localizable", bundle: .module)
    }
    /// 저장
    static var bookmark: String {
        String(localized: "Tabbar.bookmark", defaultValue: "保存", table: "Localizable", bundle: .module)
    }
    /// 툴박스
    static var toolbox: String {
        String(localized: "Tabbar.toolbox", defaultValue: "ツール", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Map {
    /// 검색 placeholder
    static var searchPlaceholder: String {
        String(localized: "Map.searchPlaceholder", defaultValue: "スポットを検索", table: "Localizable", bundle: .module)
    }
    /// 검색 취소
    static var searchCancel: String {
        String(localized: "Map.searchCancel", defaultValue: "キャンセル", table: "Localizable", bundle: .module)
    }
    /// 검색 안내 설명 (빈 상태)
    static var searchEmptyDescription: String {
        String(localized: "Map.searchEmptyDescription", defaultValue: "地名やスポット名で検索できます", table: "Localizable", bundle: .module)
    }
    /// 검색 결과 없음 제목
    static var searchResultEmptyTitle: String {
        String(localized: "Map.searchResultEmptyTitle", defaultValue: "検索結果が見つかりませんでした", table: "Localizable", bundle: .module)
    }
    /// 검색 결과 없음 설명
    static var searchResultEmptyDescription: String {
        String(localized: "Map.searchResultEmptyDescription", defaultValue: "別のキーワードで検索してみてください", table: "Localizable", bundle: .module)
    }
    /// 최근 검색 기록 placeholder 설명 (임시)
    static var recentSearchPlaceholderDescription: String {
        String(localized: "Map.recentSearchPlaceholderDescription", defaultValue: "最近の検索履歴がここに表示されます", table: "Localizable", bundle: .module)
    }
    /// 최근검색 타이틀
    static var recentSearchTitle: String {
        String(localized: "Map.recentSearchTitle", defaultValue: "最近の検索", table: "Localizable", bundle: .module)
    }
    /// 위치 재검색 버튼
    static var researchAtCurrentLocation: String {
        String(localized: "Map.researchAtCurrentLocation", defaultValue: "このエリアで再検索", table: "Localizable", bundle: .module)
    }
    /// 검색 로딩 표시
    static var loading: String {
        String(localized: "Map.loading", defaultValue: "読み込み中", table: "Localizable", bundle: .module)
    }
    /// 검색 TF 하단 안내 문구 (한국어·영어 검색 권장 + 역명 가타카나 검색 안내 통합)
    static var searchLanguageGuide: String {
        String(localized: "Map.searchLanguageGuide", defaultValue: "韓国語・英語で検索すると、より正確な結果が得られます。駅名の検索はカタカナのみに対応しています", table: "Localizable", bundle: .module)
    }
    /// 번역 후 재검색 유도 Toast 액션 버튼 타이틀
    static var translateAndSearchButtonTitle: String {
        String(localized: "Map.translateAndSearchButtonTitle", defaultValue: "韓国語に翻訳して検索", table: "Localizable", bundle: .module)
    }
    /// TF 옆 번역 버튼 타이틀
    static var translateButtonTitle: String {
        String(localized: "Map.translateButtonTitle", defaultValue: "翻訳", table: "Localizable", bundle: .module)
    }
    /// TF 옆 번역 버튼 접근성 라벨
    static var translateSearchButtonAccessibilityLabel: String {
        String(localized: "Map.translateSearchButtonAccessibilityLabel", defaultValue: "検索語を韓国語に翻訳して検索", table: "Localizable", bundle: .module)
    }
    /// 검색어 미입력 상태에서 번역 버튼을 눌렀을 때의 안내 Toast 메시지
    static var translateSearchEmptyQueryGuideMessage: String {
        String(localized: "Map.translateSearchEmptyQueryGuideMessage", defaultValue: "翻訳ボタンをご利用いただくには、日本語で入力してください", table: "Localizable", bundle: .module)
    }
    /// 검색어가 일본어를 포함하지 않는 상태(예: 한국어 입력)에서 번역 버튼을 눌렀을 때의 안내 Toast 메시지
    static var translateSearchNonJapaneseInputGuideMessage: String {
        String(localized: "Map.translateSearchNonJapaneseInputGuideMessage", defaultValue: "この機能は日本語入力時のみご利用いただけます", table: "Localizable", bundle: .module)
    }
    /// 번역 실패 시 노출되는 에러 Toast 메시지
    static var translateFailedMessage: String {
        String(localized: "Map.translateFailedMessage", defaultValue: "翻訳に失敗しました。もう一度お試しください", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Bookmark {
    /// 화면 타이틀
    static var title: String {
        String(localized: "Bookmark.title", defaultValue: "保存済み", table: "Localizable", bundle: .module)
    }
    /// 저장 개수 타이틀 (%d: 개수)
    static func savedCountTitle(_ count: Int) -> String {
        String(localized: "Bookmark.savedCountTitle", defaultValue: "\(count)件のスポットを保存中", table: "Localizable", bundle: .module)
    }
    /// 빈 상태 제목
    static var emptyTitle: String {
        String(localized: "Bookmark.emptyTitle", defaultValue: "保存したスポットがありません", table: "Localizable", bundle: .module)
    }
    /// 빈 상태 설명
    static var emptyDescription: String {
        String(localized: "Bookmark.emptyDescription", defaultValue: "気になるスポットのハートを押して保存してみましょう", table: "Localizable", bundle: .module)
    }
    /// 목록 로드 실패 설명
    static var loadFailedDescription: String {
        String(localized: "Bookmark.loadFailedDescription", defaultValue: "リストを読み込めませんでした", table: "Localizable", bundle: .module)
    }
    /// 카테고리 필터 결과 0건 제목
    static var filteredEmptyTitle: String {
        String(localized: "Bookmark.filteredEmptyTitle", defaultValue: "該当するスポットがありません", table: "Localizable", bundle: .module)
    }
    /// 카테고리 필터 결과 0건 설명
    static var filteredEmptyDescription: String {
        String(localized: "Bookmark.filteredEmptyDescription", defaultValue: "他のカテゴリーを選択してみてください", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Plan {
    /// 화면 타이틀
    static var title: String {
        String(localized: "Plan.title", defaultValue: "日程", table: "Localizable", bundle: .module)
    }
    /// 진행중 섹션 타이틀
    static var ongoingSectionTitle: String {
        String(localized: "Plan.ongoingSectionTitle", defaultValue: "進行中の日程", table: "Localizable", bundle: .module)
    }
    /// 다가오는 섹션 타이틀
    static var upcomingSectionTitle: String {
        String(localized: "Plan.upcomingSectionTitle", defaultValue: "今後の日程", table: "Localizable", bundle: .module)
    }
    /// 지난 섹션 타이틀
    static var pastSectionTitle: String {
        String(localized: "Plan.pastSectionTitle", defaultValue: "過去の日程", table: "Localizable", bundle: .module)
    }
    /// 기간 배지 (%d: 일수)
    static func durationBadge(_ days: Int) -> String {
        String(localized: "Plan.durationBadge", defaultValue: "\(days)日間", table: "Localizable", bundle: .module)
    }
    /// 일자 칩 (%d: 일차)
    static func dayChipTitle(_ day: Int) -> String {
        String(localized: "Plan.dayChipTitle", defaultValue: "\(day)日目", table: "Localizable", bundle: .module)
    }
    /// 합계 스팟 (%d: 스팟 개수)
    static func totalSpotCount(_ count: Int) -> String {
        String(localized: "Plan.totalSpotCount", defaultValue: "合計 \(count)スポット", table: "Localizable", bundle: .module)
    }
    /// 빈 상태 제목
    static var emptyTitle: String {
        String(localized: "Plan.emptyTitle", defaultValue: "登録された日程がありません", table: "Localizable", bundle: .module)
    }
    /// 빈 상태 설명
    static var emptyDescription: String {
        String(localized: "Plan.emptyDescription", defaultValue: "右上の＋ボタンから旅行の日程を追加してみましょう", table: "Localizable", bundle: .module)
    }

    /// 스팟 빈 상태 제목
    static var spotEmptyTitle: String {
        String(localized: "Plan.spotEmptyTitle", defaultValue: "まだスポットがありません", table: "Localizable", bundle: .module)
    }
    /// 스팟 빈 상태 설명
    static var spotEmptyDescription: String {
        String(localized: "Plan.spotEmptyDescription", defaultValue: "観光地や飲食店の詳細ページから「日程に追加」で追加できます", table: "Localizable", bundle: .module)
    }
    /// 지도 빈 상태 설명
    static var mapEmptyDescription: String {
        String(localized: "Plan.mapEmptyDescription", defaultValue: "地図に表示するスポットがありません", table: "Localizable", bundle: .module)
    }
    /// 스팟 0건 안내
    static var spotCountZero: String {
        String(localized: "Plan.spotCountZero", defaultValue: "スポットがまだ追加されていません", table: "Localizable", bundle: .module)
    }
    /// 스팟 N건 안내 (%d: 스팟 개수)
    static func spotCountTitle(_ count: Int) -> String {
        String(localized: "Plan.spotCountTitle", defaultValue: "\(count)件のスポットが追加されています", table: "Localizable", bundle: .module)
    }
    /// 소요시간 (%d: 분)
    static func spotDurationTitle(_ minutes: Int) -> String {
        String(localized: "Plan.spotDurationTitle", defaultValue: "\(minutes)分", table: "Localizable", bundle: .module)
    }
    /// 스팟 추가 버튼 (일자 목록 footer)
    static var spotAddButtonTitle: String {
        String(localized: "Plan.spotAddButtonTitle", defaultValue: "スポットを追加", table: "Localizable", bundle: .module)
    }
    /// 스팟 추가 시트 - 관광지 검색 탭
    static var spotAddSearchTabTitle: String {
        String(localized: "Plan.spotAddSearchTabTitle", defaultValue: "検索", table: "Localizable", bundle: .module)
    }
    /// 스팟 추가 시트 - 주소로 추가 탭
    static var spotAddAddressTabTitle: String {
        String(localized: "Plan.spotAddAddressTabTitle", defaultValue: "カスタム", table: "Localizable", bundle: .module)
    }

    /// 추가 화면 타이틀
    static var addScreenTitle: String {
        String(localized: "Plan.addScreenTitle", defaultValue: "新しい日程を作成", table: "Localizable", bundle: .module)
    }
    /// 일정명 라벨
    static var nameLabel: String {
        String(localized: "Plan.nameLabel", defaultValue: "日程名", table: "Localizable", bundle: .module)
    }
    /// 일정명 placeholder
    static var namePlaceholder: String {
        String(localized: "Plan.namePlaceholder", defaultValue: "例：ソウル春旅行 2026", table: "Localizable", bundle: .module)
    }
    /// 도시 라벨
    static var cityLabel: String {
        String(localized: "Plan.cityLabel", defaultValue: "都市", table: "Localizable", bundle: .module)
    }
    /// 기타 지역명 placeholder
    static var customRegionPlaceholder: String {
        String(localized: "Plan.customRegionPlaceholder", defaultValue: "地域名を入力", table: "Localizable", bundle: .module)
    }
    /// 아이콘(이모지) 라벨
    static var emojiLabel: String {
        String(localized: "Plan.emojiLabel", defaultValue: "アイコン", table: "Localizable", bundle: .module)
    }
    /// 아이콘(이모지) placeholder
    static var emojiPlaceholder: String {
        String(localized: "Plan.emojiPlaceholder", defaultValue: "絵文字を入力", table: "Localizable", bundle: .module)
    }
    /// 날짜 라벨
    static var dateLabel: String {
        String(localized: "Plan.dateLabel", defaultValue: "日付", table: "Localizable", bundle: .module)
    }
    /// 출발 라벨
    static var departureLabel: String {
        String(localized: "Plan.departureLabel", defaultValue: "出発", table: "Localizable", bundle: .module)
    }
    /// 귀국 라벨
    static var returnLabel: String {
        String(localized: "Plan.returnLabel", defaultValue: "帰国", table: "Localizable", bundle: .module)
    }
    /// 날짜 미선택 placeholder
    static var datePlaceholder: String {
        String(localized: "Plan.datePlaceholder", defaultValue: "---", table: "Localizable", bundle: .module)
    }
    /// 확인(작성) 버튼
    static var confirmButton: String {
        String(localized: "Plan.confirmButton", defaultValue: "日程を作成する", table: "Localizable", bundle: .module)
    }
    /// 저장 실패 알림 타이틀
    static var saveFailedAlertTitle: String {
        String(localized: "Plan.saveFailedAlertTitle", defaultValue: "保存に失敗しました", table: "Localizable", bundle: .module)
    }
    /// 저장 실패 알림 메시지
    static var saveFailedAlertMessage: String {
        String(localized: "Plan.saveFailedAlertMessage", defaultValue: "もう一度お試しください", table: "Localizable", bundle: .module)
    }
    /// 알림 확인 버튼
    static var alertConfirm: String {
        String(localized: "Plan.alertConfirm", defaultValue: "確認", table: "Localizable", bundle: .module)
    }
    /// 편집 메뉴 타이틀
    static var editMenuTitle: String {
        String(localized: "Plan.editMenuTitle", defaultValue: "編集", table: "Localizable", bundle: .module)
    }
    /// 편집 모드 저장 버튼
    static var editSaveButton: String {
        String(localized: "Plan.editSaveButton", defaultValue: "保存", table: "Localizable", bundle: .module)
    }
    /// 편집 모드 취소 버튼
    static var editCancelButton: String {
        String(localized: "Plan.editCancelButton", defaultValue: "キャンセル", table: "Localizable", bundle: .module)
    }
    /// 스팟 삭제 실패 알림 타이틀
    static var spotDeleteFailedAlertTitle: String {
        String(localized: "Plan.spotDeleteFailedAlertTitle", defaultValue: "削除に失敗しました", table: "Localizable", bundle: .module)
    }
    /// 스팟 삭제 실패 알림 메시지
    static var spotDeleteFailedAlertMessage: String {
        String(localized: "Plan.spotDeleteFailedAlertMessage", defaultValue: "もう一度お試しください", table: "Localizable", bundle: .module)
    }
    /// 일정 삭제 확인 알림 타이틀
    static var planDeleteAlertTitle: String {
        String(localized: "Plan.planDeleteAlertTitle", defaultValue: "この日程を削除しますか？", table: "Localizable", bundle: .module)
    }
    /// 일정 삭제 확인 알림 메시지
    static var planDeleteAlertMessage: String {
        String(localized: "Plan.planDeleteAlertMessage", defaultValue: "削除すると元に戻せません", table: "Localizable", bundle: .module)
    }
    /// 플랜 자체 편집 메뉴 타이틀
    static var planEditMenuTitle: String {
        String(localized: "Plan.planEditMenuTitle", defaultValue: "予定を編集", table: "Localizable", bundle: .module)
    }
    /// 플랜 자체 삭제 메뉴 타이틀 (상세 화면 "..." 메뉴)
    static var planDeleteMenuTitle: String {
        String(localized: "Plan.planDeleteMenuTitle", defaultValue: "日程を削除", table: "Localizable", bundle: .module)
    }
    /// 플랜 편집 화면 타이틀
    static var editPlanScreenTitle: String {
        String(localized: "Plan.editPlanScreenTitle", defaultValue: "日程を編集", table: "Localizable", bundle: .module)
    }
    /// 날짜 축소 확인 알림 타이틀
    static var dayShrinkAlertTitle: String {
        String(localized: "Plan.dayShrinkAlertTitle", defaultValue: "日程が短くなります", table: "Localizable", bundle: .module)
    }
    /// 날짜 축소 확인 알림 메시지 (%d: 삭제 시작 일차)
    static func dayShrinkAlertMessage(_ day: Int) -> String {
        String(localized: "Plan.dayShrinkAlertMessage", defaultValue: "\(day)日目以降のスポットは削除されます。よろしいですか？", table: "Localizable", bundle: .module)
    }
    /// 알림 취소 버튼
    static var alertCancel: String {
        String(localized: "Plan.alertCancel", defaultValue: "キャンセル", table: "Localizable", bundle: .module)
    }
    /// 전체보기 토글 타이틀
    static var fullOverviewToggleTitle: String {
        String(localized: "Plan.fullOverviewToggleTitle", defaultValue: "全体表示", table: "Localizable", bundle: .module)
    }
    /// 일자별 보기로 돌아가기 타이틀
    static var dayOverviewToggleTitle: String {
        String(localized: "Plan.dayOverviewToggleTitle", defaultValue: "日別表示に戻る", table: "Localizable", bundle: .module)
    }
    /// 공유(내보내기) 메뉴 타이틀
    static var exportMenuTitle: String {
        String(localized: "Plan.exportMenuTitle", defaultValue: "共有", table: "Localizable", bundle: .module)
    }
    /// 공유 사용 방법 안내 알림 타이틀
    static var exportGuideAlertTitle: String {
        String(localized: "Plan.exportGuideAlertTitle", defaultValue: "共有方法について", table: "Localizable", bundle: .module)
    }
    /// 공유 사용 방법 안내 알림 메시지
    static var exportGuideAlertMessage: String {
        String(localized: "Plan.exportGuideAlertMessage", defaultValue: "書き出したファイルは、受け取った人がタビコリの「読み込み」から開くと日程が追加されます", table: "Localizable", bundle: .module)
    }
    /// 가져오기 메뉴 타이틀
    static var importMenuTitle: String {
        String(localized: "Plan.importMenuTitle", defaultValue: "読み込み", table: "Localizable", bundle: .module)
    }
    /// 가져오기 성공 알림 타이틀
    static var importSuccessAlertTitle: String {
        String(localized: "Plan.importSuccessAlertTitle", defaultValue: "読み込みが完了しました", table: "Localizable", bundle: .module)
    }
    /// 가져오기 성공 알림 메시지
    static var importSuccessAlertMessage: String {
        String(localized: "Plan.importSuccessAlertMessage", defaultValue: "日程一覧に追加されました", table: "Localizable", bundle: .module)
    }
    /// 가져오기 실패 알림 타이틀
    static var importFailedAlertTitle: String {
        String(localized: "Plan.importFailedAlertTitle", defaultValue: "読み込みに失敗しました", table: "Localizable", bundle: .module)
    }
    /// 가져오기 실패 알림 메시지
    static var importFailedAlertMessage: String {
        String(localized: "Plan.importFailedAlertMessage", defaultValue: "ファイルを確認してもう一度お試しください", table: "Localizable", bundle: .module)
    }

    /// 쇼핑 리스트 버튼 (준비물 버튼 옆)
    static var shoppingListButtonTitle: String {
        String(localized: "Plan.shoppingListButtonTitle", defaultValue: "買い物", table: "Localizable", bundle: .module)
    }
    /// 지도 전체화면 보기 버튼 (접근성 라벨)
    static var fullMapButtonAccessibilityLabel: String {
        String(localized: "Plan.fullMapButtonAccessibilityLabel", defaultValue: "地図を全画面で見る", table: "Localizable", bundle: .module)
    }
    /// 편집모드 스팟 시간 수정 바텀시트 타이틀
    static var timeEditSheetTitle: String {
        String(localized: "Plan.timeEditSheetTitle", defaultValue: "時間を編集", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Detail {
    /// 정보 탭
    static var tabInfo: String {
        String(localized: "Detail.tabInfo", defaultValue: "情報", table: "Localizable", bundle: .module)
    }
    /// 사진 탭
    static var tabPhotos: String {
        String(localized: "Detail.tabPhotos", defaultValue: "写真", table: "Localizable", bundle: .module)
    }
    /// 지도 탭
    static var tabMap: String {
        String(localized: "Detail.tabMap", defaultValue: "地図", table: "Localizable", bundle: .module)
    }
    /// 영업시간
    static var infoOpenTime: String {
        String(localized: "Detail.infoOpenTime", defaultValue: "営業時間", table: "Localizable", bundle: .module)
    }
    /// 정기휴일
    static var infoRestDate: String {
        String(localized: "Detail.infoRestDate", defaultValue: "定休日", table: "Localizable", bundle: .module)
    }
    /// 전화번호
    static var infoPhone: String {
        String(localized: "Detail.infoPhone", defaultValue: "電話番号", table: "Localizable", bundle: .module)
    }
    /// 주차
    static var infoParking: String {
        String(localized: "Detail.infoParking", defaultValue: "駐車場", table: "Localizable", bundle: .module)
    }
    /// 주소
    static var infoAddress: String {
        String(localized: "Detail.infoAddress", defaultValue: "住所", table: "Localizable", bundle: .module)
    }
    /// 노선 (지하철역 전용)
    static var infoLine: String {
        String(localized: "Detail.infoLine", defaultValue: "路線", table: "Localizable", bundle: .module)
    }
    /// 홈페이지
    static var infoHomepage: String {
        String(localized: "Detail.infoHomepage", defaultValue: "ホームページ", table: "Localizable", bundle: .module)
    }
    /// 체험안내
    static var infoExperienceGuide: String {
        String(localized: "Detail.infoExperienceGuide", defaultValue: "体験案内", table: "Localizable", bundle: .module)
    }
    /// 체험가능연령
    static var infoExperienceAgeRange: String {
        String(localized: "Detail.infoExperienceAgeRange", defaultValue: "体験可能年齢", table: "Localizable", bundle: .module)
    }
    /// 이용시기
    static var infoUseSeason: String {
        String(localized: "Detail.infoUseSeason", defaultValue: "利用時期", table: "Localizable", bundle: .module)
    }
    /// 일정에 추가 버튼
    static var ctaAddToItinerary: String {
        String(localized: "Detail.ctaAddToItinerary", defaultValue: "日程に追加", table: "Localizable", bundle: .module)
    }
    /// 지도보기 버튼
    static var viewInMap: String {
        String(localized: "Detail.viewInMap", defaultValue: "NAVERマップで見る", table: "Localizable", bundle: .module)
    }
    /// 공유 텍스트 - 장소명 접두사
    static var shareTitlePrefix: String {
        String(localized: "Detail.shareTitlePrefix", defaultValue: "🏯", table: "Localizable", bundle: .module)
    }
    /// 공유 텍스트 - 주소 접두사
    static var shareAddressPrefix: String {
        String(localized: "Detail.shareAddressPrefix", defaultValue: "📍", table: "Localizable", bundle: .module)
    }
    /// 공유 텍스트 - 링크 접두사
    static var shareLinkPrefix: String {
        String(localized: "Detail.shareLinkPrefix", defaultValue: "🔗", table: "Localizable", bundle: .module)
    }
}

public extension Strings.AddToItinerary {
    /// 시작 시각 라벨
    static var startTimeLabel: String {
        String(localized: "AddToItinerary.startTimeLabel", defaultValue: "開始時刻", table: "Localizable", bundle: .module)
    }
    /// 종료 시각 라벨
    static var endTimeLabel: String {
        String(localized: "AddToItinerary.endTimeLabel", defaultValue: "終了時刻", table: "Localizable", bundle: .module)
    }
    /// 소요시간 라벨
    static var durationLabel: String {
        String(localized: "AddToItinerary.durationLabel", defaultValue: "所要時間", table: "Localizable", bundle: .module)
    }
    /// 시간 저장 안 함 토글 라벨
    static var noTimeToggleTitle: String {
        String(localized: "AddToItinerary.noTimeToggleTitle", defaultValue: "時刻を保存しない", table: "Localizable", bundle: .module)
    }
    /// 저장(추가) 버튼
    static var saveButton: String {
        String(localized: "AddToItinerary.saveButton", defaultValue: "追加する", table: "Localizable", bundle: .module)
    }
}

public extension Strings.AddCustomPlace {
    /// 화면 타이틀
    static var screenTitle: String {
        String(localized: "AddCustomPlace.screenTitle", defaultValue: "スポットを追加", table: "Localizable", bundle: .module)
    }
    /// 검색 탭 라벨
    static var searchTabLabel: String {
        String(localized: "AddCustomPlace.searchTabLabel", defaultValue: "検索", table: "Localizable", bundle: .module)
    }
    /// 커스텀 탭 라벨
    static var customTabLabel: String {
        String(localized: "AddCustomPlace.customTabLabel", defaultValue: "カスタム", table: "Localizable", bundle: .module)
    }
    /// 주소 입력 하단 안내 문구 (한국어 검색 권장)
    static var addressKoreanSearchGuide: String {
        String(localized: "AddCustomPlace.addressKoreanSearchGuide", defaultValue: "住所は韓国語で検索すると、より正確に見つかります", table: "Localizable", bundle: .module)
    }
    /// 타이틀 입력 라벨
    static var titleLabel: String {
        String(localized: "AddCustomPlace.titleLabel", defaultValue: "タイトル", table: "Localizable", bundle: .module)
    }
    /// 타이틀 입력 placeholder
    static var titlePlaceholder: String {
        String(localized: "AddCustomPlace.titlePlaceholder", defaultValue: "スポット名を入力", table: "Localizable", bundle: .module)
    }
    /// 지하철역 모드 타이틀 입력 라벨(역명)
    static var stationTitleLabel: String {
        String(localized: "AddCustomPlace.stationTitleLabel", defaultValue: "駅名", table: "Localizable", bundle: .module)
    }
    /// 주소 입력 라벨
    static var addressLabel: String {
        String(localized: "AddCustomPlace.addressLabel", defaultValue: "住所", table: "Localizable", bundle: .module)
    }
    /// 주소 입력 placeholder
    static var addressPlaceholder: String {
        String(localized: "AddCustomPlace.addressPlaceholder", defaultValue: "住所を入力", table: "Localizable", bundle: .module)
    }
    /// 저장 버튼
    static var saveButton: String {
        String(localized: "AddCustomPlace.saveButton", defaultValue: "保存する", table: "Localizable", bundle: .module)
    }
    /// 주소를 찾을 수 없음 알림 타이틀
    static var addressNotFoundAlertTitle: String {
        String(localized: "AddCustomPlace.addressNotFoundAlertTitle", defaultValue: "住所が見つかりませんでした", table: "Localizable", bundle: .module)
    }
    /// 주소를 찾을 수 없음 알림 메시지
    static var addressNotFoundAlertMessage: String {
        String(localized: "AddCustomPlace.addressNotFoundAlertMessage", defaultValue: "住所を確認してもう一度お試しください", table: "Localizable", bundle: .module)
    }
    /// 커스텀 스팟 배지 타이틀
    static var customBadgeTitle: String {
        String(localized: "AddCustomPlace.customBadgeTitle", defaultValue: "カスタム", table: "Localizable", bundle: .module)
    }
    /// 지하철역 모드 타이틀 입력 placeholder
    static var stationTitlePlaceholder: String {
        String(localized: "AddCustomPlace.stationTitlePlaceholder", defaultValue: "駅名を入力", table: "Localizable", bundle: .module)
    }
    /// 지하철역 좌표 조회 실패 알림 타이틀
    static var stationResolveFailedAlertTitle: String {
        String(localized: "AddCustomPlace.stationResolveFailedAlertTitle", defaultValue: "駅の位置情報を取得できませんでした", table: "Localizable", bundle: .module)
    }
    /// 지하철역 좌표 조회 실패 알림 메시지
    static var stationResolveFailedAlertMessage: String {
        String(localized: "AddCustomPlace.stationResolveFailedAlertMessage", defaultValue: "もう一度お試しください", table: "Localizable", bundle: .module)
    }
}

public extension Strings.RegionSpot {
    /// 축제 섹션 제목
    static var festivalSectionTitle: String {
        String(localized: "RegionSpot.festivalSectionTitle", defaultValue: "開催中のイベント", table: "Localizable", bundle: .module)
    }
    /// 관광지 탭 라벨
    static var spotTabLabel: String {
        String(localized: "RegionSpot.spotTabLabel", defaultValue: "観光スポット", table: "Localizable", bundle: .module)
    }
    /// 이벤트 탭 라벨
    static var festivalTabLabel: String {
        String(localized: "RegionSpot.festivalTabLabel", defaultValue: "イベント", table: "Localizable", bundle: .module)
    }
    /// 관광지 빈 상태 제목
    static var spotEmptyTitle: String {
        String(localized: "RegionSpot.spotEmptyTitle", defaultValue: "観光スポットが見つかりませんでした", table: "Localizable", bundle: .module)
    }
    /// 관광지 빈 상태 설명
    static var spotEmptyDescription: String {
        String(localized: "RegionSpot.spotEmptyDescription", defaultValue: "他のカテゴリーもお試しください", table: "Localizable", bundle: .module)
    }
    /// 축제 빈 상태 설명
    static var festivalEmptyDescription: String {
        String(localized: "RegionSpot.festivalEmptyDescription", defaultValue: "現在開催中のイベントはありません", table: "Localizable", bundle: .module)
    }
    /// 에러 상태 설명
    static var errorDescription: String {
        String(localized: "RegionSpot.errorDescription", defaultValue: "通信状態を確認してもう一度お試しください", table: "Localizable", bundle: .module)
    }
    /// 재시도 버튼 라벨
    static var retryButtonTitle: String {
        String(localized: "RegionSpot.retryButtonTitle", defaultValue: "再試行", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Festival {
    /// 검색 시작일 라벨
    static var startDateLabel: String {
        String(localized: "Festival.startDateLabel", defaultValue: "検索開始日", table: "Localizable", bundle: .module)
    }
    /// 검색 종료일 라벨
    static var endDateLabel: String {
        String(localized: "Festival.endDateLabel", defaultValue: "検索終了日", table: "Localizable", bundle: .module)
    }
    /// 결과 없음 제목
    static var emptyTitle: String {
        String(localized: "Festival.emptyTitle", defaultValue: "イベントが見つかりませんでした", table: "Localizable", bundle: .module)
    }
    /// 결과 없음 설명
    static var emptyDescription: String {
        String(localized: "Festival.emptyDescription", defaultValue: "条件を変更して再度お試しください", table: "Localizable", bundle: .module)
    }
    /// 종료일 지정 시 기간 내 완결 이벤트만 표시된다는 안내 문구
    static var dateRangeFilterNotice: String {
        String(localized: "Festival.dateRangeFilterNotice", defaultValue: "終了日を指定すると、期間内に開催が完結するイベントのみ表示されます", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Setting {
    /// 화면 타이틀
    static var screenTitle: String {
        String(localized: "Setting.screenTitle", defaultValue: "設定", table: "Localizable", bundle: .module)
    }

    /// GPS 권한 섹션 타이틀
    static var gpsSectionTitle: String {
        String(localized: "Setting.gpsSectionTitle", defaultValue: "位置情報の権限", table: "Localizable", bundle: .module)
    }
    /// GPS 권한 행 타이틀
    static var gpsRowTitle: String {
        String(localized: "Setting.gpsRowTitle", defaultValue: "位置情報へのアクセス", table: "Localizable", bundle: .module)
    }
    /// GPS 권한 상태 - 허용
    static var gpsStatusAllowed: String {
        String(localized: "Setting.gpsStatusAllowed", defaultValue: "許可済み", table: "Localizable", bundle: .module)
    }
    /// GPS 권한 상태 - 거부
    static var gpsStatusDenied: String {
        String(localized: "Setting.gpsStatusDenied", defaultValue: "拒否", table: "Localizable", bundle: .module)
    }
    /// GPS 권한 상태 - 미결정
    static var gpsStatusUndetermined: String {
        String(localized: "Setting.gpsStatusUndetermined", defaultValue: "未設定", table: "Localizable", bundle: .module)
    }

    /// 일정 상세 섹션 타이틀
    static var planDetailSectionTitle: String {
        String(localized: "Setting.planDetailSectionTitle", defaultValue: "日程詳細", table: "Localizable", bundle: .module)
    }
    /// 오늘 날짜 자동 이동 토글 행 타이틀
    static var autoScrollToTodayRowTitle: String {
        String(localized: "Setting.autoScrollToTodayRowTitle", defaultValue: "今日の日程へ自動移動", table: "Localizable", bundle: .module)
    }
    /// 오늘 날짜 자동 이동 토글 행 설명
    static var autoScrollToTodayRowDescription: String {
        String(localized: "Setting.autoScrollToTodayRowDescription", defaultValue: "日程詳細を開いたとき、今日に該当する日を自動的に表示します", table: "Localizable", bundle: .module)
    }

    /// 검색 섹션 타이틀
    static var searchSectionTitle: String {
        String(localized: "Setting.searchSectionTitle", defaultValue: "検索", table: "Localizable", bundle: .module)
    }
    /// 자동 번역 검색 토글 행 타이틀
    static var autoTranslateSearchRowTitle: String {
        String(localized: "Setting.autoTranslateSearchRowTitle", defaultValue: "自動翻訳検索", table: "Localizable", bundle: .module)
    }
    /// 자동 번역 검색 토글 행 설명
    static var autoTranslateSearchRowDescription: String {
        String(localized: "Setting.autoTranslateSearchRowDescription", defaultValue: "日本語で検索して結果が見つからないとき、韓国語に翻訳して再検索するボタンを表示します", table: "Localizable", bundle: .module)
    }

    /// 데이터 초기화 섹션 타이틀
    static var dataResetSectionTitle: String {
        String(localized: "Setting.dataResetSectionTitle", defaultValue: "データの初期化", table: "Localizable", bundle: .module)
    }
    /// 데이터 초기화 행 타이틀
    static var dataResetRowTitle: String {
        String(localized: "Setting.dataResetRowTitle", defaultValue: "すべてのデータを初期化", table: "Localizable", bundle: .module)
    }
    /// 데이터 초기화 행 설명
    static var dataResetRowDescription: String {
        String(localized: "Setting.dataResetRowDescription", defaultValue: "保存したスポット、日程、最近の検索履歴が削除されます", table: "Localizable", bundle: .module)
    }
    /// 초기화 확인 Alert 타이틀
    static var dataResetAlertTitle: String {
        String(localized: "Setting.dataResetAlertTitle", defaultValue: "データを初期化しますか？", table: "Localizable", bundle: .module)
    }
    /// 초기화 확인 Alert 메시지
    static var dataResetAlertMessage: String {
        String(localized: "Setting.dataResetAlertMessage", defaultValue: "保存済みスポット・日程・最近の検索履歴が削除されます。この操作は取り消せません。", table: "Localizable", bundle: .module)
    }
    /// 초기화 확인 Alert 삭제(확정) 버튼
    static var dataResetAlertConfirmButton: String {
        String(localized: "Setting.dataResetAlertConfirmButton", defaultValue: "初期化する", table: "Localizable", bundle: .module)
    }
    /// 초기화 성공 Alert 타이틀
    static var dataResetSuccessAlertTitle: String {
        String(localized: "Setting.dataResetSuccessAlertTitle", defaultValue: "初期化が完了しました", table: "Localizable", bundle: .module)
    }
    /// 초기화 실패 Alert 타이틀
    static var dataResetFailureAlertTitle: String {
        String(localized: "Setting.dataResetFailureAlertTitle", defaultValue: "初期化に失敗しました", table: "Localizable", bundle: .module)
    }
    /// 초기화 실패 Alert 메시지
    static var dataResetFailureAlertMessage: String {
        String(localized: "Setting.dataResetFailureAlertMessage", defaultValue: "一部のデータが削除できませんでした。もう一度お試しください", table: "Localizable", bundle: .module)
    }

    /// 기타 섹션 타이틀
    static var etcSectionTitle: String {
        String(localized: "Setting.etcSectionTitle", defaultValue: "その他", table: "Localizable", bundle: .module)
    }
    /// 데이터 출처 행 타이틀
    static var etcDataSourceTitle: String {
        String(localized: "Setting.etcDataSourceTitle", defaultValue: "データ出典", table: "Localizable", bundle: .module)
    }
    /// 개인정보처리방침 행 타이틀
    static var etcPrivacyPolicyTitle: String {
        String(localized: "Setting.etcPrivacyPolicyTitle", defaultValue: "プライバシーポリシー", table: "Localizable", bundle: .module)
    }
    /// 오픈소스 라이선스 행 타이틀
    static var etcLicenseTitle: String {
        String(localized: "Setting.etcLicenseTitle", defaultValue: "オープンソースライセンス", table: "Localizable", bundle: .module)
    }
    /// 기타 정보 행 타이틀
    static var etcInfoTitle: String {
        String(localized: "Setting.etcInfoTitle", defaultValue: "その他の情報", table: "Localizable", bundle: .module)
    }
    /// 문의하기 행 타이틀
    static var etcContactTitle: String {
        String(localized: "Setting.etcContactTitle", defaultValue: "お問い合わせ", table: "Localizable", bundle: .module)
    }
    /// 메일 앱 미설정 기기에서 문의하기 탭 시 안내 메시지
    static var mailNotAvailableMessage: String {
        String(localized: "Setting.mailNotAvailableMessage", defaultValue: "メールアプリが設定されていません", table: "Localizable", bundle: .module)
    }
    /// 버전 정보 행 타이틀
    static var etcVersionTitle: String {
        String(localized: "Setting.etcVersionTitle", defaultValue: "バージョン情報", table: "Localizable", bundle: .module)
    }
    /// 비활성화(TODO) 행 보조 라벨
    static var etcComingSoonLabel: String {
        String(localized: "Setting.etcComingSoonLabel", defaultValue: "準備中", table: "Localizable", bundle: .module)
    }

    /// 데이터 출처 안내 본문
    static var dataSourceContent: String {
        String(localized: "Setting.dataSourceContent", defaultValue: "本アプリは韓国観光公社 多言語観光情報サービス(EngService2)、NAVER 地図・Geocoding API、為替レートAPIの情報を利用しています。", table: "Localizable", bundle: .module)
    }
    /// 오픈소스 라이선스 안내 본문. 각 라이브러리명 + 라이센스 종류 + 저작권 고지(GitHub license API/LICENSE 파일 기준 확인)
    static var licenseContent: String {
        String(localized: "Setting.licenseContent", defaultValue: "本アプリは以下のライブラリ・SDKを使用しています。\n\n・swift-composable-architecture — MIT License\n   © Point-Free, Inc.\n\n・Kingfisher — MIT License\n   © Wei Wang\n\n・lottie-ios — Apache License 2.0\n   © Airbnb, Inc.\n\n・firebase-ios-sdk — Apache License 2.0\n   © Google LLC\n\n・SPM-NMapsMap (NAVER Maps SDK) — プロプライエタリライセンス\n   © NAVER Corp. All rights reserved.", table: "Localizable", bundle: .module)
    }
    /// 기타 정보 안내 본문 (TODO: 내용 추가 예정)
    static var etcInfoContent: String {
        String(localized: "Setting.etcInfoContent", defaultValue: "", table: "Localizable", bundle: .module)
    }
    /// 버전 정보 표시 (%@: 버전, %@: 빌드번호)
    static func versionTitle(_ version: String, _ build: String) -> String {
        String(localized: "Setting.versionTitle", defaultValue: "バージョン \(version) (\(build))", table: "Localizable", bundle: .module)
    }
}

public extension Strings.ToolBar {
    /// 허브 화면(툴박스 탭) 타이틀
    static var hubTitle: String {
        String(localized: "ToolBar.hubTitle", defaultValue: "ツールボックス", table: "Localizable", bundle: .module)
    }
    /// 화면 타이틀 (마스터/저장된 체크리스트 공용)
    static var title: String {
        String(localized: "ToolBar.title", defaultValue: "持ち物リスト", table: "Localizable", bundle: .module)
    }
    /// 플랜에 전체 추가 버튼
    static var saveToPlanButton: String {
        String(localized: "ToolBar.saveToPlanButton", defaultValue: "すべて日程に追加", table: "Localizable", bundle: .module)
    }
    /// 마스터 리스트 로드 실패 설명
    static var loadFailedDescription: String {
        String(localized: "ToolBar.loadFailedDescription", defaultValue: "リストを読み込めませんでした", table: "Localizable", bundle: .module)
    }

    /// 개별 추가 안내 문구 (리스트 상단)
    static var individualAddGuideDescription: String {
        String(localized: "ToolBar.individualAddGuideDescription", defaultValue: "アイテムをタップすると、その項目だけ日程に追加できます", table: "Localizable", bundle: .module)
    }

    /// 준비물 빈 상태 제목 (마스터 리스트 0건)
    static var itemEmptyTitle: String {
        String(localized: "ToolBar.itemEmptyTitle", defaultValue: "登録された持ち物がありません", table: "Localizable", bundle: .module)
    }
    /// 준비물 빈 상태 설명 (마스터 리스트 0건)
    static var itemEmptyDescription: String {
        String(localized: "ToolBar.itemEmptyDescription", defaultValue: "しばらくしてから再度お試しください", table: "Localizable", bundle: .module)
    }

    /// 플랜 선택 시트 타이틀
    static var planPickerTitle: String {
        String(localized: "ToolBar.planPickerTitle", defaultValue: "保存する日程を選択", table: "Localizable", bundle: .module)
    }
    /// 플랜 선택 시트 빈 상태 제목 (플랜 0건)
    static var planPickerEmptyTitle: String {
        String(localized: "ToolBar.planPickerEmptyTitle", defaultValue: "登録された日程がありません", table: "Localizable", bundle: .module)
    }
    /// 플랜 선택 시트 빈 상태 설명 (플랜 0건)
    static var planPickerEmptyDescription: String {
        String(localized: "ToolBar.planPickerEmptyDescription", defaultValue: "先に日程を作成してください", table: "Localizable", bundle: .module)
    }

    /// 덮어쓰기 확인 알림 타이틀
    static var overwriteAlertTitle: String {
        String(localized: "ToolBar.overwriteAlertTitle", defaultValue: "持ち物リストを上書きしますか？", table: "Localizable", bundle: .module)
    }
    /// 덮어쓰기 확인 알림 메시지
    static var overwriteAlertMessage: String {
        String(localized: "ToolBar.overwriteAlertMessage", defaultValue: "この日程には既に持ち物リストが保存されています。上書きすると、チェック状態を含む既存のリストは削除されます。", table: "Localizable", bundle: .module)
    }
    /// 덮어쓰기 확인 버튼
    static var overwriteAlertConfirm: String {
        String(localized: "ToolBar.overwriteAlertConfirm", defaultValue: "上書きする", table: "Localizable", bundle: .module)
    }
    /// 덮어쓰기 알림 취소 버튼
    static var overwriteAlertCancel: String {
        String(localized: "ToolBar.overwriteAlertCancel", defaultValue: "キャンセル", table: "Localizable", bundle: .module)
    }
    /// 덮어쓰기 알림 - 기존 리스트 아래에 추가 버튼
    static var appendAlertConfirm: String {
        String(localized: "ToolBar.appendAlertConfirm", defaultValue: "下に追加する", table: "Localizable", bundle: .module)
    }

    /// 저장 실패 설명
    static var saveFailedDescription: String {
        String(localized: "ToolBar.saveFailedDescription", defaultValue: "保存に失敗しました。もう一度お試しください", table: "Localizable", bundle: .module)
    }

    /// PlanDetail 진입 버튼 (접근성 라벨)
    static var planDetailEntryTitle: String {
        String(localized: "ToolBar.planDetailEntryTitle", defaultValue: "持ち物", table: "Localizable", bundle: .module)
    }

    /// 저장된 체크리스트 빈 상태 제목 (아직 저장 안 됨)
    static var savedEmptyTitle: String {
        String(localized: "ToolBar.savedEmptyTitle", defaultValue: "持ち物リストがまだありません", table: "Localizable", bundle: .module)
    }
    /// 저장된 체크리스트 빈 상태 설명 (아직 저장 안 됨)
    static var savedEmptyDescription: String {
        String(localized: "ToolBar.savedEmptyDescription", defaultValue: "ツールタブの持ち物リストから、この日程に保存できます", table: "Localizable", bundle: .module)
    }
    /// 완료 개수 표시 (%d: 완료 개수, %d: 전체 개수)
    static func checkedCountTitle(_ checked: Int, _ total: Int) -> String {
        String(localized: "ToolBar.checkedCountTitle", defaultValue: "\(checked)/\(total) 完了", table: "Localizable", bundle: .module)
    }

    /// 허브 화면 - 준비물 섹션 타이틀
    static var packingSectionTitle: String {
        String(localized: "ToolBar.packingSectionTitle", defaultValue: "持ち物リスト", table: "Localizable", bundle: .module)
    }
    /// 허브 화면 - 섹션 공용 더보기 버튼 (준비물/한국어 섹션)
    static var seeAllButton: String {
        String(localized: "ToolBar.seeAllButton", defaultValue: "もっと見る", table: "Localizable", bundle: .module)
    }
    /// 허브 화면 - 환율 섹션 타이틀
    static var exchangeRateSectionTitle: String {
        String(localized: "ToolBar.exchangeRateSectionTitle", defaultValue: "為替レート", table: "Localizable", bundle: .module)
    }

    /// PlanDetail 저장된 체크리스트 - 추가 버튼 (접근성 라벨)
    static var addButtonAccessibilityLabel: String {
        String(localized: "ToolBar.addButtonAccessibilityLabel", defaultValue: "項目を追加", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 저장된 체크리스트 - 추가모드 진입 시 닫기 버튼 (접근성 라벨)
    static var closeAddButtonAccessibilityLabel: String {
        String(localized: "ToolBar.closeAddButtonAccessibilityLabel", defaultValue: "追加をやめる", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 저장된 체크리스트 - 편집 버튼 (접근성 라벨)
    static var editButtonAccessibilityLabel: String {
        String(localized: "ToolBar.editButtonAccessibilityLabel", defaultValue: "編集", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 저장된 체크리스트 - 항목 추가 입력 placeholder
    static var addItemPlaceholder: String {
        String(localized: "ToolBar.addItemPlaceholder", defaultValue: "項目を入力", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 저장된 체크리스트 - 편집모드 서브타이틀(메모) 입력 placeholder
    static var noteFieldPlaceholder: String {
        String(localized: "ToolBar.noteFieldPlaceholder", defaultValue: "メモを入力", table: "Localizable", bundle: .module)
    }
}

public extension Strings.KoreanPhrase {
    /// 허브 화면 - 한국어 섹션 타이틀
    static var sectionTitle: String {
        String(localized: "KoreanPhrase.sectionTitle", defaultValue: "簡単な韓国語", table: "Localizable", bundle: .module)
    }
    /// 전체 문구 목록 화면 타이틀
    static var listTitle: String {
        String(localized: "KoreanPhrase.listTitle", defaultValue: "簡単な韓国語", table: "Localizable", bundle: .module)
    }
    /// 문구 리스트 로드 실패 설명
    static var loadFailedDescription: String {
        String(localized: "KoreanPhrase.loadFailedDescription", defaultValue: "リストを読み込めませんでした", table: "Localizable", bundle: .module)
    }
    /// 빈 상태 제목 (문구 0건)
    static var emptyTitle: String {
        String(localized: "KoreanPhrase.emptyTitle", defaultValue: "登録されたフレーズがありません", table: "Localizable", bundle: .module)
    }
    /// 빈 상태 설명 (문구 0건)
    static var emptyDescription: String {
        String(localized: "KoreanPhrase.emptyDescription", defaultValue: "しばらくしてから再度お試しください", table: "Localizable", bundle: .module)
    }
    /// 문구 셀 롱프레스 메뉴 - 복사
    static var copyMenuTitle: String {
        String(localized: "KoreanPhrase.copyMenuTitle", defaultValue: "コピー", table: "Localizable", bundle: .module)
    }
    /// 문구 셀 롱프레스 메뉴 - 크게보기
    static var viewLargeMenuTitle: String {
        String(localized: "KoreanPhrase.viewLargeMenuTitle", defaultValue: "拡大表示", table: "Localizable", bundle: .module)
    }
    /// 목록 화면 - 커스텀 문구 Section 헤더
    static var customSectionHeader: String {
        String(localized: "KoreanPhrase.customSectionHeader", defaultValue: "追加したフレーズ", table: "Localizable", bundle: .module)
    }
    /// 목록 화면 - 기본 제공 문구 Section 헤더
    static var defaultSectionHeader: String {
        String(localized: "KoreanPhrase.defaultSectionHeader", defaultValue: "基本フレーズ", table: "Localizable", bundle: .module)
    }
    /// 목록 화면 - "+" 버튼 accessibilityLabel
    static var addButtonAccessibilityLabel: String {
        String(localized: "KoreanPhrase.addButtonAccessibilityLabel", defaultValue: "フレーズを追加", table: "Localizable", bundle: .module)
    }
    /// 입력 폼 화면 타이틀
    static var addFormTitle: String {
        String(localized: "KoreanPhrase.addFormTitle", defaultValue: "フレーズを追加", table: "Localizable", bundle: .module)
    }
    /// 입력 폼 - 한국어 필드 라벨
    static var koreanFieldLabel: String {
        String(localized: "KoreanPhrase.koreanFieldLabel", defaultValue: "韓国語", table: "Localizable", bundle: .module)
    }
    /// 입력 폼 - 한국어 필드 플레이스홀더
    static var koreanFieldPlaceholder: String {
        String(localized: "KoreanPhrase.koreanFieldPlaceholder", defaultValue: "韓国語を入力してください", table: "Localizable", bundle: .module)
    }
    /// 입력 폼 - 일본어 필드 라벨
    static var japaneseFieldLabel: String {
        String(localized: "KoreanPhrase.japaneseFieldLabel", defaultValue: "日本語", table: "Localizable", bundle: .module)
    }
    /// 입력 폼 - 일본어 필드 플레이스홀더
    static var japaneseFieldPlaceholder: String {
        String(localized: "KoreanPhrase.japaneseFieldPlaceholder", defaultValue: "日本語を入力してください", table: "Localizable", bundle: .module)
    }
    /// 입력 폼 - 발음 필드 라벨(선택)
    static var pronunciationFieldLabel: String {
        String(localized: "KoreanPhrase.pronunciationFieldLabel", defaultValue: "発音（任意）", table: "Localizable", bundle: .module)
    }
    /// 입력 폼 - 발음 필드 플레이스홀더
    static var pronunciationFieldPlaceholder: String {
        String(localized: "KoreanPhrase.pronunciationFieldPlaceholder", defaultValue: "発音を入力してください（任意）", table: "Localizable", bundle: .module)
    }
    /// 입력 폼 - 번역 버튼 타이틀
    static var translateButtonTitle: String {
        String(localized: "KoreanPhrase.translateButtonTitle", defaultValue: "翻訳", table: "Localizable", bundle: .module)
    }
    /// 입력 폼 - 저장 버튼 타이틀
    static var saveButtonTitle: String {
        String(localized: "KoreanPhrase.saveButtonTitle", defaultValue: "保存", table: "Localizable", bundle: .module)
    }
    /// 번역 실패 토스트 메시지
    static var translationFailedToast: String {
        String(localized: "KoreanPhrase.translationFailedToast", defaultValue: "翻訳に失敗しました", table: "Localizable", bundle: .module)
    }
    /// 일본어 미입력 상태에서 번역 시도 시 안내 토스트 메시지
    static var translationEmptyJapaneseToast: String {
        String(localized: "KoreanPhrase.translationEmptyJapaneseToast", defaultValue: "日本語を入力してから翻訳してください", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Shopping {
    /// 허브 화면 - 추천 쇼핑 리스트 섹션 타이틀
    static var sectionTitle: String {
        String(localized: "Shopping.sectionTitle", defaultValue: "おすすめのお買い物リスト", table: "Localizable", bundle: .module)
    }
    /// 추천 쇼핑 리스트 로드 실패 설명
    static var loadFailedDescription: String {
        String(localized: "Shopping.loadFailedDescription", defaultValue: "リストを読み込めませんでした", table: "Localizable", bundle: .module)
    }
    /// 빈 상태 제목 (추천 쇼핑 아이템 0건)
    static var emptyTitle: String {
        String(localized: "Shopping.emptyTitle", defaultValue: "登録されたおすすめ商品がありません", table: "Localizable", bundle: .module)
    }
    /// 빈 상태 설명 (추천 쇼핑 아이템 0건)
    static var emptyDescription: String {
        String(localized: "Shopping.emptyDescription", defaultValue: "しばらくしてから再度お試しください", table: "Localizable", bundle: .module)
    }

    /// PlanDetail 연동 쇼핑 리스트 화면 타이틀
    static var planListTitle: String {
        String(localized: "Shopping.planListTitle", defaultValue: "お買い物リスト", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 연동 쇼핑 리스트 - 저장된 목록 빈 상태 제목 (아직 저장 안 됨)
    static var planListSavedEmptyTitle: String {
        String(localized: "Shopping.planListSavedEmptyTitle", defaultValue: "お買い物リストがまだありません", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 연동 쇼핑 리스트 - 저장된 목록 빈 상태 설명 (아직 저장 안 됨)
    static var planListSavedEmptyDescription: String {
        String(localized: "Shopping.planListSavedEmptyDescription", defaultValue: "右上の＋ボタンから、買いたいものを追加しましょう", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 연동 쇼핑 리스트 - 완료 개수 표시 (%d: 완료 개수, %d: 전체 개수)
    static func planListCheckedCountTitle(_ checked: Int, _ total: Int) -> String {
        String(localized: "Shopping.planListCheckedCountTitle", defaultValue: "\(checked)/\(total) 完了", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 연동 쇼핑 리스트 - 추가 버튼 (접근성 라벨)
    static var planListAddButtonAccessibilityLabel: String {
        String(localized: "Shopping.planListAddButtonAccessibilityLabel", defaultValue: "項目を追加", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 연동 쇼핑 리스트 - 추가모드 진입 시 닫기 버튼 (접근성 라벨)
    static var planListCloseAddButtonAccessibilityLabel: String {
        String(localized: "Shopping.planListCloseAddButtonAccessibilityLabel", defaultValue: "追加をやめる", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 연동 쇼핑 리스트 - 편집 버튼 (접근성 라벨)
    static var planListEditButtonAccessibilityLabel: String {
        String(localized: "Shopping.planListEditButtonAccessibilityLabel", defaultValue: "編集", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 연동 쇼핑 리스트 - 항목 추가 입력 placeholder
    static var planListAddItemPlaceholder: String {
        String(localized: "Shopping.planListAddItemPlaceholder", defaultValue: "項目を入力", table: "Localizable", bundle: .module)
    }
    /// PlanDetail 연동 쇼핑 리스트 - 편집모드 서브타이틀(메모) 입력 placeholder
    static var planListNoteFieldPlaceholder: String {
        String(localized: "Shopping.planListNoteFieldPlaceholder", defaultValue: "メモを入力", table: "Localizable", bundle: .module)
    }

    /// 플랜 저장 시 덮어쓰기 확인 알림 타이틀
    static var overwriteAlertTitle: String {
        String(localized: "Shopping.overwriteAlertTitle", defaultValue: "お買い物リストを上書きしますか？", table: "Localizable", bundle: .module)
    }
    /// 플랜 저장 시 덮어쓰기 확인 알림 메시지
    static var overwriteAlertMessage: String {
        String(localized: "Shopping.overwriteAlertMessage", defaultValue: "この日程には既にお買い物リストが保存されています。上書きすると、チェック状態を含む既存のリストは削除されます。", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Widget {
    /// 플랜 위젯 갤러리 표시명
    static var planDisplayName: String {
        String(localized: "Widget.planDisplayName", defaultValue: "日程", table: "Localizable", bundle: .module)
    }
    /// 플랜 위젯 갤러리 설명
    static var planDescription: String {
        String(localized: "Widget.planDescription", defaultValue: "直近の旅行日程をホーム画面で確認できます", table: "Localizable", bundle: .module)
    }
    /// 플랜 위젯 - 오늘 시작 표기
    static var planStartsToday: String {
        String(localized: "Widget.planStartsToday", defaultValue: "今日から", table: "Localizable", bundle: .module)
    }
    /// 플랜 위젯 - 디데이 표기 (%d: 남은 일수)
    static func planDaysUntilStart(_ days: Int) -> String {
        String(localized: "Widget.planDaysUntilStart", defaultValue: "あと\(days)日", table: "Localizable", bundle: .module)
    }
    /// 플랜 위젯 - 빈 상태 문구 (등록된 일정 없음)
    static var planEmptyTitle: String {
        String(localized: "Widget.planEmptyTitle", defaultValue: "予定された日程がありません", table: "Localizable", bundle: .module)
    }

    /// 한국어 사전 위젯 갤러리 표시명
    static var phraseDisplayName: String {
        String(localized: "Widget.phraseDisplayName", defaultValue: "簡単な韓国語", table: "Localizable", bundle: .module)
    }
    /// 한국어 사전 위젯 갤러리 설명
    static var phraseDescription: String {
        String(localized: "Widget.phraseDescription", defaultValue: "旅行で使える韓国語フレーズをホーム画面で確認できます", table: "Localizable", bundle: .module)
    }
    /// 한국어 사전 위젯 - 빈 상태 문구 (등록된 문구 없음)
    static var phraseEmptyTitle: String {
        String(localized: "Widget.phraseEmptyTitle", defaultValue: "表示できるフレーズがありません", table: "Localizable", bundle: .module)
    }
    /// 한국어 사전 위젯 - 미디엄 사이즈 좌측 국기 이모지
    static let phraseFlagEmoji = "🇰🇷"
}

public extension Strings.AppUpdate {
    /// 강제 업데이트 Alert 타이틀
    static var alertTitle: String {
        String(localized: "AppUpdate.alertTitle", defaultValue: "アップデートのお知らせ", table: "Localizable", bundle: .module)
    }
    /// 강제 업데이트 Alert 메시지
    static var alertMessage: String {
        String(localized: "AppUpdate.alertMessage", defaultValue: "より快適にご利用いただくため、最新バージョンへのアップデートが必要です", table: "Localizable", bundle: .module)
    }
    /// 강제 업데이트 Alert 업데이트 버튼
    static var updateButtonTitle: String {
        String(localized: "AppUpdate.updateButtonTitle", defaultValue: "アップデート", table: "Localizable", bundle: .module)
    }
}

public extension Strings.Notice {
    /// 팝업/홈 시트 공지 - 오늘 하루 보지 않기 체크박스 라벨
    static var doNotShowTodayLabel: String {
        String(localized: "Notice.doNotShowTodayLabel", defaultValue: "今日はもう表示しない", table: "Localizable", bundle: .module)
    }
    /// 팝업/홈 시트 공지 - 닫기 버튼
    static var closeButtonTitle: String {
        String(localized: "Notice.closeButtonTitle", defaultValue: "閉じる", table: "Localizable", bundle: .module)
    }
}
