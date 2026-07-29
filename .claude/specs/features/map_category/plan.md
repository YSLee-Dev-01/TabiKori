# Plan: map_category

## 참조 Spec
- @specs/features/map_category/spec.md

## 참조 Skill
- 신규 화면 생성이 아니므로 create-feature Skill 미적용 (기존 Home/Map Feature에 액션·이펙트 추가)

## 현재 상태 파악

- 신규:
  - 신규 `.swift` 파일 없음 — 모든 변경은 기존 파일 편집. 따라서 `tuist generate` 불필요, 빌드만 수행
- 재사용:
  - `MapFeature.searchResultsResult` / `searchNextPageResultsResult` — bounds-fit(`searchResultFitToken`)·페이지 종료 판정 로직을 카테고리 검색에서도 그대로 재사용
  - `MapView.searchResultList()`(281~316) 무한 스크롤 UX — `searchNextPageTriggered` 트리거만 카테고리 분기 지원하면 그대로 동작
  - `.home(.searchBarTapped)` → TabBar 인터셉트 → `selectedTab = .map` 전환 패턴을 카테고리 진입에 동일 적용
  - `MapFeature.fetchCoordinateEffect` / `HomeFeature.fetchNearbySpotsEffect`의 `locationUseCase.fetchCurrentCoordinate()` 호출 패턴
  - `Coordinate.zero` 옆에 정적 상수를 추가하는 방식(서울시청 기본 좌표 공유)
- 수정:
  - Domain: `TouristSpotUseCaseProtocol` / `TouristSpotUseCase` / `TestTouristSpotUseCase` / `TouristSpotRepositoryProtocol` — `fetchNearbySpots`에 `pageNo: Int` 추가
  - Domain: `Coordinate.swift` — 서울시청 기본 좌표 정적 상수 추가
  - Data: `TouristSpotRepository` / `TouristSpotEndpoint` — `nearbySpots`에 `pageNo` 전달·쿼리화(하드코딩 `pageNo=1` 제거)
  - Presentation: `HomeFeature` / `HomeView`(538) / `MapFeature` / `MapView`(409) / `TabBarFeature`(53~76)
- 삭제:
  - 없음. `TouristSpotEndpoint.nearbySpots`의 하드코딩 `URLQueryItem(name: "pageNo", value: "1")`만 파라미터 기반으로 대체(기능 유지, 값의 출처만 변경)

## 기술적 결정사항

- **서울시청 기본 좌표 공유 방식 → Domain `Coordinate`에 정적 상수 신설**:
  현재 `MapFeature.swift:24-25`에 `private`으로만 존재해 Home에서 재사용 불가. 값 중복 정의(임시방편) 대신 `Coordinate` 엔티티에 `static let seoulCityHall = Coordinate(latitude: 37.5666102, longitude: 126.9783881)`를 추가(기존 `Coordinate.zero`와 동일 패턴)하여 Home·Map이 공유. MapFeature의 기존 `private let seoulCityHall...` 상수도 이 공유 상수를 참조하도록 정리한다.
  - 대안(기각): Home에 동일 값 재정의 → 매직넘버 중복, 근본 해결 아님

- **Home 진입 좌표 해석 위치 → HomeFeature가 단발성 이펙트로 해석 후 좌표를 실어 위임**:
  Home 탭은 "현재 위치" 기준, Map 칩 탭은 "지도 중심" 기준으로 좌표 출처가 다르다. Home은 `categoryTapped` 이펙트에서 `fetchCurrentCoordinate()`를 호출하고 실패 시 `Coordinate.seoulCityHall`로 폴백한 뒤, 해석된 좌표를 담은 결과 액션을 방출한다. Map은 `State.centerLatitude/Longitude`(기본값이 이미 서울시청)를 그대로 사용. 이렇게 하면 MapFeature의 카테고리 검색 이펙트는 "좌표를 인자로 받는" 단일 경로로 통일된다.
  - 대안(기각): MapFeature에 `useCurrentLocation` 플래그를 넘겨 Map이 현재 위치까지 해석 → spec이 좌표 폴백 책임을 Home에 배정했고, Home 컨텍스트(현재 위치)와 Map 컨텍스트(지도 중심)를 뒤섞게 됨

- **MapFeature 카테고리 검색 액션 시그니처 → `categorySelected(CategoryType, coordinate: Coordinate?)`**:
  `coordinate == nil` → 지도 중심(state) 사용(Map 칩 경로), `coordinate != nil` → 전달 좌표 사용(Home 경로). 하나의 액션·이펙트로 두 진입점을 처리.

- **키워드/카테고리 검색 구분 상태 추가**:
  기존 `searchNextPageTriggered` 가드가 `searchQuery.isEmpty == false`에 의존 → 카테고리 검색은 `searchQuery`가 리셋(빈 문자열)되므로 그대로면 다음 페이지가 막힌다. 진행 중 검색 컨텍스트를 저장할 `fileprivate` 상태를 추가한다:
  - `activeCategory: CategoryType?` — nil이면 키워드 검색, 값이 있으면 카테고리 검색
  - `activeCategoryCoordinate: Coordinate?` — 카테고리 다음 페이지 요청에 재사용할 좌표(Home은 현재 위치라 지도 중심과 다를 수 있어 반드시 별도 보관)
  - 카테고리 검색 시작 시 `searchQuery`·`searchPage`·`hasMoreSearchResults` 등 키워드 상태 리셋 + `activeCategory` 설정, 키워드 검색(`searchSubmitted`) 시작 시 `activeCategory = nil`로 리셋 → 두 검색이 섞이지 않음(불변 조건 충족)

- **카테고리 검색 반경 상수**: MapFeature에 `categorySearchRadiusMeters = 10000`(Home의 `nearbySpotRadiusMeters`와 동일 값) 추가. Home 이펙트에서도 반경 10km 사용.

- **네이밍**(swift-style 준수):
  - HomeFeature: 사용자 인터랙션 `categoryTapped(CategoryType)`, 비동기 결과 `categoryCoordinateResolved(CategoryType, Coordinate)`
  - MapFeature: `categorySelected(CategoryType, coordinate: Coordinate?)`, 결과는 기존 `searchResultsResult` / `searchNextPageResultsResult` 재사용

## 구현 순서

### Phase 1. Domain — `fetchNearbySpots` 시그니처 확장 + 공유 좌표 상수
- `TouristSpotUseCaseProtocol` / `TouristSpotRepositoryProtocol`: `fetchNearbySpots(contentType:coordinate:radiusMeters:pageNo:)`로 `pageNo: Int` 추가
- `TouristSpotUseCase`: 리포지토리로 `pageNo` 그대로 위임
- `TestTouristSpotUseCase`: 동일 시그니처로 갱신(`nearbySpots` 반환은 유지)
- `Coordinate.swift`: `static let seoulCityHall` 추가

### Phase 2. Data — `pageNo` 쿼리 반영
- `TouristSpotEndpoint.nearbySpots`: 연관값에 `pageNo: Int` 추가, `queryItems`의 하드코딩 `pageNo` "1"을 `"\(pageNo)"`로 대체
- `TouristSpotRepository.fetchNearbySpots`: `pageNo` 파라미터를 받아 엔드포인트로 전달
- (검증 유의) `locationBasedList2`가 `pageNo`에 따라 실제로 다른 페이지를 반환하는지 구현/실행 단계에서 실제 응답으로 확인 — 추측 금지

### Phase 3. Presentation(Map) — 카테고리 검색·다음 페이지
- `MapFeature.State`: `activeCategory: CategoryType?`, `activeCategoryCoordinate: Coordinate?` (`fileprivate`) 추가
- `MapFeature`: `categorySelected(CategoryType, coordinate: Coordinate?)` 액션 추가
  - 키워드 검색 상태 리셋(`searchQuery=""`, `searchPage=1`, `hasMoreSearchResults=true`, `searchResults=[]`), `mode = .result`, `panelStage = .half`, `isSearchLoading = true`
  - `activeCategory`/`activeCategoryCoordinate` 설정(coordinate ?? 지도 중심)
  - 카테고리 검색 이펙트(`fetchNearbySpots`, `pageNo: 1`) 실행 → 결과는 `searchResultsResult`로 수신(bounds-fit 재사용)
- `searchNextPageTriggered`: `activeCategory` 유무로 분기 — 카테고리면 좌표·카테고리로 `fetchNearbySpots(pageNo: searchPage)` 다음 페이지 이펙트, 아니면 기존 키워드 경로. 결과는 `searchNextPageResultsResult` 공유
- `searchSubmitted`/`resetSearchState`: `activeCategory = nil`, `activeCategoryCoordinate = nil`로 리셋 추가
- `Method` extension: `categorySearchEffect` / `categoryNextPageEffect` 추가(기존 `searchEffect`/`searchNextPageEffect` 패턴·에러 로깅 동일)
- `seoulCityHall` private 상수를 `Coordinate.seoulCityHall` 참조로 정리

### Phase 4. Presentation(Home) — 카테고리 진입 트리거
- `HomeFeature`: `categoryTapped(CategoryType)`, `categoryCoordinateResolved(CategoryType, Coordinate)` 액션 추가
  - `categoryTapped`: 현재 좌표 해석 이펙트(성공 시 해석 좌표, 실패/취소 외 오류 시 `Coordinate.seoulCityHall` 폴백, 에러 로그 남김) → `categoryCoordinateResolved` 방출
  - `categoryCoordinateResolved`: Home 자체 상태 변경 없음 → `.none`(TabBar가 인터셉트해 Map으로 위임)
- 기존 `fetchNearbySpotsEffect`의 `fetchNearbySpots` 호출 2곳(sightseeing/food)에 `pageNo: 1` 인자 추가(컴파일 정합)

### Phase 5. Presentation(TabBar) — 인터셉트 및 위임
- `.home(.categoryTapped)`: `state.selectedTab = .map`로 즉시 전환(검색은 좌표 해석 후 이어짐), `.none`(Home 이펙트가 계속 진행)
- `.home(.categoryCoordinateResolved(category, coordinate))`: `.send(.map(.categorySelected(category, coordinate: coordinate)))`로 위임
- 위치는 기존 `.home(.searchBarTapped)` 케이스 인근(53~76)

### Phase 6. View 연결
- `HomeView.categoryItemButton`(538): 빈 `Button {}` 액션에 `self.store.send(.categoryTapped(item))` 연결
- `MapView.categoryChip`(409): 빈 `Button {}` 액션에 `self.store.send(.categorySelected(item, coordinate: nil))` 연결

### Phase 7. 빌드 검증
- 신규 파일이 없으므로 `tuist generate` 불필요
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 성공 확인
  - (참고: iPhone 16 Pro 시뮬레이터 미설치 → destination은 iPhone 17 사용)

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
- [ ] `fetchNearbySpots`에 `pageNo` 추가 후 Domain/Data/Presentation 전체 호출부 정상 컴파일
- [ ] Home 카테고리 탭 → Map 탭 전환 + 현재 위치(실패 시 서울시청) 기준 반경 10km 카테고리 검색 결과가 지도+리스트 표시
- [ ] Map `.map` 모드 칩 탭 → 지도 중심 기준 검색, 기존 키워드 검색 상태 리셋(섞이지 않음)
- [ ] 카테고리 결과 리스트 하단 도달 시 다음 페이지 자동 로드(카테고리 분기 정상 동작)
- [ ] 카테고리 결과 도착 시 카메라 bounds-fit 이동/줌
- [ ] 같은 카테고리 재탭 시 매번 재검색(토글 아님)
- [ ] iPhone 17 시뮬레이터 대상 `xcodebuild build` 성공
