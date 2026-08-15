# Tasks: festival

## 참조
- spec: `.claude/specs/features/festival/spec.md`
- plan: `.claude/specs/features/festival/plan.md`

## Task 목록

### Phase 0. API 실측 검증 (코드 변경 없음)

#### [x] Task 1 — `searchFestival2` / `ldongCode2` 실제 응답 검증
**파일**: 없음 (코드 변경 없음, 검증 결과는 Phase 3 DTO 작성 근거로 사용)
- **완료 (2026-08-03 curl 검증)**: `JpnService2` 경로에서 두 API 모두 `resultCode: "0000"` 정상 응답 확인
- `searchFestival2` 응답 필드는 문서와 동일: `contentid`/`contenttypeid`/`title`/`addr1`/`addr2`/`firstimage`/`firstimage2`/`mapx`/`mapy`/`mlevel`/`eventstartdate`/`eventenddate`/`lDongRegnCd`/`lDongSignguCd` 등
- `ldongCode2`(`lDongListYn=N`, `lDongRegnCd` 미지정) → 시/도 16개 목록을 `code`/`name`/`rnum` 필드로 반환 (문서와 일치)
- **중요 발견**: `eventStartDate`/`eventEndDate`는 문서 설명과 달리 **범위 겹침(overlap) 필터**로 동작함 — `eventStartDate`(하한: `eventenddate >= eventStartDate`), `eventEndDate`(상한, 옵셔널: `eventstartdate <= eventEndDate`). 장기 행사 누락 문제는 실측상 발생하지 않으며, 로컬 후처리 필터는 불필요함이 확인됨 (plan.md 결정 4 갱신됨)

---

### Phase 1. Resource / Domain Entity

#### [x] Task 2 — `Strings.swift` (수정)
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `Strings` 네임스페이스에 `Festival` 서브 네임스페이스 신설
- 화면 타이틀, 네비게이션 부제목, 기간 섹션 라벨, 지역 섹션 라벨, 결과 없음 제목/설명 문자열 추가
- 값은 일본어로 작성하고 한국어 의미를 doc 주석으로 남김 (기존 파일 컨벤션 준수)
- "すべて"는 신규 정의하지 않고 기존 `Strings.Common.contentTypeAll` 재사용

---

#### [x] Task 3 — `Festival.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/Festival.swift`
- `Festival { touristSpot: TouristSpot, startDate: Date, endDate: Date? }` 구조 (결정 1, `Bookmark` 선례와 동일한 컴포지션 방식)
- `Equatable`, `Sendable`, `Identifiable` 채택, `id`는 `touristSpot.id`에 위임
- `endDate`는 옵셔널 (결정 4)

---

#### [x] Task 4 — `LDongRegion.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/LDongRegion.swift`
- 시/도 단위 법정동 지역 엔티티: `code: String`, `name: String`
- `Equatable`, `Sendable`, `Identifiable` 채택, `id`는 `code`
- Festival 화면 전용이 아니라 향후 승격(결정 2 대안 경로) 가능하도록 Festival에 비의존적으로 정의

---

### Phase 2. Domain UseCase 계층

#### [x] Task 5 — `FestivalRepositoryProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/FestivalRepositoryProtocol.swift`
- (선행: Task 3, 4)
- `fetchFestivals(startDate: Date, endDate: Date?, regionCode: String?, pageNo: Int) async throws -> [Festival]` 선언
- `fetchRegions() async throws -> [LDongRegion]` 선언
- 결정 2에 따라 `searchFestival2` + `ldongCode2` 둘 다 하나의 프로토콜에 담당

---

#### [x] Task 6 — `FestivalUseCaseProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/Festival/FestivalUseCaseProtocol.swift`
- (선행: Task 5)
- `FestivalRepositoryProtocol`과 동일한 시그니처의 UseCase 프로토콜 정의
- 기본 조회 기간 상수(예: 기본 +30일) — `TouristSpotSearchRadius` 선례처럼 같은 파일에 배치

---

#### [x] Task 7 — `FestivalUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/Festival/FestivalUseCase.swift`
- (선행: Task 6)
- `FestivalUseCaseProtocol` 구현, `FestivalRepositoryProtocol`에 위임하는 방식 (`extension`으로 프로토콜 채택 분리)

---

#### [x] Task 8 — `TestFestivalUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/Festival/TestFestivalUseCase.swift`
- (선행: Task 6)
- `Test` 접두사 + `FestivalUseCaseProtocol` 채택
- `var festivals: [Festival]`, `var regions: [LDongRegion]` 데이터 주입용 공개 프로퍼티
- `test-style.md` 규칙(더블 패턴) 준수

---

#### [x] Task 9 — `FestivalUseCaseDependencyKey.swift` (신규, Domain)
**파일**: `Projects/Domain/Sources/Dependency/Keys/FestivalUseCaseDependencyKey.swift`
- (선행: Task 8)
- `TestDependencyKey` 채택, `testValue`만 정의 (`TestFestivalUseCase()` 반환)
- `liveValue`는 정의하지 않음 (App 레이어 담당)

---

#### [x] Task 10 — `DependencyValues.swift` (수정)
**파일**: `Projects/Domain/Sources/Dependency/DependencyValues.swift`
- (선행: Task 9)
- `festivalUseCase` 프로퍼티 확장 추가

---

### Phase 3. Data 네트워크 계층

#### [x] Task 11 — `Extension/Date+.swift` (신규, Data)
**파일**: `Projects/Data/Sources/Extension/Date+.swift`
- (선행: Task 1)
- 요청용 `yyyyMMdd` 문자열 변환 메서드 (결정 6)
- `DateFormatter`는 매번 생성하지 않고 `static let`으로 캐시, `Locale(identifier: "en_US_POSIX")` + 한국 기준 `TimeZone` 명시

---

#### [x] Task 12 — `Extension/String+.swift` (신규, Data)
**파일**: `Projects/Data/Sources/Extension/String+.swift`
- (선행: Task 1)
- 응답 `yyyyMMdd` 문자열 → `Date` 파싱 메서드 (Data 내부용, Core의 공용 `String+`와 분리 — 결정 6)
- `eventstartdate`/`eventenddate` 파싱에 사용, 캐시된 `DateFormatter` 재사용

---

#### [x] Task 13 — `FestivalEndpoint.swift` (신규)
**파일**: `Projects/Data/Sources/Network/EndPoint/FestivalEndpoint.swift`
- (선행: Task 1, 11)
- `.searchFestival(startDate: Date, endDate: Date?, regionCode: String?, pageNo: Int)`, `.ldongCode` 2케이스
- 공통 쿼리(`MobileOS`/`MobileApp`/`serviceKey`/`_type`/`arrange`/`numOfRows`/`pageNo`) + `eventStartDate`(필수) + `eventEndDate`(옵셔널, `endDate == nil`이면 쿼리에서 제외 — 결정 4) + `lDongRegnCd`(옵셔널)
- `JpnService2` 경로 사용 (결정 3), `TouristSpotEndpoint`의 case별 `queryItems` 구성 스타일 준수
- `numOfRows=50`, `pageNo` 파라미터는 시그니처에 유지 (결정 10, 페이지네이션은 범위 밖)

---

#### [x] Task 14 — `FestivalDTO.swift` (신규)
**파일**: `Projects/Data/Sources/DTO/Festival/FestivalDTO.swift`
- (선행: Task 3, 12, 13)
- `FestivalResponseDTO` / `FestivalItemDTO` 정의
- `resultCode ≠ "0000"` 검증 후 `TabiError.apiFailed` throw
- `Items`의 응답이 빈 문자열로 오는 케이스에 대한 커스텀 `init(from:)` 방어 로직 이식 (`TouristSpotResponseDTO` 선례)
- `toEntities()` — `compactMap`으로 매핑, `eventstartdate` 파싱 실패 시 항목 제외 + `AppLogger.network` 로그, `eventenddate`는 값이 없거나 파싱 실패해도 `endDate = nil`로 매핑하고 항목은 유지 (결정 4, 11)
- 좌표(`mapx`/`mapy`) 파싱 실패 시 `Coordinate.zero` 대체 + 에러 로그 (항목 유지)
- `contenttypeid`가 없으면 `.festival`로 폴백 (결정 11)

---

#### [x] Task 15 — `LDongRegionDTO.swift` (신규)
**파일**: `Projects/Data/Sources/DTO/Festival/LDongRegionDTO.swift`
- (선행: Task 4, 13)
- `LDongRegionResponseDTO` / 아이템 DTO 정의
- `resultCode ≠ "0000"` 검증 후 `TabiError.apiFailed` throw
- `toEntities()` — 코드/명칭 매핑, 실패 시 `AppLogger.network` 로그

---

#### [x] Task 16 — `FestivalRepository.swift` (신규)
**파일**: `Projects/Data/Sources/Repository/Festival/FestivalRepository.swift`
- (선행: Task 5, 14, 15)
- `NetworkService` 주입 (기본값 `NetworkService()`), `TouristSpotRepository` 선례와 동일한 초기화 패턴
- `extension`으로 `FestivalRepositoryProtocol` 채택 분리, `fetchFestivals`/`fetchRegions` 구현

---

### Phase 4. App DI 조립

#### [x] Task 17 — `FestivalUseCaseDependencyKey.swift` (신규, App)
**파일**: `Projects/App/Sources/Dependency/FestivalUseCaseDependencyKey.swift`
- (선행: Task 9, 16)
- 같은 타입(`FestivalUseCaseProtocol` 관련 DependencyKey)에 `@retroactive DependencyKey` extension으로 `liveValue` 정의
- `FestivalUseCase(repository: FestivalRepository())` 주입

---

### Phase 5. DesignSystem 셀

#### [x] Task 18 — `TabiFestivalRow.swift` (신규)
**파일**: `Projects/DesignSystem/Sources/Card/TabiFestivalRow.swift`
- (선행: 없음, Domain 미참조이므로 독립적으로 작성 가능)
- primitive 파라미터만 받음: `thumbnailURL: URL?`, `japaneseTitle: String`, `koreanTitle: String?`, `periodTitle: String`, `onTap: () -> Void` (결정 7, DesignSystem은 Domain 참조 불가)
- `TabiLabel`/`TabiPressStyle`/`TabiRadius`/`KFImage` 재사용, `TabiSpotRow`와 동일한 썸네일 크기·패딩 규격 유지
- 썸네일 placeholder는 `Kingfisher` + `calendar` 계열 SF Symbol

---

### Phase 6. Presentation FestivalFeature

#### [x] Task 19 — `Festival/Model/Festival+.swift` (신규)
**파일**: `Projects/Presentation/Sources/Festival/Model/Festival+.swift`
- (선행: Task 3)
- `periodTitle` 파생 프로퍼티: `endDate`가 있으면 `M/d ~ M/d`, `nil`이면 `M/d ~` (결정 4, 6)
- `Presentation/Extension/Date+.swift`의 `festivalPeriodDateTitle` 사용해 `"\(start) ~ \(end)"` 조합

---

#### [x] Task 20 — `Presentation/Extension/Date+.swift` (수정)
**파일**: `Projects/Presentation/Sources/Extension/Date+.swift`
- (선행: 없음)
- 표시용 `festivalPeriodDateTitle`(`M/d` 포맷) 메서드 추가 (결정 6, 기존 파일에 추가)

---

#### [x] Task 21 — `FestivalFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/Festival/FestivalFeature.swift`
- (선행: Task 6, 10, 19)
- `@Dependency(\.festivalUseCase)` 주입
- State: `startDate: Date`(기본 오늘), `endDate: Date?`(기본 오늘+30일), `isEndDateUnlimited: Bool`(기본 `false`), `regions: [LDongRegion]`, `selectedRegionCode: String?`, `festivals: [Festival]`, `isLoading`, fileprivate `lastSelectedEndDate: Date?`, `hasLoadedRegions`/`hasLoadedInitialFestivals` (swift-style.md State 선언 순서 준수)
- Action 선언 순서: `binding` → `onAppear` → `unlimitedEndDateToggled`/`regionChipTapped`/`festivalTapped` → `festivalsResult`/`regionsResult`
- body: `BindingReducer()` → `Reduce`
  - `binding(\.startDate)`/`binding(\.endDate)`에서 `startDate != nil`일 때만 재조회 (결정 5)
  - `unlimitedEndDateToggled`: ON 시 `lastSelectedEndDate = state.endDate; state.endDate = nil`, OFF 시 `state.endDate = lastSelectedEndDate ?? 기본값(+30일)` 복원 후 재조회
  - `regionChipTapped`: 선택 토글 후 재조회 ("すべて" 칩 및 재탭 해제 지원 — 결정 9)
  - 재조회 effect는 `.cancellable(id: CancelID.festivalSearch, cancelInFlight: true)` (결정 5, `HomeFeature.categoryTapped` 선례)
  - 취소된 요청은 `Task.isCancelled` 가드로 `AppLogger.view.log(.debug, ...)`만 남기고 상태 미변경
  - `onAppear`에서 `hasLoadedRegions` 가드로 지역 목록 1회만 요청, 실패 시 `regions`를 빈 배열로 두고 `AppLogger.view` 에러 로그 (날짜 검색 effect는 독립적으로 계속 진행 — 결정 9)
  - `festivalTapped`는 `.none` (부모인 `TabBarFeature`가 라우팅 처리 — 결정 8)

---

#### [x] Task 22 — `Festival/Sub/FestivalDateRangeView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Festival/Sub/FestivalDateRangeView.swift`
- (선행: Task 21)
- 기간 요약 박스 + `TabiRangeCalendar`(재사용) 배치
- "종료일 없음/무제한" 토글(`Toggle` 또는 커스텀 칩) 배치
- 토글 ON일 때 `TabiRangeCalendar`의 종료일 선택 영역 비활성화(흐리게) 처리

---

#### [x] Task 23 — `Festival/Sub/FestivalRegionFilterBar.swift` (신규)
**파일**: `Projects/Presentation/Sources/Festival/Sub/FestivalRegionFilterBar.swift`
- (선행: Task 21)
- `TabiChip` 수평 스크롤 (`BookmarkCategoryFilterBar` 선례와 동일 구조)
- "すべて"(`Strings.Common.contentTypeAll`) 칩 포함, 선택된 칩 재탭 시 해제

---

#### [x] Task 24 — `Festival/Sub/FestivalEmptyState.swift` (신규)
**파일**: `Projects/Presentation/Sources/Festival/Sub/FestivalEmptyState.swift`
- (선행: Task 2)
- 결과 없음 상태 UI, `Strings.Festival`의 결과 없음 제목/설명 문자열 사용

---

#### [x] Task 25 — `FestivalView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Festival/FestivalView.swift`
- (선행: Task 18, 21, 22, 23, 24)
- 상단 `TabiNavigationBar`(또는 `safeAreaBar(edge: .top)`) + `ScrollView`(기간 뷰+토글 → 지역 필터 → 결과 리스트) 구조
- `body` 50줄 초과 시 Sub 뷰로 분리(이미 Task 22~24로 분리됨)
- 결과 리스트 셀은 `TabiFestivalRow` 사용, 탭 시 `.festivalTapped` 발신
- 뒤로가기는 `PlanDetailView` 툴바 패턴(`.toolbar` + `chevron.left` + `navigationBarBackButtonHidden(true)` + `.interactivePopGestureEnabled(true)`) 그대로 적용

---

#### [ ] Task 26 — `FestivalMock.swift` (신규, 선택) — 스킵 (선택 항목, 핵심 기능과 무관)
**파일**: `Projects/Presentation/Sources/Festival/FestivalMock.swift`
- (선행: Task 8, 21)
- Preview용 목 데이터, `#Preview`에서 `TestFestivalUseCase` 주입 (`DetailMock`/`PlanDetailMock` 선례)

---

### Phase 7. 네비게이션 배선

#### [x] Task 27 — `StackPath.swift` (수정)
**파일**: `Projects/Presentation/Sources/Navigation/StackPath.swift`
- (선행: Task 21)
- `case festival(FestivalFeature)` 추가, `State`/`Action` Equatable 자동 충족 확인

---

#### [x] Task 28 — `HomeFeature.swift` / `HomeView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Home/HomeFeature.swift`, `Projects/Presentation/Sources/Home/HomeView.swift`
- (선행: 없음)
- `HomeFeature`에 `recommendedEventBannerTapped` 액션 추가, `return .none` (자체 라우팅 없음 — 결정 8, `home(.nearbySpotTapped)` 선례)
- `HomeView.recommendedEventBanner()`의 빈 `Button` 액션에 `store.send(.recommendedEventBannerTapped)` 연결
- `festivalRecommendationTitle(6)` 등 기존 타이틀 로직은 건드리지 않음 (plan.md 참고/범위 밖 항목)

---

#### [x] Task 29 — `TabBarFeature.swift` / `TabBarView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`, `Projects/Presentation/Sources/Tabbar/TabBarView.swift`
- (선행: Task 17, 27, 28)
- `TabBarFeature`: `home(.recommendedEventBannerTapped)` 수신 시 `.festival(.init())` push
- `TabBarFeature`: `path(.element(id:action: .festival(.festivalTapped(festival))))` 수신 시 `.detail(DetailFeature.State(touristSpot: festival.touristSpot))` push (결정 1, 8 — 변환 코드 불필요)
- `TabBarView`의 `destination` 스위치에 `.festival` → `FestivalView(store:)` 케이스 추가, 기존 `heroNamespace` 배선 재사용

---

### Phase 8. 빌드 / 검증

#### [x] Task 30 — Tuist 재생성 및 빌드
**파일**: 없음 (설정/빌드 검증)
- `tuist install && tuist generate` 실행 (결정 12, 신규 파일 다수)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` 빌드 성공 확인

---

#### [ ] Task 31 — 시뮬레이터 동작 확인 (부분 완료, 나머지는 사용자 수동 검증 필요)
**파일**: 없음 (수동 검증)
- (선행: Task 30)
- **완료**: 시뮬레이터(iPhone 17 Pro Max)에 앱 설치·실행, 홈 화면 정상 렌더링 스크린샷 확인
- **미완료 (macOS 손쉬운 사용 권한 없어 자동 탭/스크롤 불가, 사용자가 직접 확인하기로 함)**:
  - 홈 배너 탭 → Festival 진입 시 기본 30일 결과 조회
  - 날짜 범위 변경 시 재조회 (`startDate` 확정 시점)
  - "종료일 없음/무제한" 토글 ON 시 장기 행사 포함 재조회, OFF 시 이전 종료일로 복원
  - 지역 칩 선택/해제 시 재조회
  - 셀 탭 → 상세 진입 시 축제 소개 정보 정상 표시 (`contentType` 매핑 검증)
  - 빠른 연속 조건 변경 시 최신 결과만 반영 (`cancelInFlight`)
  - 지역 목록 로딩 실패 시 필터 숨김 + 날짜 기반 목록은 정상 조회

---

## 체크리스트

### 품질 (DoD)
- [ ] `tuist generate` 후 빌드 성공
- [ ] `DependencyInformation` 의존성 방향 위반 없음 (DesignSystem은 Domain 미참조, Domain은 Data 미참조, `liveValue`는 App에만 존재)
- [ ] 신규 문자열은 전부 `Resource/Strings`에 정의, 신규 UI는 DesignSystem 확인 후 신설
- [ ] 테스트 타겟 미구성 상태 유지 (구성 시 `.claude/rules/test-style.md` 별도 적용)

### 기능 (AC)
- [ ] 홈 화면 `recommendedEventBanner` 탭 시 Festival 화면으로 push 이동한다
- [ ] Festival 화면 진입 시 오늘 ~ +30일 범위로 `searchFestival2` 결과가 기본 조회된다
- [ ] `TabiRangeCalendar`로 날짜 범위를 변경하면 목록이 재조회된다
- [ ] "종료일 없음/무제한" 토글을 켜면 종료일 제한 없이 검색되어 장기 행사가 결과에 포함된다
- [ ] 시/도 필터를 선택하면 해당 지역 행사만 필터링되어 조회된다
- [ ] 결과 셀에 썸네일, 제목, 행사 기간(`M/d ~ M/d`, 종료일 없으면 `M/d ~`)이 표시된다
- [ ] 결과 셀 탭 시 기존 `DetailFeature`로 이동해 상세 정보가 표시된다
- [ ] `searchFestival2`/`ldongCode2` 요청 실패 시 에러가 로그로 남고 화면이 크래시 없이 빈 상태를 보여준다
- [ ] `endDate`가 있을 때는 `endDate ≥ startDate` 불변 조건 유지, 지역 필터 실패에도 날짜 검색은 항상 동작한다
- [ ] 요청 중 조건 변경 시 이전 요청이 취소되고 최신 결과만 반영된다
