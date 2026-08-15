# map_category

## 무엇을 하는가
현재 HomeView와 MapView의 카테고리 버튼(관광지/음식점/숙박/축제/쇼핑/자연)을 눌러도 아무 반응이 없다. 사용자가 카테고리를 탭하면 즉시 해당 카테고리로 "검색"이 수행되어(필터가 아니라 새 검색) 지도 마커와 리스트로 결과를 확인할 수 있게 한다. Home에서 탭하면 Map 탭으로 전환되며 현재 위치 기준으로, Map에서 탭하면 현재 지도 중심 좌표 기준으로 검색한다.

## 동작 명세
- 트리거:
  - HomeView 카테고리 아이템 탭 (`categoryItemButton`, `HomeView.swift:538`)
  - MapView `.map` 모드에서 카테고리 칩 탭 (`categoryChip`, `MapView.swift:408`, `.map` 모드일 때만 노출)
- 결과:
  - Home에서 탭: Map 탭으로 전환(`selectedTab = .map`) 후 현재 위치(`fetchCurrentCoordinate`) 기준 반경 10km 이내 해당 카테고리 검색 실행. 결과는 `MapFeature.searchResults`에 채워지고 `mode`가 `.result`로 전환되어 지도 마커 + 리스트로 표시된다
  - Map에서 탭: 지도 중심 좌표(`centerLatitude`/`centerLongitude`) 기준 반경 10km 이내 해당 카테고리 검색 실행. 기존 키워드 검색 상태(`searchQuery`, `searchPage`, `hasMoreSearchResults` 등)는 초기화되고 `searchResults`를 그대로 재사용. `mode`는 `.result`로 전환
  - 결과 도착 시 지도 카메라 bounds-fit(`searchResultFitToken` 증가) — `map_spot` 기능에서 이미 구현된 로직 재사용
  - 결과 리스트 스크롤이 하단에 도달하면 다음 페이지(`pageNo + 1`)가 자동 로드된다 (키워드 검색과 동일한 무한 스크롤 UX)
- 사이드이펙트:
  - `touristSpotUseCase.fetchNearbySpots(contentType:coordinate:radiusMeters:pageNo:)` 네트워크 호출 (신규 `pageNo` 파라미터 포함)
  - Home 트리거 시 추가로 `locationUseCase.fetchCurrentCoordinate()` 호출
- 불변 조건:
  - 카테고리 검색 시작 시 기존에 진행 중이던 키워드 검색/페이지 상태는 완전히 리셋된다 (섞이지 않음)
  - 카테고리 탭은 토글(필터 해제)이 아니라 매번 새로운 검색이다 — 같은 카테고리를 다시 눌러도 동일하게 재검색을 수행한다
  - Home에서 위치 권한이 없거나 좌표 조회에 실패해도 Map 탭 전환은 정상 수행되며, 검색은 Map의 기본 표시 좌표(서울시청, `MapFeature.seoulCityHallLatitude`/`Longitude` = `37.5666102`/`126.9783881`)로 대체되어 진행된다 (빈 결과 처리 아님)

## 무엇이 잘못될 수 있는가
- 위치 권한 미허용/좌표 조회 실패 (Home 트리거) → 서울시청 기본 좌표로 대체하여 검색 진행 (에러 로그는 남기되 결과는 빈 배열로 처리하지 않음)
- Map에서 지도 중심이 아직 해석되지 않은 상태(`hasResolvedInitialCenter == false`)에서 카테고리 탭 → 별도 처리 불필요. `MapFeature.State.centerLatitude`/`centerLongitude`의 기본값 자체가 이미 서울시청 좌표(`MapFeature.swift:30-31`)이므로, 해석 전에 탭해도 결국 동일한 기본 좌표로 검색되어 위 항목과 동작이 일치한다
- 무한 스크롤 진행 중 다른 카테고리를 탭하는 상황 → 카테고리 칩은 `mode == .map`일 때만 노출되고, 무한 스크롤은 `mode == .result`(sheet 노출 상태)에서만 발생하므로 UI상 동시에 발생할 수 없다 (별도 가드 불필요). 단, 취소 후 재검색 시 이전 다음 페이지 요청이 뒤늦게 응답을 덮어쓸 가능성은 키워드 검색에도 동일하게 존재하는 기존 동작이며 이번 기능 범위에서 다루지 않는다
- `locationBasedList2` 응답이 특정 페이지에서 0건 반환 → `hasMoreSearchResults`가 false로 전환되어 무한 스크롤 종료 (키워드 검색과 동일 로직 재사용)
- `pageNo` 파라미터가 실제로 `locationBasedList2`에서 다른 결과를 반환하는지 미검증 상태 — 추측하지 않고 구현 중 실제 API 응답으로 확인 필요

## 무엇에 의존하는가
### 의존성
- `Domain/Sources/UseCase/TouristSpot/TouristSpotUseCaseProtocol.swift`, `TouristSpotUseCase.swift`, `TestTouristSpotUseCase.swift` — `fetchNearbySpots`에 `pageNo: Int` 파라미터 추가
- `Domain/Sources/RepositoryProtocol/TouristSpotRepositoryProtocol.swift` — 동일 시그니처 변경
- `Data/Sources/Repository/TouristSpot/TouristSpotRepository.swift`, `Data/Sources/Network/EndPoint/TouristSpotEndpoint.swift` — `pageNo` 쿼리 파라미터화 (현재 하드코딩된 `pageNo=1` 제거)
- `Presentation/Sources/Home/HomeFeature.swift` — `categoryTapped(CategoryType)` 액션 추가 (기존 `fetchNearbySpotsEffect`와는 별개의 단발성 검색 effect). 좌표 조회 실패 시 서울시청 기본 좌표로 폴백 필요 — 현재 이 상수(`seoulCityHallLatitude`/`Longitude`)는 `MapFeature.swift:24-25`에 `private`으로 선언되어 있어 공유 방법(상수 위치 이동 또는 동일 값 재정의) 결정 필요
- `Presentation/Sources/Home/HomeView.swift:538` — `categoryItemButton` 액션 연결
- `Presentation/Sources/Map/MapFeature.swift` — `categorySelected(CategoryType)` 액션 및 카테고리 기반 검색/다음 페이지 effect 추가 (`searchEffect`/`searchNextPageEffect`와 유사 패턴). 키워드 검색과 카테고리 검색을 구분할 상태(예: 진행 중인 검색이 키워드인지 카테고리인지) 필요 여부 확인
- `Presentation/Sources/Map/MapView.swift:408` — `categoryChip` 액션 연결
- `Presentation/Sources/Tabbar/TabBarFeature.swift:60` — `.home(.categoryTapped)` 인터셉트하여 Map 탭 전환 + `.map(.categorySelected)` 위임 (기존 `.home(.searchBarTapped)` 패턴 재사용)
- 기존 무한 스크롤/bounds-fit 로직 재사용: `MapFeature.swift:119-125(searchNextPageTriggered), 177-190(searchResultsResult), 231-245(searchNextPageEffect)`, `MapView.swift:281-315(searchResultList)`
- `DesignSystem/Sources/Map/TabiMapView.swift`, `TabiMapView+Coordinator.swift` — 구현 중 발견: "지도 중심 좌표 기준 검색"이 정확하려면 드래그 후 실제 카메라 중심을 `MapFeature.centerLatitude/centerLongitude`에 반영해야 함. `NMFMapViewCameraDelegate.mapViewCameraIdle(_:)` + `NMFMapView.cameraPosition.target`을 사용하는 `onCameraIdle` 콜백을 신규 추가해 `MapFeature.mapCenterChanged(Coordinate)` 액션으로 연결

### 제약
- Domain은 Data를 참조하지 않는다 — 실제 `pageNo` 쿼리 반영은 Data 레이어에서만 수행
- API, 라이브러리 버전, 메서드 시그니처는 추측하지 않는다 — `locationBasedList2`의 `pageNo` 동작은 구현 중 실제 응답으로 검증
- `fetchNearbySpots` 시그니처 변경은 기존 호출부(`HomeFeature.fetchNearbySpotsEffect`의 sightseeing/food 호출)에도 영향 — 모든 호출부에 `pageNo` 인자 추가 필요
- 새 `.swift` 파일 추가 시 `tuist generate` 필요
- 현재 태스크와 무관한 코드(최근 검색, 검색창, 클러스터링 등)는 수정하지 않는다

## Acceptance Criteria
- [x] `fetchNearbySpots`에 `pageNo` 파라미터가 추가되고 Domain/Data 전체 호출부가 정상 컴파일된다
- [x] Home에서 카테고리 탭 시 Map 탭으로 전환되고, 현재 위치 기준 반경 10km 이내 해당 카테고리 검색 결과가 지도+리스트에 표시된다
- [x] Map `.map` 모드에서 카테고리 칩 탭 시, 지도 중심 좌표 기준 반경 10km 이내 해당 카테고리 검색 결과가 표시되며 기존 키워드 검색 상태는 리셋된다
- [ ] 카테고리 검색 결과 리스트를 스크롤해 하단에 도달하면 다음 페이지가 자동으로 추가 로드된다 (구현 완료, 시뮬레이터 수동 확인 필요)
- [ ] 카테고리 검색 결과 도착 시 지도 카메라가 결과 전체를 포함하도록 이동/줌된다 (구현 완료, 시뮬레이터 수동 확인 필요)
- [ ] Home에서 위치 권한이 없어도 카테고리 탭 시 서울시청 기본 좌표 기준으로 검색이 정상 수행된다 (빈 결과로 처리되지 않음) (구현 완료, 시뮬레이터 수동 확인 필요)
- [x] `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 빌드 성공
