# Plan: map_spot (검색 결과 지도 마커 표시)

## 참조 Spec
- @specs/features/map_spot/spec.md

## 참조 Skill
- 신규 화면 생성이 아니므로 create-feature Skill 미적용 (기존 Map 화면 확장)

## 현재 상태 파악

### 신규
- 없음 (기존 파일 수정만으로 완결 가능). 단, 카메라 bounds-fit 로직을 별도 파일로 분리할 경우 DesignSystem에 1개 파일이 추가될 수 있으며, 이 경우에만 `tuist generate` 필요

### 재사용
- `Domain/Sources/Entity/Coordinate.swift` — 좌표 타입 그대로 사용
- `Data`의 `String.toDouble()` — `mapx`/`mapy` 문자열 → Double 변환 (기존 `TouristSpotDetailDTO`가 이미 사용 중)
- `DesignSystem/Sources/Map/TabiMapView.swift` — `markers`, `onMarkerTapped` 파라미터 그대로 사용 (플레인 마커 sync 경로 재사용)
- `DesignSystem/Sources/Map/TabiMapMarker.swift` — 마커 모델 그대로 사용 (캡션 = title)
- `TabiMapView+Coordinator.swift`의 `syncPlainMarkers` — 마커 추가/제거 diff 로직 재사용
- `TabBarFeature.swift` (68~69행) `.map(.searchResultTapped)` → `state.path.append(.detail(...))` — 상세 이동 로직 **수정 없이 그대로 재사용** (마커 탭도 동일 액션을 방출하므로 자동 연동)
- `MapFeature`의 `searchResultTapped` 리듀서 — 시트 닫힘(`mode=.map`, `isResultPaused=true`) 처리 재사용

### 수정
- `Domain/Sources/Entity/TouristSpot.swift` — `coordinate: Coordinate` 프로퍼티 + `init` 파라미터 추가
- `Data/Sources/DTO/TouristSpot/TouristSpotDTO.swift` — `TouristSpotItemDTO`에 `mapx`/`mapy` 추가, `toEntity()`에서 `Coordinate` 매핑
- `Presentation/Sources/Detail/DetailView.swift` (198행 프리뷰 mock) — `TouristSpot(...)` 생성부에 `coordinate` 인자 추가 (컴파일 유지)
- `DesignSystem/Sources/Map/TabiMapView.swift` + `TabiMapView+Coordinator.swift` — bounds-fit 카메라 이동 기능 확장 (1회성 토큰 기반)
- `Presentation/Sources/Map/MapFeature.swift` — 최초 결과 도착 시 카메라 fit 트리거 토큰 추가
- `Presentation/Sources/Map/MapView.swift` — `mapBackground()`의 `TabiMapView` 호출에 `markers`/`onMarkerTapped`/fit 토큰 전달

### 삭제
- 없음

### 생성 지점 동기화 대상 (coordinate 추가 시 컴파일 깨지는 곳 — 확인 완료)
- `Data/.../TouristSpotDTO.swift` `toEntity()` — 실제 매핑 (Phase 2)
- `Presentation/.../DetailView.swift` 프리뷰 mock (Phase 1에서 함께 수정)
- (그 외 `TouristSpot(...)` 직접 생성 지점은 위 2곳뿐 — grep으로 확인. `DetailMock`/`HomeFeature`/`TestTouristSpotUseCase`는 타입 참조/빈 배열만 사용하므로 영향 없음)

## 기술적 결정사항

- **`coordinate`를 non-optional `Coordinate`(기본값 없이 init 필수)로 추가**: 기존 `TouristSpotDetail`이 `Coordinate(latitude: mapy ?? 0, longitude: mapx ?? 0)` 패턴으로 이미 non-optional을 쓰고 있어 일관성 유지. 파싱 실패/필드 부재 시 `(0, 0)`으로 채운다. 대안(Optional Coordinate)은 Detail과의 처리 방식이 갈라져 기각.
- **좌표 없는 항목(마커 미표시) 판정은 Presentation 레이어에서 `(0,0) 제외` 필터로 처리**: 엔티티는 `(0,0)`을 담되, 마커 목록 생성 시 `latitude == 0 && longitude == 0`인 항목을 제외. sheet 리스트 표시에는 영향 없음(불변 조건 충족).
- **카메라 bounds-fit은 "1회성 토큰(fit token)" 방식으로 구현**: `updateUIView`가 매 렌더마다 호출되므로, MapFeature가 최초 결과(`searchResultsResult`, 유효 좌표 ≥1개)에서만 토큰을 증가시키고 Coordinator가 "마지막 적용 토큰"과 비교해 값이 바뀔 때만 카메라를 이동. 이로써
  - 다음 페이지 로드(`searchNextPageResultsResult`)는 토큰을 건드리지 않아 재이동 안 함
  - 사용자 수동 드래그 이후에도 토큰이 그대로라 재이동 안 함
  - 검색 취소/비움 시 결과 초기화되며 토큰도 다음 검색에서만 갱신
  - 대안(매번 markers 변화 감지 후 fit)은 무한 스크롤/드래그 시 원치 않는 재이동을 유발해 기각.
- **마커 탭 → 상세 이동은 기존 `searchResultTapped(TouristSpot)` 재사용**: 마커 `id`로 `searchResults`에서 spot을 조회해 동일 액션 방출. 매칭 실패 시 아무 동작 안 함(guard). TabBar 네비게이션 로직 수정 불필요.
- **클러스터링 미적용**: `TabiMapView.isClusteringEnabled` 기본값(false) 유지 → `syncPlainMarkers` 경로 사용.

## 구현 순서

### Phase 0. 사전 검증 (추측 금지 항목 실측)
- `searchKeyword2` / `locationBasedList2` 실제 JSON 응답에 `mapx`/`mapy` 필드가 존재하는지 확인 (네트워크 로그 또는 실제 호출로 검증). 필드명이 다르거나 부재하면 이후 Phase의 매핑 키를 실측값에 맞춰 조정
- NMapsMap의 bounds-fit 관련 API 시그니처를 Xcode/헤더에서 확인:
  - `NMGLatLngBounds` 생성 방식 (좌표 배열 → bounds)
  - `NMFCameraUpdate`의 fit/bounds 이니셜라이저 및 padding 파라미터
  - 단일 좌표(1건) 처리용 `scrollTo` + `zoomTo` 시그니처는 기존 `makeUIView`에서 이미 검증됨

### Phase 1. Domain (Entity)
- `TouristSpot`에 `public let coordinate: Coordinate` 추가, `init` 파라미터 반영
- 같은 커밋 범위에서 `DetailView.swift` 프리뷰 mock의 `TouristSpot(...)` 생성부에 `coordinate` 인자 추가 (컴파일 유지)

### Phase 2. Data (DTO 매핑)
- `TouristSpotItemDTO`에 `let mapx: String?`, `let mapy: String?` 추가
- `toEntity()`에서 `Coordinate(latitude: mapy?.toDouble() ?? 0, longitude: mapx?.toDouble() ?? 0)` 생성 후 `TouristSpot`에 전달 (`TouristSpotDetailDTO` 60~93행 패턴과 동일)
- Domain은 Data를 참조하지 않는다는 제약 준수 (매핑은 Data 내부에서만)

### Phase 3. DesignSystem (카메라 bounds-fit 확장)
- `TabiMapView`에 fit 트리거 입력 추가:
  - fit 대상 좌표는 전달된 `markers`에서 도출(별도 좌표 배열 파라미터 불필요)
  - 1회성 트리거용 `boundsFitToken: Int`(또는 `AnyHashable?`) 파라미터 추가, 기본값은 fit 미수행 값
- `Coordinator`에 `lastAppliedFitToken` 저장, `sync`/`updateUIView` 시:
  - 토큰이 이전과 다르고 유효 좌표가 1개 이상일 때만 카메라 이동 후 토큰 저장
  - 좌표 2개 이상 → `NMGLatLngBounds` 구성 후 fit 카메라 업데이트(padding 포함)
  - 좌표 1개 → 해당 좌표로 `scrollTo` + 적정 `zoomTo`
  - 좌표 0개 → 이동하지 않음(현재 카메라 유지)
- 기존 `onMapTapped`/`onMarkerTapped`/드래그 델리게이트 동작 불변
- (신규 파일 없이 기존 두 파일 수정으로 처리. 부득이 파일 분리 시 `tuist generate` 수행)

### Phase 4. Presentation (Feature)
- `MapFeature.State`에 관측 가능한 fit 토큰 프로퍼티 추가 (예: `var searchResultFitToken: Int = 0`)
- `searchResultsResult` 처리에서: 유효 좌표(≠(0,0))를 가진 결과가 1개 이상이면 토큰 증가 (0건이면 증가하지 않음 → 카메라 유지)
- `searchNextPageResultsResult`는 토큰 미변경 (무한 스크롤 시 재이동 방지)
- `resetSearchState`/`searchCancelTapped`/`searchSubmitted`(결과 초기화)로 마커 소거는 `searchResults` 초기화로 자연 처리 (별도 코드 불필요)
- `searchResultTapped` 리듀서는 기존 그대로 사용

### Phase 5. Presentation (View 연동)
- `MapView.mapBackground()`의 `TabiMapView` 호출부 수정:
  - `markers:` — `store.searchResults`를 필터(`coordinate != (0,0)`) 후 `TabiMapMarker(id: spot.id, latitude/longitude: spot.coordinate, title: spot.title)`로 매핑 (캡션 = `spot.title`, DetailMapTabView와 동일 표기)
  - `onMarkerTapped:` — 전달된 id로 `store.searchResults`에서 spot 조회, 있으면 `store.send(.searchResultTapped(spot))`, 없으면 무시
  - `boundsFitToken:` — `store.searchResultFitToken` 전달
- 매핑 헬퍼는 `MapView` 내부 `private extension`(예: `TouristSpot` → `TabiMapMarker?`)로 정리

### Phase 6. 빌드 검증
- 신규 파일을 추가한 경우 `tuist install && tuist generate`
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 성공 확인
  (CLAUDE.md는 iPhone 16 Pro를 예시로 들지만, 실제 설치 시뮬레이터는 iPhone 17 사용)

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
- [ ] `TouristSpot`에 `coordinate` 추가 후 모든 생성 지점(Data 매핑, DetailView 프리뷰) 정상 컴파일
- [ ] 키워드 검색 시 sheet 목록과 동일 항목이 지도 위 마커(가게 이름 캡션)로 표시
- [ ] 최초 결과 로드 시 카메라 자동 fit, 다음 페이지 로드/수동 드래그 후에는 재이동 안 함
- [ ] 마커 탭 → sheet 항목 탭과 동일하게 상세화면 이동
- [ ] 검색 취소/검색어 비움 시 마커 소거
- [ ] 좌표 파싱 실패/0건/1건 엣지 케이스 각각 명세대로 처리
- [ ] iPhone 17 시뮬레이터 대상 빌드 성공
