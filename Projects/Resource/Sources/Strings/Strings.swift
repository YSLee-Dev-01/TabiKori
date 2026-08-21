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
    public enum Setting {}
    public enum ToolBar {}
    public enum KoreanPhrase {}
    public enum Shopping {}
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
    /// 지하철
    static let categorySubway = "地下鉄"
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
    /// 지하철역 검색 시 가타카나 입력 안내 문구
    static let subwayKatakanaGuide = "カタカナで入力してください"
    /// 지하철역명 입력 후 검색 안내 문구
    static let subwaySearchEnterGuide = "Enterキーで検索してください"
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
    /// 진행중인 플랜이 있을 때 한국 배너 부제목 (%@: 일차)
    nonisolated(unsafe) static let inKoreaBannerOngoingPlanSubtitle: ((String) -> String) = {
        "\($0) 旅です！"
    }
    /// 플랜으로 이동 버튼
    static let moveToPlanButton = "プランへ移動"
    /// 환율 위젯 - 툴박스 탭으로 이동 버튼
    static let moveToToolBoxButton = "ツールボックスへ移動"
    /// 환율 기준 시각 (%@: 날짜/시간)
    nonisolated(unsafe) static let exchangeRateUpdatedAtTitle: ((String) -> String) = {
        "為替レート基準時刻: \($0)"
    }
    /// 축제 더보기 버튼
    static let festivalMoreButtonTitle = "もっと見る"
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
    /// 툴박스
    static let toolbox = "ツール"
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
    /// 지하철역 검색 결과 노출 시 가타카나 입력 안내 문구
    static let subwayKatakanaSearchGuide = "駅名を検索する際はカタカナのみで入力してください"
    /// 검색 시 한국어/영어 입력 안내 문구
    static let searchLanguageGuide = "韓国語・英語で検索すると、より正確な結果が得られます"
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
    /// 합계 스팟 (%d: 스팟 개수)
    nonisolated(unsafe) static let totalSpotCount: ((Int) -> String) = {
        "合計 \($0)スポット"
    }
    /// 빈 상태 제목
    static let emptyTitle = "登録された日程がありません"
    /// 빈 상태 설명
    static let emptyDescription = "右上の「新規作成」から旅行の日程を追加してみましょう"

    /// 스팟 빈 상태 제목
    static let spotEmptyTitle = "まだスポットがありません"
    /// 스팟 빈 상태 설명
    static let spotEmptyDescription = "観光地や飲食店の詳細ページから「日程に追加する」で追加できます"
    /// 지도 빈 상태 설명
    static let mapEmptyDescription = "地図に表示するスポットがありません"
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
    /// 스팟 추가 시트 - 주소로 추가 탭
    static let spotAddAddressTabTitle = "住所で追加"

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
    /// 스팟 삭제 실패 알림 타이틀
    static let spotDeleteFailedAlertTitle = "削除に失敗しました"
    /// 스팟 삭제 실패 알림 메시지
    static let spotDeleteFailedAlertMessage = "もう一度お試しください"
    /// 일정 삭제 확인 알림 타이틀
    static let planDeleteAlertTitle = "この日程を削除しますか？"
    /// 일정 삭제 확인 알림 메시지
    static let planDeleteAlertMessage = "削除すると元に戻せません"
    /// 플랜 자체 편집 메뉴 타이틀
    static let planEditMenuTitle = "予定を編集"
    /// 플랜 자체 삭제 메뉴 타이틀 (상세 화면 "..." 메뉴)
    static let planDeleteMenuTitle = "日程を削除"
    /// 플랜 편집 화면 타이틀
    static let editPlanScreenTitle = "日程を編集"
    /// 날짜 축소 확인 알림 타이틀
    static let dayShrinkAlertTitle = "日程が短くなります"
    /// 날짜 축소 확인 알림 메시지 (%d: 삭제 시작 일차)
    nonisolated(unsafe) static let dayShrinkAlertMessage: ((Int) -> String) = {
        "\($0)日目以降のスポットは削除されます。よろしいですか？"
    }
    /// 알림 취소 버튼
    static let alertCancel = "キャンセル"
    /// 전체보기 토글 타이틀
    static let fullOverviewToggleTitle = "全体表示"
    /// 일자별 보기로 돌아가기 타이틀
    static let dayOverviewToggleTitle = "日別表示に戻る"
    /// 내보내기 메뉴 타이틀
    static let exportMenuTitle = "エクスポート"
    /// 추가 메뉴 타이틀
    static let addMenuTitle = "追加"
    /// 가져오기 메뉴 타이틀
    static let importMenuTitle = "インポート"
    /// 가져오기 성공 알림 타이틀
    static let importSuccessAlertTitle = "インポートが完了しました"
    /// 가져오기 성공 알림 메시지
    static let importSuccessAlertMessage = "日程一覧に追加されました"
    /// 가져오기 실패 알림 타이틀
    static let importFailedAlertTitle = "インポートに失敗しました"
    /// 가져오기 실패 알림 메시지
    static let importFailedAlertMessage = "ファイルを確認してもう一度お試しください"

    /// 쇼핑 리스트 버튼 (준비물 버튼 옆)
    static let shoppingListButtonTitle = "買い物"
    /// 지도 전체화면 보기 버튼 (접근성 라벨)
    static let fullMapButtonAccessibilityLabel = "地図を全画面で見る"
    /// 편집모드 스팟 시간 수정 바텀시트 타이틀
    static let timeEditSheetTitle = "時間を編集"
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
    /// 노선 (지하철역 전용)
    static let infoLine = "路線"
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
    static let viewInMap = "NAVERマップで見る"
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
    static let screenTitle = "スポットを追加"
    /// Bookmark 화면 진입 버튼
    static let entryButtonTitle = "カスタムスポット"
    /// 검색 탭 라벨
    static let searchTabLabel = "検索"
    /// 커스텀 탭 라벨
    static let customTabLabel = "カスタム"
    /// 주소 입력 하단 안내 문구 (한국어 검색 권장)
    static let addressKoreanSearchGuide = "住所は韓国語で検索すると、より正確に見つかります"
    /// 타이틀 입력 라벨
    static let titleLabel = "タイトル"
    /// 타이틀 입력 placeholder
    static let titlePlaceholder = "スポット名を入力"
    /// 지하철역 모드 타이틀 입력 라벨(역명)
    static let stationTitleLabel = "駅名"
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
    /// 지하철역 모드 타이틀 입력 placeholder
    static let stationTitlePlaceholder = "駅名を入力"
    /// 지하철역 좌표 조회 실패 알림 타이틀
    static let stationResolveFailedAlertTitle = "駅の位置情報を取得できませんでした"
    /// 지하철역 좌표 조회 실패 알림 메시지
    static let stationResolveFailedAlertMessage = "もう一度お試しください"
}

public extension Strings.RegionSpot {
    /// 축제 섹션 제목
    static let festivalSectionTitle = "開催中のイベント"
    /// 관광지 탭 라벨
    static let spotTabLabel = "観光スポット"
    /// 이벤트 탭 라벨
    static let festivalTabLabel = "イベント"
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

public extension Strings.Setting {
    /// 화면 타이틀
    static let screenTitle = "設定"

    /// GPS 권한 섹션 타이틀
    static let gpsSectionTitle = "位置情報の権限"
    /// GPS 권한 행 타이틀
    static let gpsRowTitle = "位置情報へのアクセス"
    /// GPS 권한 상태 - 허용
    static let gpsStatusAllowed = "許可済み"
    /// GPS 권한 상태 - 거부
    static let gpsStatusDenied = "拒否"
    /// GPS 권한 상태 - 미결정
    static let gpsStatusUndetermined = "未設定"

    /// 일정 상세 섹션 타이틀
    static let planDetailSectionTitle = "日程詳細"
    /// 오늘 날짜 자동 이동 토글 행 타이틀
    static let autoScrollToTodayRowTitle = "今日の日程へ自動移動"
    /// 오늘 날짜 자동 이동 토글 행 설명
    static let autoScrollToTodayRowDescription = "日程詳細を開いたとき、今日に該当する日を自動的に表示します"

    /// 데이터 초기화 섹션 타이틀
    static let dataResetSectionTitle = "データの初期化"
    /// 데이터 초기화 행 타이틀
    static let dataResetRowTitle = "すべてのデータを初期化"
    /// 데이터 초기화 행 설명
    static let dataResetRowDescription = "保存したスポット、旅程、最近の検索履歴が削除されます"
    /// 초기화 확인 Alert 타이틀
    static let dataResetAlertTitle = "データを初期化しますか？"
    /// 초기화 확인 Alert 메시지
    static let dataResetAlertMessage = "保存済みスポット・旅程・最近の検索履歴が削除されます。この操作は取り消せません。"
    /// 초기화 확인 Alert 삭제(확정) 버튼
    static let dataResetAlertConfirmButton = "初期化する"
    /// 초기화 성공 Alert 타이틀
    static let dataResetSuccessAlertTitle = "初期化が完了しました"
    /// 초기화 실패 Alert 타이틀
    static let dataResetFailureAlertTitle = "初期化に失敗しました"
    /// 초기화 실패 Alert 메시지
    static let dataResetFailureAlertMessage = "一部のデータが削除できませんでした。もう一度お試しください"

    /// 기타 섹션 타이틀
    static let etcSectionTitle = "その他"
    /// 데이터 출처 행 타이틀
    static let etcDataSourceTitle = "データ出典"
    /// 개인정보처리방침 행 타이틀
    static let etcPrivacyPolicyTitle = "プライバシーポリシー"
    /// 오픈소스 라이선스 행 타이틀
    static let etcLicenseTitle = "オープンソースライセンス"
    /// 기타 정보 행 타이틀
    static let etcInfoTitle = "その他の情報"
    /// 문의하기 행 타이틀
    static let etcContactTitle = "お問い合わせ"
    /// 버전 정보 행 타이틀
    static let etcVersionTitle = "バージョン情報"
    /// 비활성화(TODO) 행 보조 라벨
    static let etcComingSoonLabel = "準備中"

    /// 데이터 출처 안내 본문
    static let dataSourceContent = "本アプリは韓国観光公社 多言語観光情報サービス(EngService2)、NAVER 地図・Geocoding API、為替レートAPIの情報を利用しています。"
    /// 오픈소스 라이선스 안내 본문
    static let licenseContent = "本アプリは以下のオープンソースライブラリを使用しています。\n\n・swift-composable-architecture\n・Kingfisher\n・lottie-ios\n・firebase-ios-sdk\n・SPM-NMapsMap"
    /// 기타 정보 안내 본문 (TODO: 내용 추가 예정)
    static let etcInfoContent = ""
    /// 버전 정보 표시 (%@: 버전, %@: 빌드번호)
    nonisolated(unsafe) static let versionTitle: ((String, String) -> String) = { version, build in
        "バージョン \(version) (\(build))"
    }
}

public extension Strings.ToolBar {
    /// 허브 화면(툴박스 탭) 타이틀
    static let hubTitle = "ツールボックス"
    /// 화면 타이틀 (마스터/저장된 체크리스트 공용)
    static let title = "持ち物リスト"
    /// 플랜에 전체 추가 버튼
    static let saveToPlanButton = "すべて旅程に追加"
    /// 마스터 리스트 로드 실패 설명
    static let loadFailedDescription = "リストを読み込めませんでした"

    /// 개별 추가 안내 문구 (리스트 상단)
    static let individualAddGuideDescription = "アイテムをタップすると、その項目だけ旅程に追加できます"

    /// 준비물 빈 상태 제목 (마스터 리스트 0건)
    static let itemEmptyTitle = "登録された持ち物がありません"
    /// 준비물 빈 상태 설명 (마스터 리스트 0건)
    static let itemEmptyDescription = "しばらくしてから再度お試しください"

    /// 플랜 선택 시트 타이틀
    static let planPickerTitle = "保存する旅程を選択"
    /// 플랜 선택 시트 빈 상태 제목 (플랜 0건)
    static let planPickerEmptyTitle = "登録された日程がありません"
    /// 플랜 선택 시트 빈 상태 설명 (플랜 0건)
    static let planPickerEmptyDescription = "先に旅程を作成してください"

    /// 덮어쓰기 확인 알림 타이틀
    static let overwriteAlertTitle = "持ち物リストを上書きしますか？"
    /// 덮어쓰기 확인 알림 메시지
    static let overwriteAlertMessage = "この旅程には既に持ち物リストが保存されています。上書きすると、チェック状態を含む既存のリストは削除されます。"
    /// 덮어쓰기 확인 버튼
    static let overwriteAlertConfirm = "上書きする"
    /// 덮어쓰기 알림 취소 버튼
    static let overwriteAlertCancel = "キャンセル"
    /// 덮어쓰기 알림 - 기존 리스트 아래에 추가 버튼
    static let appendAlertConfirm = "下に追加する"

    /// 저장 실패 설명
    static let saveFailedDescription = "保存に失敗しました。もう一度お試しください"

    /// PlanDetail 진입 버튼 (접근성 라벨)
    static let planDetailEntryTitle = "持ち物"

    /// 저장된 체크리스트 빈 상태 제목 (아직 저장 안 됨)
    static let savedEmptyTitle = "持ち物リストがまだありません"
    /// 저장된 체크리스트 빈 상태 설명 (아직 저장 안 됨)
    static let savedEmptyDescription = "ツールタブの持ち物リストから、この旅程に保存できます"
    /// 완료 개수 표시 (%d: 완료 개수, %d: 전체 개수)
    nonisolated(unsafe) static let checkedCountTitle: ((Int, Int) -> String) = { checked, total in
        "\(checked)/\(total) 完了"
    }

    /// 허브 화면 - 준비물 섹션 타이틀
    static let packingSectionTitle = "持ち物リスト"
    /// 허브 화면 - 섹션 공용 더보기 버튼 (준비물/한국어 섹션)
    static let seeAllButton = "もっと見る"
    /// 허브 화면 - 환율 섹션 타이틀
    static let exchangeRateSectionTitle = "為替レート"

    /// PlanDetail 저장된 체크리스트 - 추가 버튼 (접근성 라벨)
    static let addButtonAccessibilityLabel = "項目を追加"
    /// PlanDetail 저장된 체크리스트 - 추가모드 진입 시 닫기 버튼 (접근성 라벨)
    static let closeAddButtonAccessibilityLabel = "追加をやめる"
    /// PlanDetail 저장된 체크리스트 - 편집 버튼 (접근성 라벨)
    static let editButtonAccessibilityLabel = "編集"
    /// PlanDetail 저장된 체크리스트 - 항목 추가 입력 placeholder
    static let addItemPlaceholder = "項目を入力"
    /// PlanDetail 저장된 체크리스트 - 편집모드 서브타이틀(메모) 필드 라벨
    static let noteFieldLabel = "メモ"
    /// PlanDetail 저장된 체크리스트 - 편집모드 서브타이틀(메모) 입력 placeholder
    static let noteFieldPlaceholder = "メモを入力"
}

public extension Strings.KoreanPhrase {
    /// 허브 화면 - 한국어 섹션 타이틀
    static let sectionTitle = "簡単な韓国語"
    /// 전체 문구 목록 화면 타이틀
    static let listTitle = "簡単な韓国語"
    /// 문구 리스트 로드 실패 설명
    static let loadFailedDescription = "リストを読み込めませんでした"
    /// 빈 상태 제목 (문구 0건)
    static let emptyTitle = "登録されたフレーズがありません"
    /// 빈 상태 설명 (문구 0건)
    static let emptyDescription = "しばらくしてから再度お試しください"
    /// 문구 셀 롱프레스 메뉴 - 복사
    static let copyMenuTitle = "コピー"
    /// 문구 셀 롱프레스 메뉴 - 크게보기
    static let viewLargeMenuTitle = "拡大表示"
}

public extension Strings.Shopping {
    /// 허브 화면 - 추천 쇼핑 리스트 섹션 타이틀
    static let sectionTitle = "おすすめのお買い物リスト"
    /// 추천 쇼핑 리스트 로드 실패 설명
    static let loadFailedDescription = "リストを読み込めませんでした"
    /// 빈 상태 제목 (추천 쇼핑 아이템 0건)
    static let emptyTitle = "登録されたおすすめ商品がありません"
    /// 빈 상태 설명 (추천 쇼핑 아이템 0건)
    static let emptyDescription = "しばらくしてから再度お試しください"

    /// PlanDetail 연동 쇼핑 리스트 화면 타이틀
    static let planListTitle = "お買い物リスト"
    /// PlanDetail 연동 쇼핑 리스트 - 저장된 목록 빈 상태 제목 (아직 저장 안 됨)
    static let planListSavedEmptyTitle = "お買い物リストがまだありません"
    /// PlanDetail 연동 쇼핑 리스트 - 저장된 목록 빈 상태 설명 (아직 저장 안 됨)
    static let planListSavedEmptyDescription = "右上の＋ボタンから、買いたいものを追加しましょう"
    /// PlanDetail 연동 쇼핑 리스트 - 완료 개수 표시 (%d: 완료 개수, %d: 전체 개수)
    nonisolated(unsafe) static let planListCheckedCountTitle: ((Int, Int) -> String) = { checked, total in
        "\(checked)/\(total) 完了"
    }
    /// PlanDetail 연동 쇼핑 리스트 - 추가 버튼 (접근성 라벨)
    static let planListAddButtonAccessibilityLabel = "項目を追加"
    /// PlanDetail 연동 쇼핑 리스트 - 추가모드 진입 시 닫기 버튼 (접근성 라벨)
    static let planListCloseAddButtonAccessibilityLabel = "追加をやめる"
    /// PlanDetail 연동 쇼핑 리스트 - 편집 버튼 (접근성 라벨)
    static let planListEditButtonAccessibilityLabel = "編集"
    /// PlanDetail 연동 쇼핑 리스트 - 항목 추가 입력 placeholder
    static let planListAddItemPlaceholder = "項目を入力"
    /// PlanDetail 연동 쇼핑 리스트 - 편집모드 서브타이틀(메모) 필드 라벨
    static let planListNoteFieldLabel = "メモ"
    /// PlanDetail 연동 쇼핑 리스트 - 편집모드 서브타이틀(메모) 입력 placeholder
    static let planListNoteFieldPlaceholder = "メモを入力"
}
