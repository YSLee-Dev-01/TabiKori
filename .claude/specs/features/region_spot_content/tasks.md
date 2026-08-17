# Tasks: region_spot_content

## 참조
- spec: `.claude/specs/features/region_spot_content/spec.md`
- plan: `.claude/specs/features/region_spot_content/plan.md`

---

## Task 목록

### Phase 0. API 파라미터 검증 — **완료** (2026-08-10)

> 코드 작성 없이 실호출로 값을 확인하고, 결과를 `plan.md`의 결정사항 3·5 표에 반영했다.

#### [x] Task 1 — `areaCode2` 시도 단위 `areaCode` 검증
- 결과: 서울1·인천2·대전3·대구4·광주5·부산6·울산7·세종8·경기31·강원32·충북33·충남34·경북35·경남36·전북37·전남38·제주39. plan.md 가정값과 완전히 일치.

#### [x] Task 2 — `areaCode2` 시군구 단위 `sigunguCode` 검증
- 결과: 경주(areaCode35)=2, 여수(areaCode38)=13, 강릉(areaCode32)=1, 전주(areaCode37)=12

#### [x] Task 3 — `areaBasedList2` 응답 스키마 검증
- 결과: `TouristSpotResponseDTO`와 필드 단위 호환(`contentid`/`contenttypeid`/`title`/`firstimage`/`mapx`/`mapy` 모두 존재, `dist`는 응답에 없으나 옵셔널이라 문제없음). `arrange=Q`(대표이미지 우선순)로 확정.

#### [x] Task 4 — `ldongCode2` 응답에서 `lDongRegnCd`/`lDongSignguCd` 검증
- 결과: 서울11·부산26·제주50·경북47·강원51·전북52. **전남·광주는 코드 `12`(전남광주 통합특별시)로 통합되어 있음을 발견**(areaCode 체계와 불일치).
- 추가 확인: `searchFestival2`가 `lDongSignguCd` 파라미터로 시군구 단위 정밀 필터링을 지원함을 실호출로 확인(여수=130 필터 시 1건만 정확히 반환). 이에 따라 사용자 재확인 후 결정사항 5를 "시도 전체 노출"에서 "시군구 정밀 필터링"으로 변경.
- 경주(경북47)=130, 여수(전남광주12)=130, 강릉(강원51)=150, 전주(전북52)=110

---

### Phase 1. Data 레이어

#### [x] Task 5 — `KoreanRegion+.swift` (신규)
**파일**: `Projects/Data/Sources/Extension/KoreanRegion+.swift`
- `Domain`의 `KoreanRegion`에 대해 `Data` 모듈에서 `extension`으로 API 파라미터 매핑 프로퍼티 4개 추가 (검증된 값은 plan.md 결정사항 3·5 표 참조)
  - `var areaCode: String?` — seoul=1, busan=6, jeju=39, gyeongju=35, yeosu=38, gangneung=32, jeonju=37, etc=nil
  - `var sigunguCode: String?` — gyeongju=2, yeosu=13, gangneung=1, jeonju=12, 나머지 nil
  - `var lDongRegnCd: String?` — seoul=11, busan=26, jeju=50, gyeongju=47, yeosu=12, gangneung=51, jeonju=52, etc=nil
  - `var lDongSignguCd: String?` — gyeongju=130, yeosu=130, gangneung=150, jeonju=110, 나머지 nil
- `switch`는 default 없이 전 케이스 명시 (exhaustiveness로 매핑 누락이 컴파일 타임에 드러나도록)
- 강제 언래핑(`!`) 금지

---

#### [x] Task 6 — `TouristSpotEndpoint.swift` — `areaBasedSpots` 케이스 추가
**파일**: `Projects/Data/Sources/Network/EndPoint/TouristSpotEndpoint.swift`
- `case areaBasedSpots(region: KoreanRegion, contentType: CategoryType, pageNo: Int)` 추가
- `baseURL`: 기존 케이스와 동일하게 `switch`에 합류
- `path`: `/B551011/JpnService2/areaBasedList2` (결정사항 1)
- `queryItems`: 공통 파라미터(`MobileOS`, `MobileApp`, `serviceKey`, `_type`) + `arrange=Q`(Task 3에서 확정) + `numOfRows=50` + `pageNo` + `contentTypeId`(`contentType.apiCode`) + `areaCode`(`region.areaCode`) + `sigunguCode`가 있을 때만 조건부 append(`FestivalEndpoint.searchFestival`의 `if let` 패턴 재사용)
- `region.areaCode`가 `nil`인 케이스(`.etc`)는 이 Endpoint까지 도달하지 않는다는 전제(Repository/UseCase/Feature 단에서 차단, 결정사항 4) — Endpoint 자체에서 강제 언래핑하지 않도록 옵셔널 처리 방식 결정 필요 시 Task 7에서 처리

---

#### [x] Task 7 — `TouristSpotRepository.swift` — `fetchRegionSpots` 구현
**파일**: `Projects/Data/Sources/Repository/TouristSpot/TouristSpotRepository.swift`
- `fetchRegionSpots(region: KoreanRegion, contentType: CategoryType, pageNo: Int) async throws -> [TouristSpot]` 구현
- 기존 `TouristSpotResponseDTO`를 그대로 재사용하여 디코딩(신규 DTO 제작 금지, plan.md "재사용" 근거)
- `TouristSpotEndpoint.areaBasedSpots(...)` 호출 후 `toEntities()`로 변환하여 반환
- 네트워크 실패는 기존 패턴대로 `TabiError`로 변환

---

#### [x] Task 8 — `FestivalEndpoint.swift` — `searchFestival`에 시군구 파라미터 추가
**파일**: `Projects/Data/Sources/Network/EndPoint/FestivalEndpoint.swift`
- `case searchFestival(startDate: Date, endDate: Date?, regionCode: String?, sigunguCode: String?, pageNo: Int)`로 파라미터 추가
- `queryItems`에서 기존 `regionCode`(`lDongRegnCd`)와 동일한 `if let` 조건부 append 패턴으로 `sigunguCode`를 `lDongSignguCd` 쿼리 파라미터로 추가 (결정사항 5, Phase 0 실호출 검증 결과)

---

#### [x] Task 9 — `FestivalRepository.swift` — 신규 파라미터 전달
**파일**: `Projects/Data/Sources/Repository/Festival/FestivalRepository.swift`
- `fetchFestivals(...)` 시그니처에 `sigunguCode: String?` 추가, `FestivalEndpoint.searchFestival(...)` 호출부까지 전달

---

### Phase 2. Domain 레이어

#### [x] Task 10 — `TouristSpotRepositoryProtocol.swift` — 시그니처 추가
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TouristSpotRepositoryProtocol.swift`
- `func fetchRegionSpots(region: KoreanRegion, contentType: CategoryType, pageNo: Int) async throws -> [TouristSpot]` 프로토콜 메서드 추가
- `Domain`은 `Data`를 참조하지 않으므로 파라미터는 `areaCode: String`이 아닌 `region: KoreanRegion` (결정사항 2)

---

#### [x] Task 11 — `TouristSpotUseCaseProtocol.swift` — 시그니처 추가
**파일**: `Projects/Domain/Sources/UseCase/TouristSpot/TouristSpotUseCaseProtocol.swift`
- `func fetchRegionSpots(region: KoreanRegion, contentType: CategoryType, pageNo: Int) async throws -> [TouristSpot]` 추가
- `Domain/Sources/Dependency/Keys/TouristSpotUseCaseDependencyKey.swift`, `App/Sources/Dependency/TouristSpotUseCaseDependencyKey.swift`는 프로토콜 타입만 노출하므로 **수정 불필요** (plan.md "변경 불필요" 근거)

---

#### [x] Task 12 — `TouristSpotUseCase.swift` — repository 위임 구현
**파일**: `Projects/Domain/Sources/UseCase/TouristSpot/TouristSpotUseCase.swift`
- `fetchRegionSpots(region:contentType:pageNo:)`를 `repository.fetchRegionSpots(region:contentType:pageNo:)`에 위임하는 구현 추가

---

#### [x] Task 13 — `TestTouristSpotUseCase.swift` — 테스트 더블 갱신
**파일**: `Projects/Domain/Sources/UseCase/TouristSpot/TestTouristSpotUseCase.swift`
- `public var regionSpots: [TouristSpot] = []` 데이터 주입용 프로퍼티 추가
- `fetchRegionSpots(region:contentType:pageNo:)` 구현이 `self.regionSpots`를 반환하도록 추가 (`test-style.md` 3번 규칙 — `Test` 접두사, 프로토콜 채택, 주입용 `var` 공개)

---

#### [x] Task 14 — `FestivalRepositoryProtocol.swift` / `FestivalUseCaseProtocol.swift` / `FestivalUseCase.swift` / `TestFestivalUseCase.swift` — 시군구 파라미터 전파 + `fetchRegionFestivals` 신규
**파일**:
- `Projects/Domain/Sources/RepositoryProtocol/FestivalRepositoryProtocol.swift`
- `Projects/Domain/Sources/UseCase/Festival/FestivalUseCaseProtocol.swift`
- `Projects/Domain/Sources/UseCase/Festival/FestivalUseCase.swift`
- `Projects/Domain/Sources/UseCase/Festival/TestFestivalUseCase.swift`
- `fetchFestivals(...)` 시그니처에 `sigunguCode: String?` 파라미터를 4개 파일 모두 일관되게 추가 완료
- 기존 호출부 `Projects/Presentation/Sources/Festival/FestivalFeature.swift`의 `fetchFestivals(...)`에 `sigunguCode: nil` 추가 완료
- **[구현 중 발견 — 모듈 경계 수정]** `Presentation`이 `Data`를 import할 수 없어 `lDongRegnCd`/`lDongSignguCd`를 직접 읽지 못하므로, `fetchRegionFestivals(startDate:endDate:region: KoreanRegion:pageNo:)`를 4개 파일 모두에 신규 추가(`fetchRegionSpots`와 동일 패턴). `Data`의 `FestivalRepository`가 내부에서 `region.lDongRegnCd`/`lDongSignguCd`로 변환해 기존 `fetchFestivals`에 위임하도록 구현 완료 (plan.md 결정사항 5 추가 근거 참조)

---

### Phase 3. Resource 레이어

#### [x] Task 15 — `Strings.swift` — `Strings.RegionSpot` 갱신
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- 기존 `comingSoonTitle` / `comingSoonDescription` 삭제 (다른 참조 없는지 `grep` 확인 후 진행 — plan.md "삭제" 근거: 실제 콘텐츠로 대체되어 역할 종료)
- 아래 문자열을 `Strings.RegionSpot`에 신규 추가 (모두 일본어, 기존 톤 유지)
  - 관광지 섹션 제목
  - 축제 섹션 제목
  - 관광지 빈 상태 제목·설명
  - 축제 빈 상태 설명
  - 에러 상태 제목·설명
  - 재시도 버튼 라벨
- "전체" 등 이미 존재하는 문자열은 `Strings.Common`(예: `contentTypeAll`) 재사용 여부를 먼저 확인 후 없을 때만 신규 추가

---

### Phase 4. Presentation — Feature

#### [x] Task 16 — `RegionSpotFeature.swift` — State/Action/Effect 확장
**파일**: `Projects/Presentation/Sources/RegionSpot/RegionSpotFeature.swift`
- `@Dependency(\.touristSpotUseCase)`, `@Dependency(\.festivalUseCase)` 추가
- `RegionSpotLoadState` 열거형 정의(로딩/성공/빈/에러 4상태 구분, 관광지·축제 섹션이 각각 독립 상태를 가짐 — 결정사항 7)
- State (선언 순서: 공개 → fileprivate → @Presents)
  - `let region: KoreanRegion` (기존 유지)
  - `var selectedCategory: CategoryType = .sightseeing`
  - `var spots: [TouristSpot] = []`, `var spotLoadState: RegionSpotLoadState = .idle`
  - `var festivals: [Festival] = []`, `var festivalLoadState: RegionSpotLoadState = .idle`
  - `fileprivate var hasLoadedInitialContent: Bool = false` (`FestivalFeature.hasLoadedInitialFestivals` 선례, `onAppear` 재진입 시 중복 호출 방지)
- Action (선언 순서: 생명주기 → 인터랙션 → 비동기 결과)
  - `onAppear`, `categoryTabTapped(CategoryType)`, `retryButtonTapped`, `spotTapped(TouristSpot)`, `festivalTapped(Festival)`
  - `spotsResult(CategoryType, [TouristSpot])`, `spotsFailed(CategoryType)`, `festivalsResult([Festival])`, `festivalsFailed`
- `region.areaCode`가 `nil`(`.etc`)인 경우 `onAppear`에서 API 호출 없이 관광지 섹션을 빈 상태로 종료 (결정사항 4) — 단, `areaCode`는 Data 레이어 소속이므로 Presentation은 UseCase 반환값(빈 배열/에러)으로만 분기하거나, UseCase 시그니처가 `region: KoreanRegion`을 그대로 받으므로 이 판단은 Domain/Data 내부에서 처리되고 Presentation은 결과만 받는 구조 유지
- 축제 조회 시 `region`의 `lDongRegnCd`/`lDongSignguCd`를 그대로 UseCase에 전달(시군구 정밀 필터링, 결정사항 5)
- `private enum CancelID { case regionSpots, regionFestivals }` (파일 하단 배치, `FestivalFeature` 선례)
- `private extension RegionSpotFeature`에 `fetchSpotsEffect(state:)` / `fetchFestivalsEffect(state:)` 분리
- Effect는 `.run { [touristSpotUseCase = self.touristSpotUseCase] send in ... }` 형태로 의존성 값 캡처 (`swift-style.md` TCA `weak self` 예외 규칙)
- `.cancellable(id: CancelID.regionSpots, cancelInFlight: true)` 적용 — 카테고리 탭 전환 시 이전 요청 취소 (불변 조건, 결정사항 6-1)
- `spotsResult(CategoryType, ...)`에 요청 당시 카테고리를 동봉, reducer에서 `state.selectedCategory != category`면 무시 (결정사항 6-2, 취소 신호 지연 대비 이중 방어)
- 에러 처리: `Task.isCancelled`는 `AppLogger.view.log(.debug, ...)`, 그 외 실패는 `AppLogger.view.log(.error, ...)` (`FestivalFeature` 선례, `swift-style.md` 9번 규칙)
- 축제 조회 기간: `startDate = 오늘`, `endDate = nil` (진행 중/예정 축제) — `FestivalSearchPeriod` 등 기존 상수 재사용 여부 확인 후 사용
- `body`: `BindingReducer()`(바인딩 사용 시) → `Reduce { ... }` 순서 유지 (`swift-style.md` 5번 규칙)

---

### Phase 5. Presentation — View / Sub

#### [x] Task 17 — `RegionSpotView.swift` — Coming Soon 제거, 실제 콘텐츠 배치
**파일**: `Projects/Presentation/Sources/RegionSpot/RegionSpotView.swift`
- `comingSoonState()` private 메서드 및 호출부 삭제
- 기존 헤더 이미지(`regionHeaderImage()`) + 지역명(`jaTitle`/`koTitle`) 표시 유지
- `ScrollView` 내부에 `헤더 → 카테고리 탭(RegionSpotCategoryTabBar) → 관광지 섹션(RegionSpotSpotSection) → 축제 섹션(RegionSpotFestivalSection)` 순서로 배치
- `body`가 50줄을 넘지 않도록 서브뷰 호출만 남기고 세부 레이아웃은 각 Sub 뷰에 위임 (`swift-style.md` 6번 규칙)

---

#### [x] Task 18 — `RegionSpotCategoryTabBar.swift` (신규)
**파일**: `Projects/Presentation/Sources/RegionSpot/Sub/RegionSpotCategoryTabBar.swift`
- `CategoryType.allItems`를 가로 스크롤 `TabiChip`으로 표시 (신규 컴포넌트 제작 금지, 기존 재사용)
- 선택 시 `store.send(.categoryTabTapped(category))` 호출
- 선택된 탭이 화면 중앙에 오도록 `ScrollViewReader` + `scrollTo(anchor: .center)` 적용 (`FestivalRegionFilterBar` 패턴 참고)

---

#### [x] Task 19 — `RegionSpotSpotSection.swift` (신규)
**파일**: `Projects/Presentation/Sources/RegionSpot/Sub/RegionSpotSpotSection.swift`
- `RegionSpotLoadState`에 따라 4가지 UI 분기
  - 로딩: `ProgressView`
  - 빈 상태: `TabiEmptyState(.fill)`
  - 에러: `TabiEmptyState` + `TabiButton`(재시도, `store.send(.retryButtonTapped)`)
  - 성공: `LazyVStack` + `TabiSpotRow`(반복)
- `TabiSpotRow`의 `distance` 파라미터는 `areaBasedList2` 응답에 거리 개념이 없으므로 `nil` 고정 전달
- 행 탭 시 `store.send(.spotTapped(spot))` 호출
- 애니메이션은 신규 정의 없이 `.tabiStandard` / `.tabiFast` 재사용

---

#### [x] Task 20 — `RegionSpotFestivalSection.swift` (신규)
**파일**: `Projects/Presentation/Sources/RegionSpot/Sub/RegionSpotFestivalSection.swift`
- `RegionSpotLoadState`에 따라 로딩/에러/성공 UI 분기, `TabiFestivalRow` 재사용
- 결과 없음(빈 상태)은 섹션 전체를 숨기지 않고 `TabiEmptyState(.card)`로 인라인 표시 (spec: "데이터 없음 시 빈 상태 UI 표시")
- 행 탭 시 `store.send(.festivalTapped(festival))` 호출

---

### Phase 6. 라우팅

#### [x] Task 21 — `TabBarFeature.swift` — RegionSpot 하위 액션 라우팅
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- `case .path(.element(id: _, action: .region(.spotTapped(let spot)))):` → `state.path.append(.detail(DetailFeature.State(touristSpot: spot)))`
- `case .path(.element(id: _, action: .region(.festivalTapped(let festival)))):` → `state.path.append(.detail(DetailFeature.State(touristSpot: festival.touristSpot)))` (기존 `.festival(.festivalTapped(...))` 처리부와 동일 패턴, 135~136번 라인 선례)
- 홈 → RegionSpot push 로직(`case .home(.regionCardTapped(let region)):`)은 기존 그대로 유지, 수정하지 않음

---

### Phase 7. 프로젝트 생성 및 빌드

#### [x] Task 22 — `tuist generate` 및 빌드 검증
**대상**: 프로젝트 전체 (Tuist 재생성 + 빌드)
- 신규 `.swift` 파일 4개(Task 5, 18, 19, 20) 추가 후 `tuist install && tuist generate` 실행 (stale 프로젝트 오탐 방지, `CLAUDE.md` 주의사항)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 로 빌드 성공 확인 (`iPhone 16 Pro` 미설치 — 메모리 근거)
- 빌드 경고/에러 없음을 확인하고, 있다면 Task별로 원인 파일을 특정하여 수정

---

## 체크리스트

### 품질 (DoD)
- [x] Phase 0 검증 결과가 plan.md에 반영되고 추측값 없이 Phase 1이 진행됨
- [ ] 모듈 의존성 방향 준수 — `Presentation`이 `Data`를 import하지 않음, `areaCode`/`sigunguCode`/`lDongRegnCd`/`lDongSignguCd`가 `Data` 레이어 밖으로 노출되지 않음
- [ ] `KoreanRegion` → `areaCode`/`sigunguCode`/`lDongRegnCd`/`lDongSignguCd` 매핑이 `switch` 전 케이스 열거이며 강제 언래핑(`!`) 없음
- [ ] 카테고리 탭 연타 시 이전 응답이 현재 선택을 덮어쓰지 않음 (`.cancellable` + 결과 카테고리 대조 이중 방어)
- [ ] 관광지/축제 섹션 각각 로딩·성공·빈·에러 4상태가 UI에서 구분됨
- [ ] 신규 DesignSystem 컴포넌트를 만들지 않고 기존 컴포넌트(`TabiChip`/`TabiSpotRow`/`TabiFestivalRow`/`TabiEmptyState`/`TabiLabel`/`TabiCard`/`TabiButton`)로만 구성됨
- [ ] 신규 문자열이 모두 `Strings.RegionSpot`/`Strings.Common`에 정의되고 뷰에 문자열 리터럴 없음
- [ ] 기존 `FestivalFeature`의 축제 목록 조회 동작이 `sigunguCode` 파라미터 추가로 인해 변경되지 않음(`nil` 전달로 회귀 없음)
- [ ] `tuist generate` 후 빌드 성공
- [ ] 테스트 타겟 미구성 상태이므로 별도 테스트 코드 작성은 범위 밖 (`test-style.md` 규칙은 추후 테스트 타겟 구성 시 적용)

### 기능 (AC) — spec.md 기준
- [ ] 홈 화면에서 지역 카드 탭 시 RegionSpot 화면에 해당 지역의 관광지 리스트가 표시된다
- [ ] 카테고리 탭 전환 시 선택한 카테고리에 맞는 관광지 리스트로 갱신된다
- [ ] 해당 지역에서 진행 중인 축제가 있을 경우 축제 섹션에 노출된다
- [ ] API 호출 실패 시 에러 상태가 표시되고 재시도가 가능하다
- [ ] 관광지/축제 데이터가 없는 지역은 빈 상태 UI로 구분 표시된다
- [ ] 모든 `KoreanRegion` 케이스가 유효한 areaCode로 매핑되어 있다 (`.etc`는 의도적으로 `nil` — 결정사항 4)
