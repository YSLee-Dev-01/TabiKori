# Tasks: map_category

## 참조
- spec: `.claude/specs/features/map_category/spec.md`
- plan: `.claude/specs/features/map_category/plan.md`

## Task 목록

### Phase 1. Domain — `fetchNearbySpots` 시그니처 확장 + 공유 좌표 상수

#### [x] Task 1 — `TouristSpotUseCaseProtocol.swift`
**파일**: `Projects/Domain/Sources/UseCase/TouristSpot/TouristSpotUseCaseProtocol.swift`
- `fetchNearbySpots(contentType:coordinate:radiusMeters:)`에 `pageNo: Int` 파라미터 추가 → `fetchNearbySpots(contentType:coordinate:radiusMeters:pageNo:)`

---

#### [x] Task 2 — `TouristSpotUseCase.swift`
**파일**: `Projects/Domain/Sources/UseCase/TouristSpot/TouristSpotUseCase.swift`
- `fetchNearbySpots` 시그니처를 Task 1과 동일하게 변경
- `repository.fetchNearbySpots` 호출부에 `pageNo` 그대로 위임 전달

---

#### [x] Task 3 — `TestTouristSpotUseCase.swift`
**파일**: `Projects/Domain/Sources/UseCase/TouristSpot/TestTouristSpotUseCase.swift`
- `fetchNearbySpots` 시그니처를 Task 1과 동일하게 변경 (반환값은 기존 `nearbySpots` 프로퍼티 그대로 유지)

---

#### [x] Task 4 — `TouristSpotRepositoryProtocol.swift`
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TouristSpotRepositoryProtocol.swift`
- `fetchNearbySpots(contentType:coordinate:radiusMeters:)`에 `pageNo: Int` 파라미터 추가 (Task 1과 동일 시그니처)

---

#### [x] Task 5 — `Coordinate.swift`
**파일**: `Projects/Domain/Sources/Entity/Coordinate.swift`
- 기존 `static let zero` 옆에 `public static let seoulCityHall = Coordinate(latitude: 37.5666102, longitude: 126.9783881)` 추가 (Home/Map 공유용 서울시청 기본 좌표)

---

### Phase 2. Data — `pageNo` 쿼리 반영

#### [x] Task 6 — `TouristSpotEndpoint.swift`
**파일**: `Projects/Data/Sources/Network/EndPoint/TouristSpotEndpoint.swift`
- `case nearbySpots(contentType:coordinate:radiusMeters:)` 연관값에 `pageNo: Int` 추가
- `queryItems`의 `.nearbySpots` 분기에서 하드코딩된 `URLQueryItem(name: "pageNo", value: "1")`을 `URLQueryItem(name: "pageNo", value: "\(pageNo)")`로 대체
- 구현/실행 단계에서 `locationBasedList2`가 `pageNo`에 따라 실제로 다른 결과를 반환하는지 실제 응답으로 검증 (추측 금지, spec 참고)

---

#### [x] Task 7 — `TouristSpotRepository.swift`
**파일**: `Projects/Data/Sources/Repository/TouristSpot/TouristSpotRepository.swift`
- `fetchNearbySpots` 시그니처에 `pageNo: Int` 추가
- `TouristSpotEndpoint.nearbySpots(contentType:coordinate:radiusMeters:pageNo:)` 호출부에 `pageNo` 전달

---

### Phase 3. Presentation(Map) — 카테고리 검색·다음 페이지

#### [x] Task 8 — `MapFeature.swift` — State
**파일**: `Projects/Presentation/Sources/Map/MapFeature.swift`
- `State`에 `fileprivate var activeCategory: CategoryType?`, `fileprivate var activeCategoryCoordinate: Coordinate?` 추가 (nil이면 키워드 검색 진행 중, 값이 있으면 카테고리 검색 진행 중)
- `private let categorySearchRadiusMeters = 10000` 상수 추가
- 기존 `private let seoulCityHallLatitude`/`seoulCityHallLongitude` 상수 및 `State.centerLatitude`/`centerLongitude` 기본값 초기화, `.fallbackToSeoul` 케이스를 `Coordinate.seoulCityHall` 참조로 정리(값 중복 제거)

---

#### [x] Task 9 — `MapFeature.swift` — Action
**파일**: `Projects/Presentation/Sources/Map/MapFeature.swift`
- `Action`에 `categorySelected(CategoryType, coordinate: Coordinate?)` 추가 (`coordinate == nil`이면 지도 중심 좌표 사용 — Map 칩 경로, 값이 있으면 전달 좌표 사용 — Home 경로)

---

#### [x] Task 10 — `MapFeature.swift` — Reducer 로직
**파일**: `Projects/Presentation/Sources/Map/MapFeature.swift`
- `.categorySelected(category, coordinate)` 처리 추가:
  - 키워드 검색 상태 리셋(`searchQuery = ""`, `searchPage = 1`, `hasMoreSearchResults = true`, `searchResults = []`)
  - `mode = .result`, `panelStage = .half`, `isSearchLoading = true`
  - `activeCategory = category`, `activeCategoryCoordinate = coordinate ?? Coordinate(latitude: state.centerLatitude, longitude: state.centerLongitude)`
  - `categorySearchEffect(...)` 반환 (결과는 기존 `.searchResultsResult`로 수신, bounds-fit 로직 재사용)
- `.searchNextPageTriggered` 가드/분기 수정: `activeCategory`가 있으면 카테고리 다음 페이지 경로(`categoryNextPageEffect`, 좌표는 `activeCategoryCoordinate` 사용), 없으면 기존 키워드 경로(`searchQuery.isEmpty == false` 가드 유지) — 결과는 공통으로 `.searchNextPageResultsResult` 수신
- `.searchSubmitted` 처리 시작 부분에 `activeCategory = nil`, `activeCategoryCoordinate = nil` 리셋 추가 (키워드 검색이 카테고리 상태와 섞이지 않도록)
- `resetSearchState(_:)`에 `activeCategory = nil`, `activeCategoryCoordinate = nil` 리셋 추가

---

#### [x] Task 11 — `MapFeature.swift` — Method extension
**파일**: `Projects/Presentation/Sources/Map/MapFeature.swift`
- `private extension MapFeature`에 `categorySearchEffect(category:coordinate:)` 추가: `touristSpotUseCase.fetchNearbySpots(contentType: category, coordinate: coordinate, radiusMeters: categorySearchRadiusMeters, pageNo: 1)` 호출, 성공 시 `.searchResultsResult`, 실패 시 기존 `searchEffect`와 동일한 취소/에러 로깅 패턴(`AppLogger.view.log`) 적용 후 빈 배열 방출
- `categoryNextPageEffect(category:coordinate:pageNo:)` 추가: 동일한 `fetchNearbySpots` 호출(다음 페이지), 성공 시 `.searchNextPageResultsResult`, 실패 시 `searchNextPageEffect`와 동일한 취소/에러 로깅 패턴 적용

---

### Phase 4. Presentation(Home) — 카테고리 진입 트리거

#### [x] Task 12 — `HomeFeature.swift` — Action 및 fetchNearbySpotsEffect 인자
**파일**: `Projects/Presentation/Sources/Home/HomeFeature.swift`
- `Action`에 `categoryTapped(CategoryType)`, `categoryCoordinateResolved(CategoryType, Coordinate)` 추가
- `fetchNearbySpotsEffect()` 내부 `touristSpotUseCase.fetchNearbySpots` 호출 2곳(sightseeing/food)에 `pageNo: 1` 인자 추가 (Domain 시그니처 변경에 따른 컴파일 정합)

---

#### [x] Task 13 — `HomeFeature.swift` — Reducer 로직
**파일**: `Projects/Presentation/Sources/Home/HomeFeature.swift`
- `.categoryTapped(category)` 처리 추가: 좌표 해석 이펙트 실행 — `locationUseCase.fetchCurrentCoordinate()` 성공 시 해석 좌표, 실패 시(취소 제외) `Coordinate.seoulCityHall`로 폴백하고 에러 로그 남김 → `.categoryCoordinateResolved(category, coordinate)` 방출
- `.categoryCoordinateResolved`는 Home 자체 상태 변경 없이 `.none` 반환 (TabBar가 인터셉트하여 Map으로 위임)

---

#### [x] Task 14 — `HomeView.swift` — 카테고리 버튼 액션 연결
**파일**: `Projects/Presentation/Sources/Home/HomeView.swift`
- `categoryItemButton(_:)`(538번 줄 부근)의 빈 `Button {}` 액션에 `self.store.send(.categoryTapped(item))` 연결

---

### Phase 5. Presentation(TabBar) — 인터셉트 및 위임

#### [x] Task 15 — `TabBarFeature.swift`
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- 기존 `.home(.searchBarTapped)` 케이스(65~68번 줄) 인근에 아래 두 케이스 추가:
  - `.home(.categoryTapped)`: `state.selectedTab = .map`로 즉시 Map 탭 전환, `.none` 반환 (검색은 Home의 좌표 해석 이펙트가 계속 진행)
  - `.home(.categoryCoordinateResolved(let category, let coordinate))`: `.send(.map(.categorySelected(category, coordinate: coordinate)))`로 위임
- 두 케이스 모두 기존 포괄 `case .home:` 매치보다 위에 위치해야 함 (Swift switch 순서 규칙)

---

### Phase 6. View 연결(Map)

#### [x] Task 16 — `MapView.swift` — 카테고리 칩 액션 연결
**파일**: `Projects/Presentation/Sources/Map/MapView.swift`
- `categoryChip(_:)`(409번 줄 부근)의 빈 `Button {}` 액션에 `self.store.send(.categorySelected(item, coordinate: nil))` 연결 (Map 칩 탭은 항상 지도 중심 좌표 사용)

---

### Phase 7. 빌드 검증

#### [x] Task 17 — 빌드 확인
- 신규 `.swift` 파일 없음 → `tuist generate` 불필요
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 빌드 성공 확인
- Domain/Data/Presentation 전체에서 `fetchNearbySpots` 호출부(`HomeFeature` sightseeing/food, `MapFeature` 신규 카테고리 이펙트)가 `pageNo` 인자 누락 없이 정상 컴파일되는지 확인

---

## 체크리스트

### 품질 (DoD)
- [x] 빌드 성공 (`xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`)
- [ ] 테스트 통과 (테스트 타겟 미구성 상태 — 해당 없음)

### 기능 (AC)
- [ ] `fetchNearbySpots`에 `pageNo` 파라미터가 추가되고 Domain/Data 전체 호출부가 정상 컴파일된다
- [ ] Home에서 카테고리 탭 시 Map 탭으로 전환되고, 현재 위치 기준 반경 10km 이내 해당 카테고리 검색 결과가 지도+리스트에 표시된다
- [ ] Map `.map` 모드에서 카테고리 칩 탭 시, 지도 중심 좌표 기준 반경 10km 이내 해당 카테고리 검색 결과가 표시되며 기존 키워드 검색 상태는 리셋된다
- [ ] 카테고리 검색 결과 리스트를 스크롤해 하단에 도달하면 다음 페이지가 자동으로 추가 로드된다
- [ ] 카테고리 검색 결과 도착 시 지도 카메라가 결과 전체를 포함하도록 이동/줌된다
- [ ] Home에서 위치 권한이 없어도 카테고리 탭 시 서울시청 기본 좌표 기준으로 검색이 정상 수행된다 (빈 결과로 처리되지 않음)
- [ ] 같은 카테고리를 다시 눌러도 매번 새로운 검색이 수행된다 (토글 아님)
