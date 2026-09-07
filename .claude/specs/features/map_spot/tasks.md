# Tasks: map_spot

## 참조
- spec: `.claude/specs/features/map_spot/spec.md`
- plan: `.claude/specs/features/map_spot/plan.md`

## Task 목록

### Phase 0. 사전 검증 (추측 금지 항목 실측)

#### [x] Task 1 — API 응답 필드 및 NMapsMap 시그니처 실측
**파일**: 없음 (조사 전용, 코드 변경 없음)
- `searchKeyword2` 실제 API를 `curl`로 직접 호출해 확인 완료(2026-07-27, 키워드 "경복궁"): 응답 item에 `"mapx":"127.0412487847"`, `"mapy":"37.6589779599"` 형태로 필드 존재 확인. → Phase 2 매핑 키는 `mapx`/`mapy` 그대로 사용
- NMapsMap 헤더로 확인 (`NS_SWIFT_NAME` 오버라이드 없어 Clang 기본 브릿징 규칙 적용):
  - `NMGLatLngBounds.h`: `+ (instancetype)latLngBoundsWithLatLngs:(NSArray<NMGLatLng *> *)latLngs` → Swift `NMGLatLngBounds(latLngs: [NMGLatLng])`
  - `NMFCameraUpdate.h`: `+ (instancetype)cameraUpdateWithFitBounds:(NMGLatLngBounds *)bounds padding:(CGFloat)padding` → Swift `NMFCameraUpdate(fitBounds: bounds, padding: CGFloat)`
  - 단일 좌표(1건) 케이스는 기존 `makeUIView`가 이미 쓰는 `NMFCameraUpdate(scrollTo: NMGLatLng, zoomTo: Double)` 패턴 그대로 재사용 가능

---

### Phase 1. Domain (Entity)

#### [x] Task 2 — `TouristSpot.swift`
**파일**: `Projects/Domain/Sources/Entity/TouristSpot.swift`
- `public let coordinate: Coordinate` 프로퍼티 추가
- `init(id:title:thumbnailURLString:distanceMeters:contentType:)`에 `coordinate: Coordinate` 파라미터 추가 및 대입부 반영
- 기존 프로퍼티(`japaneseTitle`, `koreanTitle`, `thumbnailURL` 등) 로직은 변경하지 않음

---

#### [x] Task 3 — `DetailView.swift` (프리뷰 mock)
**파일**: `Projects/Presentation/Sources/Detail/DetailView.swift` (198행 부근)
- 프리뷰의 `TouristSpot(id:title:thumbnailURLString:distanceMeters:contentType:)` 생성부에 `coordinate:` 인자 추가하여 컴파일 유지
- 임의의 유효 좌표(예: 경복궁 실제 좌표) 또는 `Coordinate(latitude: 0, longitude: 0)` 중 프리뷰 목적에 맞는 값 사용

---

### Phase 2. Data (DTO 매핑)

#### [x] Task 4 — `TouristSpotDTO.swift`
**파일**: `Projects/Data/Sources/DTO/TouristSpot/TouristSpotDTO.swift`
- `TouristSpotItemDTO`에 `let mapx: String?`, `let mapy: String?` 필드 추가 (Task 1 실측 결과의 실제 필드명 반영)
- `private extension TouristSpotItemDTO`의 `toEntity()`에서 `TouristSpotDetailDTO.swift` 91~94행과 동일한 패턴으로 `Coordinate(latitude: self.mapy?.toDouble() ?? 0, longitude: self.mapx?.toDouble() ?? 0)` 생성
- 생성한 `coordinate`를 `TouristSpot(...)` 초기화 인자에 전달
- Domain은 Data를 참조하지 않는다는 제약 준수 (매핑 로직은 이 파일 내부에서만 수행)

---

### Phase 3. DesignSystem (카메라 bounds-fit 확장)

#### [x] Task 5 — `TabiMapView.swift`
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapView.swift`
- 1회성 카메라 fit 트리거용 파라미터 추가 (예: `boundsFitToken: Int = 0`), `init`에 반영
- fit 대상 좌표는 기존 `markers: [TabiMapMarker]`에서 도출 (별도 좌표 배열 파라미터 불필요)
- `makeCoordinator()`가 새 파라미터를 `Coordinator` 초기화에 필요한 형태로 전달하도록 수정 (Task 6과 시그니처 일치 필요)
- `updateUIView(_:context:)`에서 `context.coordinator.sync(...)` 호출 시 `boundsFitToken`(및 markers)을 함께 전달해 fit 판단을 위임
- 기존 `onMapTapped`/`onMarkerTapped`/`onMapDragged`/`showsLocationButton`/`followsUserLocation` 동작은 변경하지 않음

---

#### [x] Task 6 — `TabiMapView+Coordinator.swift`
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapView+Coordinator.swift`
- `Coordinator`에 `private var lastAppliedFitToken: Int?` 저장 프로퍼티 추가
- `sync(markers:isClusteringEnabled:on:)` 시그니처에 `boundsFitToken: Int` 파라미터 추가 (또는 별도 fit 전용 메서드 분리), 마커 diff(`syncPlainMarkers`) 로직은 그대로 유지
- fit 판단 로직 추가:
  - `boundsFitToken`이 `lastAppliedFitToken`과 다를 때만 카메라 이동 시도 후 `lastAppliedFitToken` 갱신
  - 유효 좌표(마커) 0개 → 카메라 이동하지 않음 (현재 카메라 유지)
  - 유효 좌표 1개 → 해당 좌표로 `NMFCameraUpdate(scrollTo:zoomTo:)` (기존 `makeUIView` 패턴과 동일한 방식)
  - 유효 좌표 2개 이상 → Task 1에서 확인한 `NMGLatLngBounds` 생성자로 좌표들을 감싼 뒤, bounds 기반 `NMFCameraUpdate`로 padding 포함 이동
- `mapView(_:didTapMap:point:)`, `mapView(_:cameraWillChangeByReason:animated:)`(드래그 감지) 등 기존 델리게이트 동작은 변경하지 않음
- `syncClusteredMarkers`/클러스터링 관련 코드는 이번 작업 범위 밖이므로 수정하지 않음 (spec: 클러스터링 미적용)

---

### Phase 4. Presentation (Feature)

#### [x] Task 7 — `MapFeature.swift`
**파일**: `Projects/Presentation/Sources/Map/MapFeature.swift`
- `State`에 카메라 fit 트리거용 프로퍼티 추가 (예: `var searchResultFitToken: Int = 0`)
- `searchResultsResult(let spots)` 케이스(165~169행)에서: `spots` 중 유효 좌표(`coordinate != Coordinate(latitude: 0, longitude: 0)`)를 가진 항목이 1개 이상이면 `state.searchResultFitToken += 1`, 0건이면 토큰 미변경 (카메라 유지)
- `searchNextPageResultsResult(let spots)` 케이스(171~175행)는 토큰을 건드리지 않음 (무한 스크롤 시 재이동 방지, 불변 조건)
- `resetSearchState(_:)`(232~242행)와 `searchCancelTapped`는 `state.searchResults = []`로 결과를 초기화하는 기존 로직을 그대로 사용 (마커는 `searchResults` 초기화로 자연 소거되므로 추가 코드 불필요)
- `searchResultTapped` 리듀서(102~105행)는 기존 그대로 유지 (수정 없음)

---

### Phase 5. Presentation (View 연동)

#### [x] Task 8 — `MapView.swift`
**파일**: `Projects/Presentation/Sources/Map/MapView.swift`
> 2026-07-27 기준 최신 코드로 줄 번호 재확인 완료 (이전 초안은 리팩터링 전 줄 번호 기준이었음 — `isSearchResultPresented` → `mode: MapMode` 전환, `searchResultScrollID` 추가 등으로 전체적으로 ~10줄 앞당겨짐)
- `mapBackground()`(107~127행)의 `TabiMapView(...)` 호출부(110~118행)에 아래 인자 추가:
  - `markers:` — `store.searchResults`를 매핑한 `[TabiMapMarker]` (좌표가 `(0, 0)`인 항목은 제외)
  - `onMarkerTapped:` — 기존 `{ _ in }`(116행) 대신, 전달된 `id`로 `store.searchResults`에서 `first(where: { $0.id == id })` 조회 후 있으면 `store.send(.searchResultTapped(spot))`, 없으면 아무 동작 안 함 (guard)
  - `boundsFitToken:` — `store.searchResultFitToken` 전달
- 매핑 헬퍼는 파일 내 `private extension TouristSpot`(96~102행, 기존 `formattedDistance` 옆) 또는 별도 `private extension`에 `toMapMarker() -> TabiMapMarker?` 형태로 추가
  - `TabiMapMarker(id: spot.id, latitude: spot.coordinate.latitude, longitude: spot.coordinate.longitude, title: spot.title)` (캡션은 `spot.title`, `DetailMapTabView.swift` 26~32행과 동일 표기 방식)
- 시트 표시 조건은 `.sheet(isPresented: .constant(self.store.mode == .result))`(85행)로 이미 `mode` 기반이며, 마커 탭 시 `searchResultTapped` 리듀서가 `mode = .map`으로 전환해 시트를 닫는 기존 동작(`MapFeature.swift` 102~105행)과 자연스럽게 맞물림 — 별도 처리 불필요
- 다른 `TabiMapView` 호출부(`mapBackground()` 외 다른 화면)는 이번 작업 범위 밖이므로 수정하지 않음

---

### Phase 6. 빌드 검증

#### [x] Task 9 — 빌드/생성 검증
**파일**: 없음 (검증 전용)
- 신규 `.swift` 파일 추가 없이 기존 파일 수정만 발생 → `tuist generate` 불필요
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` **BUILD SUCCEEDED** 확인 완료
- 구현 중 발견/수정한 추가 사항 (계획에는 없었으나 실측 필요했던 부분):
  - NMapsMap의 실제 Swift 브릿징 이름은 `NMFCameraUpdate(fitBounds:padding:)`가 아니라 `NMFCameraUpdate(fit:padding:)` (컴파일러가 rename 안내)
  - Swift 6 strict concurrency: `NMFMapView.moveCamera`가 `@MainActor` 격리라 `Coordinator`의 nonisolated 메서드에서 직접 호출 시 데이터 레이스 에러 발생 → `MainActor.assumeIsolated { }` 블록 내부에서 `NMFCameraUpdate` 생성과 `moveCamera` 호출을 함께 수행하도록 처리
  - `TabiMapMarker`를 액터 경계 너머로 전달하기 위해 `Sendable` 명시적 채택 추가

---

## 체크리스트

### 품질 (DoD)
- [ ] 빌드 성공 (`xcodebuild build ... -destination 'platform=iOS Simulator,name=iPhone 17'`)
- [ ] 테스트 통과 — 테스트 타겟 미구성 상태이므로 해당 없음 (`.claude/CLAUDE.md` 참조)
- [ ] `TouristSpot` 생성 지점(Task 3, 4) 모두 컴파일 확인
- [ ] 카테고리 칩, 최근검색 placeholder 등 이번 기능과 무관한 기존 코드 미수정 확인

### 기능 (AC)
- [ ] `TouristSpot`에 `coordinate`가 추가되고 모든 생성 지점이 정상 컴파일된다
- [ ] 키워드 검색 시 sheet 목록과 동일한 항목들이 지도 위에 마커(가게 이름 캡션 포함)로 표시된다
- [ ] 검색 결과가 처음 로드될 때 지도 카메라가 결과 전체가 보이도록 자동 이동/줌되며, 다음 페이지 추가 로드 시에는 재이동하지 않는다
- [ ] 지도 마커를 탭하면 sheet의 해당 항목을 탭한 것과 동일하게 상세화면으로 이동한다
- [ ] 검색 취소/검색어 비움 시 지도 위 마커가 사라진다
- [ ] 좌표 파싱 실패/검색 결과 0건/1건 엣지 케이스가 spec대로 처리된다
