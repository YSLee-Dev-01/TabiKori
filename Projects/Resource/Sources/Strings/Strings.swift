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
    public enum Bookmark {}
    public enum Plan {}
    public enum Festival {}
    public enum AddToItinerary {}
    public enum AddCustomPlace {}
    public enum RegionSpot {}
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
    /// 삭제 (스와이프 액션)
    static let delete = "削除"
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
    /// 기타
    static let etc = "その他"
    /// 기타 (한국어)
    static let etcKo = "기타"
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
    /// 위치 재검색 버튼
    static let researchAtCurrentLocation = "このエリアで再検索"
    /// 검색 로딩 표시
    static let loading = "読み込み中"
}

public extension Strings.Bookmark {
    /// 화면 타이틀
    static let title = "保存済み"
    /// 저장 개수 타이틀 (%d: 개수)
    nonisolated(unsafe) static let savedCountTitle: ((Int) -> String) = {
        "\($0)件のスポットを保存中"
    }
    /// 빈 상태 제목
    static let emptyTitle = "保存したスポットがありません"
    /// 빈 상태 설명
    static let emptyDescription = "気になるスポットのハートを押して保存してみましょう"
}

public extension Strings.Plan {
    /// 화면 타이틀
    static let title = "日程"
    /// 신규작성 버튼
    static let newPlanButton = "新規作成"
    /// 진행중 섹션 타이틀
    static let ongoingSectionTitle = "進行中の日程"
    /// 다가오는 섹션 타이틀
    static let upcomingSectionTitle = "今後の日程"
    /// 지난 섹션 타이틀
    static let pastSectionTitle = "過去の日程"
    /// 기간 배지 (%d: 일수)
    nonisolated(unsafe) static let durationBadge: ((Int) -> String) = {
        "\($0)日間"
    }
    /// 일자 칩 (%d: 일차)
    nonisolated(unsafe) static let dayChipTitle: ((Int) -> String) = {
        "\($0)日目"
    }
    /// 합계 스팟 (Detail 미구현으로 항상 0 고정)
    static let totalSpotCountFixed = "合計 0スポット"
    /// 탭하여 상세를 표시 안내 문구
    static let tapToViewDetail = "タップして詳細を表示"
    /// 빈 상태 제목
    static let emptyTitle = "登録された日程がありません"
    /// 빈 상태 설명
    static let emptyDescription = "右上の「新規作成」から旅行の日程を追加してみましょう"

    /// 스팟 빈 상태 제목
    static let spotEmptyTitle = "まだスポットがありません"
    /// 스팟 빈 상태 설명
    static let spotEmptyDescription = "観光地や飲食店の詳細ページから「日程に追加する」で追加できます"
    /// 스팟 0건 안내
    static let spotCountZero = "スポットがまだ追加されていません"
    /// 스팟 N건 안내 (%d: 스팟 개수)
    nonisolated(unsafe) static let spotCountTitle: ((Int) -> String) = {
        "\($0)件のスポットが追加されています"
    }
    /// 소요시간 (%d: 분)
    nonisolated(unsafe) static let spotDurationTitle: ((Int) -> String) = {
        "\($0)分"
    }
    /// 스팟 추가 버튼 (일자 목록 footer)
    static let spotAddButtonTitle = "スポットを追加"
    /// 스팟 추가 시트 - 관광지 검색 탭
    static let spotAddSearchTabTitle = "観光地検索"

    /// 추가 화면 타이틀
    static let addScreenTitle = "新しい日程を作成"
    /// 일정명 라벨
    static let nameLabel = "日程名"
    /// 일정명 placeholder
    static let namePlaceholder = "例：ソウル春旅行 2026"
    /// 도시 라벨
    static let cityLabel = "都市"
    /// 기타 지역명 placeholder
    static let customRegionPlaceholder = "地域名を入力"
    /// 아이콘(이모지) 라벨
    static let emojiLabel = "アイコン"
    /// 아이콘(이모지) placeholder
    static let emojiPlaceholder = "絵文字を入力"
    /// 날짜 라벨
    static let dateLabel = "日付"
    /// 출발 라벨
    static let departureLabel = "出発"
    /// 귀국 라벨
    static let returnLabel = "帰国"
    /// 날짜 미선택 placeholder
    static let datePlaceholder = "---"
    /// 확인(작성) 버튼
    static let confirmButton = "日程を作成する"
    /// 저장 실패 알림 타이틀
    static let saveFailedAlertTitle = "保存に失敗しました"
    /// 저장 실패 알림 메시지
    static let saveFailedAlertMessage = "もう一度お試しください"
    /// 알림 확인 버튼
    static let alertConfirm = "確認"
    /// 편집 메뉴 타이틀
    static let editMenuTitle = "編集"
    /// 편집 모드 저장 버튼
    static let editSaveButton = "保存"
    /// 편집 모드 취소 버튼
    static let editCancelButton = "キャンセル"
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
    /// 공유 텍스트 - 장소명 접두사
    static let shareTitlePrefix = "🏯"
    /// 공유 텍스트 - 주소 접두사
    static let shareAddressPrefix = "📍"
    /// 공유 텍스트 - 링크 접두사
    static let shareLinkPrefix = "🔗"
}

public extension Strings.AddToItinerary {
    /// 시작 시각 라벨
    static let startTimeLabel = "開始時刻"
    /// 종료 시각 라벨
    static let endTimeLabel = "終了時刻"
    /// 소요시간 라벨
    static let durationLabel = "所要時間"
    /// 저장(추가) 버튼
    static let saveButton = "追加する"
}

public extension Strings.AddCustomPlace {
    /// 화면 타이틀
    static let screenTitle = "カスタムスポットを追加"
    /// Bookmark 화면 진입 버튼
    static let entryButtonTitle = "カスタムスポット"
    /// 타이틀 입력 라벨
    static let titleLabel = "タイトル"
    /// 타이틀 입력 placeholder
    static let titlePlaceholder = "スポット名を入力"
    /// 주소 입력 라벨
    static let addressLabel = "住所"
    /// 주소 입력 placeholder
    static let addressPlaceholder = "住所を入力"
    /// 저장 버튼
    static let saveButton = "保存する"
    /// 주소를 찾을 수 없음 알림 타이틀
    static let addressNotFoundAlertTitle = "住所が見つかりませんでした"
    /// 주소를 찾을 수 없음 알림 메시지
    static let addressNotFoundAlertMessage = "住所を確認してもう一度お試しください"
    /// 커스텀 스팟 배지 타이틀
    static let customBadgeTitle = "カスタム"
}

public extension Strings.RegionSpot {
    /// 관광지 섹션 제목
    static let spotSectionTitle = "観光スポット"
    /// 축제 섹션 제목
    static let festivalSectionTitle = "開催中のイベント"
    /// 관광지 빈 상태 제목
    static let spotEmptyTitle = "観光スポットが見つかりませんでした"
    /// 관광지 빈 상태 설명
    static let spotEmptyDescription = "他のカテゴリーもお試しください"
    /// 축제 빈 상태 설명
    static let festivalEmptyDescription = "現在開催中のイベントはありません"
    /// 에러 상태 제목
    static let errorTitle = "読み込みに失敗しました"
    /// 에러 상태 설명
    static let errorDescription = "通信状態を確認してもう一度お試しください"
    /// 재시도 버튼 라벨
    static let retryButtonTitle = "再試行"
}

public extension Strings.Festival {
    /// 검색 시작일 라벨
    static let startDateLabel = "検索開始日"
    /// 검색 종료일 라벨
    static let endDateLabel = "検索終了日"
    /// 결과 없음 제목
    static let emptyTitle = "イベントが見つかりませんでした"
    /// 결과 없음 설명
    static let emptyDescription = "条件を変更して再度お試しください"
    /// 종료일 지정 시 기간 내 완결 이벤트만 표시된다는 안내 문구
    static let dateRangeFilterNotice = "終了日を指定すると、期間内に開催が完結するイベントのみ表示されます"
}
