# Plan: festival

## 참조 Spec
- @specs/features/festival/spec.md

## 참조 Skill
신규 화면 생성 시
- @skills/create-feature/SKILL.md — 현재 레포에 존재하지 않음. 대신 최근 신규 화면 선례인 `Presentation/Bookmark/`, `Presentation/PlanDetail/` 구조를 참조한다.

## 현재 상태 파악

### 신규
- **Domain**
  - `Entity/Festival.swift` — 행사 도메인 모델 (`touristSpot: TouristSpot` + `startDate` / `endDate`, 결정 1)
  - `Entity/LDongRegion.swift` — 시/도 단위 법정동 지역 (`code`, `name`)
  - `RepositoryProtocol/FestivalRepositoryProtocol.swift` — `fetchFestivals(...)`, `fetchRegions()`
  - `UseCase/Festival/FestivalUseCaseProtocol.swift` — 프로토콜 + 기본 조회 기간 상수(`TouristSpotSearchRadius` 선례처럼 같은 파일에 배치)
  - `UseCase/Festival/FestivalUseCase.swift` — Repository 위임
  - `UseCase/Festival/TestFestivalUseCase.swift` — `var` 프로퍼티 주입형 테스트 더블
  - `Dependency/Keys/FestivalUseCaseDependencyKey.swift` — `TestDependencyKey` + `testValue`
- **Data**
  - `Network/EndPoint/FestivalEndpoint.swift` — `.searchFestival(...)`, `.ldongCode(...)` 2케이스
  - `DTO/Festival/FestivalDTO.swift` — `FestivalResponseDTO` / `FestivalItemDTO` + `toEntities()`
  - `DTO/Festival/LDongRegionDTO.swift` — `LDongRegionResponseDTO` / 아이템 DTO + `toEntities()`
  - `Repository/Festival/FestivalRepository.swift` — `FestivalRepositoryProtocol` 구현
  - `Extension/Date+.swift` — 요청용 `yyyyMMdd` 문자열 변환 (캐시된 `static let` DateFormatter, 결정 6)
  - `Extension/String+.swift` — 응답 `yyyyMMdd` → `Date` 파싱 (Data 내부용)
- **App**
  - `Dependency/FestivalUseCaseDependencyKey.swift` — `liveValue` (`FestivalUseCase(repository: FestivalRepository())`)
- **DesignSystem**
  - `Card/TabiFestivalRow.swift` — 썸네일 + 제목 + 행사 기간 셀 (primitive 파라미터, 결정 7)
- **Presentation**
  - `Festival/FestivalFeature.swift`, `Festival/FestivalView.swift`
  - `Festival/Sub/FestivalDateRangeView.swift` — 기간 요약 박스 + `TabiRangeCalendar`
  - `Festival/Sub/FestivalRegionFilterBar.swift` — `TabiChip` 수평 스크롤
  - `Festival/Sub/FestivalEmptyState.swift` — 결과 없음 상태
  - `Festival/Model/Festival+.swift` — `periodTitle`(`M/d ~ M/d`) 등 화면 표시용 파생 값
  - `Festival/FestivalMock.swift` (선택) — Preview용 목 데이터 (`DetailMock` / `PlanDetailMock` 선례)
- **Resource**
  - `Strings.swift`에 `Strings.Festival` 네임스페이스 신설 (기존 파일 수정)

### 재사용
- `TabiRangeCalendar`(DesignSystem) — 날짜 범위 선택, `Binding<Date?>` 2개 인터페이스 그대로 사용. "첫 탭 = startDate 세팅 + endDate nil 리셋" 규칙이 재조회 타이밍 결정에 직결 (결정 5)
- `TabiChip` — 지역 필터 칩 (`BookmarkCategoryFilterBar` 선례와 동일 구조)
- `TabiNavigationBar`, `TabiLabel`, `TabiCard`, `TabiColor`, `TabiRadius`, `TabiPressStyle`, `TabiAnimation`
- `PlanDetailView`의 뒤로가기 패턴 — `.toolbar` + `chevron.left` + `navigationBarBackButtonHidden(true)` + `.interactivePopGestureEnabled(true)`
- `DetailFeature.State(touristSpot:)` — 무수정 재사용 (결정 1로 변환 코드 불필요)
- `CategoryType.festival` ↔ `apiCode "85"`(`Data/Extension/CategoryType+.swift`) — 상세 화면의 `detailIntro2` 호출이 축제 스키마로 파싱되도록 `TouristSpot.contentType`을 정확히 채우는 데 사용
- `TouristSpot`의 `japaneseTitle` / `koreanTitle` / `thumbnailURL` 파생 로직
- `Coordinate.zero` — 좌표 파싱 실패 시 대체값 (`TouristSpotItemDTO.toEntity()` 선례)
- `TouristSpotResponseDTO`의 `Items` 커스텀 `init(from:)` — 응답 `items`가 빈 문자열로 오는 케이스 방어 로직을 그대로 이식
- `Secret.tourAPIKey`, `NetworkService`, `Endpoint` 프로토콜, `NetworkError`, `TabiError.apiFailed`
- `AppLogger.network` / `AppLogger.view`
- `Strings.Common.contentTypeAll`("すべて") — 지역 필터 해제 칩 라벨 (신규 문자열 불필요)
- `Presentation/Extension/Date+.swift` — 날짜 타이틀 포맷 선례 (신규 포맷은 이 파일에 추가)

### 수정
- `Domain/Sources/Dependency/DependencyValues.swift` — `festivalUseCase` 프로퍼티 추가
- `Presentation/Sources/Navigation/StackPath.swift` — `case festival(FestivalFeature)` 추가
- `Presentation/Sources/Tabbar/TabBarFeature.swift` — `home(.recommendedEventBannerTapped)` → `.festival` push, `path(... .festival(.festivalTapped))` → `.detail` push
- `Presentation/Sources/Tabbar/TabBarView.swift` — `destination` 스위치에 `.festival` 케이스 추가
- `Presentation/Sources/Home/HomeFeature.swift` — `recommendedEventBannerTapped` 액션 추가 (자체 처리 없음, 부모가 라우팅)
- `Presentation/Sources/Home/HomeView.swift` — `recommendedEventBanner()`의 빈 `Button` 액션에 `store.send(.recommendedEventBannerTapped)` 연결
- `Presentation/Sources/Extension/Date+.swift` — `festivalPeriodDateTitle`(`M/d`) 추가
- `Resource/Sources/Strings/Strings.swift` — `Strings` 네임스페이스에 `Festival` 추가 + 문자열 정의

### 삭제
- 없음 (기존 코드 제거 대상 없음. `recommendedEventBanner`의 빈 클로저는 원래 미구현 placeholder이므로 대체가 아닌 채움)

---

## 기술적 결정사항

- **[결정 1] `Festival` 엔티티 구조 → `TouristSpot` 컴포지션 + 행사 기간(종료일 옵셔널)**
  - `Festival { touristSpot: TouristSpot, startDate: Date, endDate: Date? }` 형태. `Bookmark { touristSpot, savedAt }` 선례와 동일한 조합 방식. `endDate`는 결정 4에 따라 옵셔널.
  - 이유: spec의 "Festival → TouristSpot 변환 필요"를 별도 매핑 함수 없이 해결하고, `DetailFeature.State(touristSpot:)`를 무수정 재사용할 수 있음. `japaneseTitle` / `koreanTitle` / `thumbnailURL` 파생 로직과 좌표 보존도 자동으로 따라옴.
  - 대안: 평평한 프로퍼티(title/thumbnail/coordinate...)를 직접 갖고 `toTouristSpot()` 변환 메서드를 두는 방식 → 필드 중복 + 변환 코드가 늘고, 필드 추가 시 두 타입을 함께 고쳐야 함.

- **[결정 2] UseCase/Repository 분리 → `Festival` 단일 스택이 `searchFestival2` + `ldongCode2` 둘 다 담당**
  - `FestivalEndpoint`에 2케이스, `FestivalRepositoryProtocol`에 `fetchFestivals` / `fetchRegions` 2메서드, DependencyKey·liveValue·`DependencyValues`는 1세트.
  - 이유: `TouristSpotEndpoint`가 5개 케이스(nearby/detail/intro/images/searchKeyword)를 하나의 Endpoint·Repository·UseCase로 묶는 기존 선례와 일치. 지역 목록은 현재 Festival 화면 전용이므로 별도 스택은 과설계.
  - 대안 / 승격 경로: 이후 다른 화면(지도 지역 필터 등)에서 법정동 코드가 필요해지면 `LDongRegion` 전용 UseCase/Repository로 분리. `LDongRegion` 엔티티를 처음부터 Festival 비의존으로 정의해 두어 이 분리를 저비용으로 만든다.

- **[결정 3] API 서비스 경로 → `JpnService2` 확정 (사용자 확인 + 실측 검증 완료)**
  - `searchFestival2` / `ldongCode2` 모두 기존 `TouristSpotEndpoint`와 동일하게 `/B551011/JpnService2/...` 경로를 사용한다. CLAUDE.md 본문의 `EngService2` 표기와는 다르지만, 이 레포의 기존 Endpoint가 이미 `JpnService2`를 쓰고 있으므로 그 선례를 따른다.
  - **실측 결과(Task 1, 2026-08-03 확인)**: 두 API 모두 `JpnService2` 경로에서 정상 응답(`resultCode: "0000"`)함을 실제 호출로 확인. `searchFestival2` 응답 필드는 문서와 동일(`contentid`/`contenttypeid`/`title`/`addr1`/`addr2`/`firstimage`/`firstimage2`/`mapx`/`mapy`/`mlevel`/`eventstartdate`/`eventenddate`/`lDongRegnCd`/`lDongSignguCd` 등). `ldongCode2`(`lDongListYn=N`, `lDongRegnCd` 미지정)는 시/도 16개 목록을 `code`/`name`/`rnum` 필드로 반환.

- **[결정 4] 날짜 범위 → API 파라미터 매핑, `endDate`는 옵셔널 (사용자 확인 + 실측 검증 완료)**
  - **실측 결과(Task 1, 2026-08-03 확인)**: `eventStartDate`/`eventEndDate`는 문서 설명("행사 시작일"/"행사 종료일")과 달리 실제로는 **범위 겹침(overlap) 필터**로 동작한다.
    - `eventStartDate`(필수) = 하한: `event.eventenddate >= eventStartDate` 인 행사만 반환 (아직 종료되지 않은 행사)
    - `eventEndDate`(옵셔널) = 상한: 추가로 `event.eventstartdate <= eventEndDate` 인 행사만 필터링 (이미 시작된 행사)
    - 두 조건을 합치면 정확히 "선택 범위와 겹치는 행사"가 반환되므로, 장기 행사가 결과에서 빠지는 문제는 원래부터 발생하지 않는다. (검증: `eventStartDate`만 보낸 호출에서 반환된 모든 항목의 `eventenddate`가 파라미터 값 이상이었고, 시작일이 파라미터보다 이전인 장기 행사도 정상 포함됨)
  - `eventEndDate`는 API상 필수 파라미터가 아니므로, 이를 그대로 반영해 `Festival` / `FestivalUseCaseProtocol.fetchFestivals` / `FestivalEndpoint` 전 계층에서 `endDate: Date?`로 다룬다.
  - `endDate`가 있으면 `eventStartDate`/`eventEndDate` 둘 다 쿼리에 포함하고, `endDate`가 `nil`("종료일 없음/무제한" 토글 ON)이면 `eventStartDate`만 전송한다 → 상한 없이 시작일 이후 종료되지 않은 모든 행사가 조회된다.
  - 클라이언트 측 로컬 후처리 필터(`eventstartdate <= endDate` 등)는 실측으로 불필요함이 확인되었다 — 도입하지 않는다.
  - 행사 기간 표시(`periodTitle`)도 `endDate`가 `nil`이면 `M/d ~`(종료일 미표기) 형식으로 처리한다(`Festival+.swift`).

- **[결정 5] 재조회 트리거 → `startDate` 확정 시점 + 토글 변경 + `cancelInFlight`**
  - `TabiRangeCalendar`는 첫 탭에서 `startDate`를 세팅하고 `endDate`를 `nil`로 리셋하므로, 재조회는 `startDate != nil`이면 발생시킨다(`endDate`는 옵셔널이므로 조회 조건에서 제외). 즉 시작일만 선택된 상태에서도 검색이 가능하다.
  - "종료일 없음/무제한" 토글 ON/OFF, 종료일 재선택, 지역 변경 모두 동일 effect를 `.cancellable(id: CancelID.festivalSearch, cancelInFlight: true)`로 발행 → spec의 "이전 요청 취소, 최신 조건만 반영" 충족. `HomeFeature.categoryTapped`의 `CancelID` 패턴을 그대로 따른다.
  - 토글이 ON일 때 `TabiRangeCalendar`의 종료일 선택 UI는 비활성화(또는 시각적으로 흐리게 처리)하고, 토글을 다시 끄면 마지막으로 선택했던 종료일(또는 기본값 +30일)로 복원한다.
  - 취소된 요청은 `Task.isCancelled` 가드로 `AppLogger.view.log(.debug, ...)`만 남기고 상태를 건드리지 않는다(`HomeFeature.fetchNearbySpotsEffect` 선례).

- **[결정 6] `yyyyMMdd` 변환 → Data 레이어 전용 Extension + 캐시된 DateFormatter**
  - 요청 포맷은 `Data/Extension/Date+.swift`, 응답 파싱은 `Data/Extension/String+.swift`에 배치(`{Type}+.swift` 네이밍 규칙 준수). `DateFormatter`는 아이템마다 생성하지 않고 `static let`으로 캐시하며 `Locale(identifier: "en_US_POSIX")` + 한국 기준 `TimeZone`을 명시한다.
  - 이유: 표시용 포맷은 Presentation, 전송/파싱용 포맷은 Data로 책임을 나눈다. Core의 `String+`는 전 모듈 공용이므로 관광공사 API 전용 포맷을 넣지 않는다.
  - `Presentation/Extension/Date+.swift`에는 표시용 `festivalPeriodDateTitle`(`M/d`)만 추가하고, `Festival+.swift`에서 `"\(start) ~ \(end)"`로 조합한다.

- **[결정 7] 결과 셀 → DesignSystem에 `TabiFestivalRow` 신설**
  - `TabiSpotRow`는 태그/거리 슬롯이 고정되어 행사 기간 표시에 맞지 않고, 파라미터를 옵셔널로 늘리면 기존 호출부(Map/Bookmark)까지 영향받는다. 별도 컴포넌트로 분리.
  - DesignSystem은 `Domain`을 참조할 수 없으므로(`DependencyInformation`: designSystem → core, resource) `thumbnailURL: URL?`, `japaneseTitle: String`, `koreanTitle: String?`, `periodTitle: String`, `onTap: () -> Void` primitive 파라미터만 받는다(`TabiSpotRow` 승격 시 확립한 원칙과 동일). 썸네일 placeholder는 `Kingfisher` + `calendar` 계열 SF Symbol.

- **[결정 8] 화면 진입/라우팅 → `StackPath.festival` 추가, push는 `TabBarFeature`가 담당**
  - `HomeFeature`는 `recommendedEventBannerTapped`만 발신하고 라우팅하지 않는다(`home(.nearbySpotTapped)` → `.detail` 선례와 동일한 부모 위임 구조).
  - Festival → Detail 이동도 `TabBarFeature`가 `path(.element(id:action: .festival(.festivalTapped(festival))))`를 받아 `.detail(DetailFeature.State(touristSpot: festival.touristSpot))`를 append한다. `FestivalFeature` 자체는 스택을 알지 않는다.
  - `DetailView`가 `namespace`를 요구하므로 `TabBarView`의 기존 `heroNamespace` 배선을 그대로 사용한다. Festival 셀에는 `matchedTransitionSource`를 붙이지 않아도 동작에 문제가 없다(히어로 전환 없이 표준 push).

- **[결정 9] 지역 필터 실패/해제 동작**
  - `ldongCode2` 실패 시 `regions`를 빈 배열로 두고 필터 바를 **숨긴다**(spec: 숨기거나 비활성화). `AppLogger.view` 에러 로그를 남기고 날짜 기반 검색 effect는 독립적으로 계속 진행한다 → "필터는 옵셔널" 불변 조건 충족.
  - 선택 해제는 "すべて" 칩(`Strings.Common.contentTypeAll`)과 "선택된 칩 재탭"(`selected == tapped ? nil : tapped`, `BookmarkFeature.categoryFilterTapped` 선례) 두 경로 모두 지원.
  - 지역 목록은 `onAppear` 1회만 요청하며 `hasLoadedRegions` 가드로 재진입 중복 호출을 막는다(`DetailFeature.hasStartedLoading` 선례).

- **[결정 10] 페이지네이션은 범위 밖, 시그니처만 확장 대비**
  - `numOfRows=50`, `pageNo=1` 고정(`TouristSpotEndpoint` 선례). Endpoint/Repository/UseCase 시그니처에는 `pageNo` 파라미터를 남겨 이후 무한 스크롤 도입 시 Presentation만 수정하면 되게 한다.

- **[결정 11] 에러/로깅 배치**
  - DTO 매핑 실패(`resultCode ≠ "0000"`, 좌표 파싱, 기간 파싱)는 `AppLogger.network`, Feature 레벨 실패는 `AppLogger.view` (기존 규칙과 동일).
  - `resultCode ≠ "0000"` → `TabiError.apiFailed(code:message:)` throw → Feature에서 catch 후 빈 배열 반영. 좌표 파싱 실패는 `Coordinate.zero` 대체 + 에러 로그(항목 유지). `eventstartdate` 파싱 실패는 `compactMap`으로 항목 제외 + 에러 로그. `eventenddate`는 값이 없거나 파싱 실패해도 항목을 제외하지 않고 `endDate = nil`로 매핑(결정 4). `contenttypeid`가 없으면 `.festival`로 폴백한다(상세 화면 `detailIntro2`가 축제 스키마로 파싱되도록).

- **[결정 12] Tuist / 모듈 설정**
  - 신규 파일이 다수이므로 `tuist install && tuist generate` 후 빌드한다(생성 없이 빌드하면 stale 오탐).
  - 에셋/리소스 추가가 없어 각 `Project.swift` 수정은 불필요. 신규 모듈 간 의존도 없으므로 `DependencyInformation.swift`도 수정하지 않는다.
  - 시크릿은 `Secret.tourAPIKey` 재사용 → `Secret.xcconfig` 관련 작업 없음.

- **[참고 / 범위 밖]** `HomeView.recommendedEventBanner()`가 `Strings.Home.festivalRecommendationTitle(6)`으로 월을 6에 하드코딩해 두었다. 이번 작업은 배너 **탭 동작 연결**까지만 하고 타이틀 로직은 건드리지 않는다(무관한 코드 수정 금지).

---

## 구현 순서

### Phase 0. API 실측 검증 (코드 변경 없음)
- `searchFestival2` / `ldongCode2`를 `JpnService2` 경로(결정 3, 확정됨)로 1회 호출해 실제 응답 필드명(`eventstartdate`/`eventenddate`/`mapx`/`mapy`/`firstimage`/`contenttypeid`, 시/도 목록의 코드·명칭 필드명)과 `resultCode` 값을 확인한다.
- `eventEndDate`를 생략했을 때 실제로 종료일 제한 없이 조회되는지 확인한다(결정 4).
- 확인 결과를 다음 Phase의 DTO/Endpoint 작성 근거로 고정한다.

### Phase 1. Resource / Domain Entity
- `Strings.swift`에 `Strings.Festival` 네임스페이스 추가: 화면 타이틀, 네비게이션 부제목, 기간 섹션 라벨, 지역 섹션 라벨, 결과 없음 제목/설명. 값은 일본어로 작성하고 한국어 의미를 doc 주석으로 남긴다(기존 파일 컨벤션). "すべて"는 `Strings.Common.contentTypeAll` 재사용.
- `Domain/Entity/Festival.swift` — `Equatable, Sendable, Identifiable`(`id`는 `touristSpot.id` 위임).
- `Domain/Entity/LDongRegion.swift` — `Equatable, Sendable, Identifiable`(`id`는 `code`).

### Phase 2. Domain UseCase 계층
- `FestivalRepositoryProtocol` 정의 — `fetchFestivals(startDate: Date, endDate: Date?, regionCode: String?, pageNo: Int) async throws -> [Festival]`, `fetchRegions() async throws -> [LDongRegion]`.
- `FestivalUseCaseProtocol`(+ 기본 조회 기간 상수, 예: 기본 +30일) & `FestivalUseCase`(Repository 위임).
- `TestFestivalUseCase` — `var festivals`, `var regions` 주입형 더블.
- `Dependency/Keys/FestivalUseCaseDependencyKey.swift`(`testValue`) 작성 + `DependencyValues.swift`에 `festivalUseCase` 프로퍼티 추가.

### Phase 3. Data 네트워크 계층
- `Extension/Date+.swift`, `Extension/String+.swift` — `yyyyMMdd` 변환/파싱 (캐시 formatter).
- `FestivalEndpoint` — `MobileOS`/`MobileApp`/`serviceKey`/`_type`/`arrange`/`numOfRows`/`pageNo` 공통 쿼리 + `eventStartDate`(필수) + `eventEndDate`(옵셔널, `endDate`가 `nil`이면 쿼리에서 제외) + `lDongRegnCd`(옵셔널), `ldongCode` 케이스는 시/도 목록 조회 파라미터. `TouristSpotEndpoint`의 case별 `queryItems` 구성 스타일을 따른다.
- `FestivalDTO` / `LDongRegionDTO` — `resultCode` 검증 후 `TabiError.apiFailed` throw, `Items` 빈 문자열 방어 `init(from:)` 이식, `compactMap` 매핑, 결정 11의 로깅/폴백 규칙 적용. `eventenddate`는 값이 없거나 파싱 실패해도 `endDate = nil`로 매핑하며 항목을 제외하지 않는다(로컬 사후 필터 없음).
- `Repository/Festival/FestivalRepository.swift` — `NetworkService` 주입(기본값 `NetworkService()`), 프로토콜 채택은 `TouristSpotRepository`처럼 처리.

### Phase 4. App DI 조립
- `App/Dependency/FestivalUseCaseDependencyKey.swift` — `@retroactive DependencyKey` extension으로 `liveValue` 정의.

### Phase 5. DesignSystem 셀
- `Card/TabiFestivalRow.swift` 작성 — primitive 파라미터, `TabiLabel`/`TabiPressStyle`/`TabiRadius`/`KFImage` 재사용, `TabiSpotRow`와 동일한 썸네일 크기·패딩 규격 유지.

### Phase 6. Presentation FestivalFeature
- `FestivalFeature` — `@Dependency(\.festivalUseCase)`.
  - State: `startDate: Date`(기본 오늘), `endDate: Date?`(기본 오늘+30일), `isEndDateUnlimited: Bool`(기본 `false`, "종료일 없음/무제한" 토글), `regions: [LDongRegion]`, `selectedRegionCode: String?`, `festivals: [Festival]`, `isLoading`, fileprivate `lastSelectedEndDate: Date?`(토글 OFF 복원용), `hasLoadedRegions` / `hasLoadedInitialFestivals`.
  - Action 선언 순서: `binding` → `onAppear` → `unlimitedEndDateToggled` / `regionChipTapped` / `festivalTapped` → `festivalsResult` / `regionsResult`.
  - body: `BindingReducer()` → `Reduce`. `binding(\.startDate)` / `binding(\.endDate)`에서 결정 5의 조건(`startDate != nil`) 검사 후 재조회. `unlimitedEndDateToggled`에서 토글 ON 시 `lastSelectedEndDate = state.endDate; state.endDate = nil`, OFF 시 `state.endDate = lastSelectedEndDate ?? 기본값(+30일)`로 복원 후 재조회. `regionChipTapped`에서 토글 후 재조회. `festivalTapped`는 `.none`(부모가 처리).
- `FestivalView` — `safeAreaBar(edge: .top)` 또는 상단 `TabiNavigationBar` + `ScrollView`(기간 뷰+토글 → 지역 필터 → 결과 리스트). `body` 50줄 초과 시 `Sub/`로 분리(`FestivalDateRangeView`, `FestivalRegionFilterBar`, `FestivalEmptyState`). `FestivalDateRangeView`에 "종료일 없음/무제한" 토글(`Toggle` 또는 커스텀 칩) 배치, ON일 때 `TabiRangeCalendar`의 종료일 선택 영역은 비활성화 처리. 뒤로가기는 `PlanDetailView` 툴바 패턴 그대로.
- `Festival/Model/Festival+.swift` — `periodTitle`(`endDate`가 있으면 `M/d ~ M/d`, `nil`이면 `M/d ~`). `Presentation/Extension/Date+.swift`에 `festivalPeriodDateTitle` 추가.
- (선택) `FestivalMock.swift` + `#Preview`에서 `TestFestivalUseCase` 주입.

### Phase 7. 네비게이션 배선
- `StackPath`에 `case festival(FestivalFeature)` 추가 (`State`/`Action` Equatable 자동 충족 확인).
- `HomeFeature`에 `recommendedEventBannerTapped` 추가(`return .none`), `HomeView`의 배너 `Button` 액션 연결.
- `TabBarFeature`에 두 라우팅 케이스 추가: `home(.recommendedEventBannerTapped)` → `.festival(.init())` append, `path(... .festival(.festivalTapped(festival)))` → `.detail(DetailFeature.State(touristSpot: festival.touristSpot))` append.
- `TabBarView`의 `destination` 스위치에 `.festival` → `FestivalView(store:)` 추가.

### Phase 8. 빌드 / 검증
- `tuist install && tuist generate` → `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`.
- 시뮬레이터 확인: 홈 배너 탭 → 진입 시 기본 30일 결과, 날짜 변경 재조회, "종료일 없음/무제한" 토글 ON 시 장기 행사 포함 재조회 및 OFF 시 이전 종료일로 복원, 지역 칩 선택/해제 재조회, 셀 탭 → 상세 진입(축제 소개 정보 정상 표시 = `contentType` 매핑 검증), 빠른 연속 변경 시 최신 결과만 반영, 지역 목록 실패 시 필터 숨김 + 목록 정상 조회.

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
  - [ ] 홈 `recommendedEventBanner` 탭 시 Festival 화면으로 push 이동
  - [ ] 진입 시 오늘 ~ +30일 범위로 `searchFestival2` 결과 기본 조회
  - [ ] `TabiRangeCalendar`로 범위 변경 시 목록 재조회 (`startDate` 확정 시점)
  - [ ] "종료일 없음/무제한" 토글 ON 시 `eventEndDate` 없이 조회되어 장기 행사가 결과에 포함됨
  - [ ] 시/도 필터 선택 시 해당 지역만 조회, 재탭/"すべて"로 해제
  - [ ] 결과 셀에 썸네일 + 제목 + `M/d ~ M/d`(종료일 없으면 `M/d ~`) 표시
  - [ ] 결과 셀 탭 시 기존 `DetailFeature`로 이동해 상세 정보 표시
  - [ ] `searchFestival2` / `ldongCode2` 실패 시 크래시 없이 빈 상태 + `AppLogger` 로그
- [ ] `endDate`가 있을 때는 `endDate ≥ startDate` 불변 조건 유지, `endDate`가 없어도(옵셔널) 검색 정상 동작, 지역 필터 실패에도 날짜 검색 동작
- [ ] 요청 중 조건 변경 시 이전 요청 취소되고 최신 결과만 반영 (`cancelInFlight`)
- [ ] 좌표 파싱 실패 → `Coordinate.zero` 대체 + 로그, `eventstartdate` 파싱 실패 → 항목 제외 + 로그, `eventenddate` 파싱 실패/없음 → `endDate = nil`로 처리(항목 유지)
- [ ] `DependencyInformation` 의존성 방향 위반 없음 (DesignSystem은 Domain 미참조, Domain은 Data 미참조, `liveValue`는 App에만)
- [ ] 신규 문자열은 전부 `Resource/Strings`에 정의, 신규 UI는 DesignSystem 확인 후 신설
- [ ] `tuist generate` 후 빌드 성공

---

## 탐색 중 확인한 사실 (plan 작성 근거)

- `TouristSpotEndpoint`의 실제 서비스 경로는 `/B551011/JpnService2/...`이며, `.claude/CLAUDE.md`에 적힌 `EngService2`와 다르다 — Phase 0에서 이 서비스명 기준으로 검증해야 한다.
- `TabiRangeCalendar.selectDate()`는 첫 탭에서 `endDate`를 `nil`로 리셋한다. `endDate`가 옵셔널 파라미터로 확정되어(결정 4) 재조회 트리거는 `startDate != nil` 조건만으로 충분하다(결정 5).
- `DetailFeature.State`는 `TouristSpot`만 받으며 `.festival`용 `TouristSpotIntro.empty(for:)` 분기가 이미 존재한다 → `contentType`을 `.festival`로 정확히 채우면 상세 화면 수정이 전혀 필요 없다.
- `HomeView.recommendedEventBanner()`의 `Button` 액션은 현재 빈 클로저이고, `HomeFeature`에 대응 액션이 없다 → 액션 신설이 필요하다.
- DesignSystem 모듈 의존은 `[.core, .resource]` + `[.naverMap, .kingfisher]`로, `Domain` 타입을 받을 수 없다 → 신규 셀은 primitive 파라미터여야 한다.

### Critical Files for Implementation
- /Users/yslee/Desktop/Project/TabiKori/Projects/Data/Sources/Network/EndPoint/TouristSpotEndpoint.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Data/Sources/DTO/TouristSpot/TouristSpotDTO.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Tabbar/TabBarFeature.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/Presentation/Sources/Navigation/StackPath.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/DesignSystem/Sources/Calendar/TabiRangeCalendar.swift
