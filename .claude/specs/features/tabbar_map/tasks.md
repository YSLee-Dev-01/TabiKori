# Tasks: tabbar_map

## 참조
- spec: `.claude/specs/features/tabbar_map/spec.md`
- plan: `.claude/specs/features/tabbar_map/plan.md`

## Task 목록

### Phase 1. DesignSystem (TabiMapView positionMode 파라미터 추가)

#### [x] Task 1 — `TabiMapView.swift` (수정)
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapView.swift`
- `followsUserLocation: Bool = true` 저장 프로퍼티(`private let`)와 `init` 파라미터(기본값 `true`) 추가
  - 기본값 `true`를 주는 이유: 기존 `positionMode = showsLocationButton ? .direction : .disabled` 동작을 그대로 보존하기 위함(무수정 호환)
- `updateUIView(_:context:)`의 `uiView.mapView.positionMode` 계산식을 아래로 변경:
  - `self.showsLocationButton ? (self.followsUserLocation ? .direction : .normal) : .disabled`
- `NMFMyPositionMode`(NMapsMap 타입)는 계속 `TabiMapView` 내부에서만 사용하고 외부(Presentation)에는 `Bool` 파라미터로만 노출 — DesignSystem이 NMapsMap 의존을 캡슐화하는 기존 원칙 유지
- 완료 기준: `Projects/Presentation/Sources/Detail/Sub/DetailMapTabView.swift`의 기존 `TabiMapView(...)` 호출부(22번째 줄)가 `followsUserLocation`을 지정하지 않으므로 기본값 `true`가 적용되고, `showsLocationButton` 미지정(기본 `false`)이라 `positionMode`는 여전히 `.disabled` → 무수정 컴파일/동작 보존 확인

---

### Phase 2. Resource (문자열 값 교체)

#### [x] Task 2 — `Strings.swift` (수정)
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `Strings.Tabbar.map`의 값을 `"地図"` → `"マップ"`로 교체 (132번째 줄, 신규 문자열 추가 아님)
- `Detail` 관련 문자열(`tabMap`, `sectionMap`, `openInMaps`, `mapComingSoon` 등 173번째 줄 `mapComingSoon` 포함)은 이 기능과 무관하므로 수정하지 않음

---

### Phase 3. Presentation (MapFeature / MapView 신규)

#### [x] Task 3 — `MapFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/Map/MapFeature.swift`
- `Tuist install && tuist generate` 필요: 새 `.swift` 파일이므로 작성 후 프로젝트 재생성 없이 빌드하면 stale 프로젝트로 오탐 에러 발생 (CLAUDE.md IMPORTANT)
- `@Reducer public struct MapFeature: Sendable` 선언, `@Dependency(\.locationUseCase) var locationUseCase` 주입 (신규 의존성 등록 없이 기존 `Domain/Sources/Dependency/DependencyValues.swift`에 이미 등록된 것 재사용)
- 서울시청 좌표 상수를 `private let`으로 정의: `seoulCityHallLatitude = 37.5666102`, `seoulCityHallLongitude = 126.9783881`
- `@ObservableState public struct State: Equatable` (선언 순서: 공개 프로퍼티 → fileprivate)
  - `var centerLatitude: Double = 37.5666102` (초기값 서울시청 위도)
  - `var centerLongitude: Double = 126.9783881` (초기값 서울시청 경도)
  - `var showsUserLocation: Bool = false` — allowed일 때만 true (지도 위치 버튼 on/off, `.normal` 모드 표시 여부)
  - `var hasResolvedInitialCenter: Bool = false` — 초기 카메라 좌표 확정 여부(MapView 렌더링 게이트)
  - `var locationStatus: LocationAuthorizationStatus = .undetermined` — 현재 권한 상태
  - `fileprivate var hasLoadedInitial: Bool = false` — `onAppear` 최초 1회 가드(탭 재진입 시 흐름 재실행 방지)
  - `public init() {}`
- `public enum Action: Equatable` (선언 순서: 생명주기 → 비동기 결과, BindableAction 불필요 — 바인딩 상태 없음)
  - `case onAppear`
  - `case requestLocationPermission`
  - `case locationPermissionResult(LocationAuthorizationStatus)`
  - `case coordinateResult(Coordinate)`
  - `case fallbackToSeoul`
- `public var body: some Reducer<State, Action>` — `Reduce` 단일 (하위 Reducer/Scope 없음)
  - `.onAppear`:
    - `state.hasLoadedInitial == true`면 `.none` 즉시 반환 (탭 재진입 시 흐름 재실행 금지 → 카메라 자동 재이동 없음 보장)
    - `state.hasLoadedInitial = true`
    - `state.locationStatus = self.locationUseCase.checkAuthorization()`
    - 분기:
      - `.undetermined` → `.send(.requestLocationPermission)`
      - `.allowed` → `self.fetchCoordinateEffect()` 헬퍼 호출 (아래 정의)
      - `.denied` → `.send(.fallbackToSeoul)`
  - `.requestLocationPermission`:
    - `.run { [locationUseCase = self.locationUseCase] send in let result = await locationUseCase.requestAuthorization(); await send(.locationPermissionResult(result)) }`
  - `.locationPermissionResult(let status)`:
    - `state.locationStatus = status`
    - `status == .allowed` → `self.fetchCoordinateEffect()` 반환
    - 그 외(denied 등) → `.send(.fallbackToSeoul)` 반환
  - `.coordinateResult(let coordinate)`:
    - `state.centerLatitude = coordinate.latitude`
    - `state.centerLongitude = coordinate.longitude`
    - `state.showsUserLocation = true`
    - `state.hasResolvedInitialCenter = true`
    - `.none`
  - `.fallbackToSeoul`:
    - `state.centerLatitude = self.seoulCityHallLatitude`
    - `state.centerLongitude = self.seoulCityHallLongitude`
    - `state.showsUserLocation = false`
    - `state.hasResolvedInitialCenter = true`
    - `.none`
- `private extension MapFeature` (하단, HomeFeature 패턴 참고):
  - `func fetchCoordinateEffect() -> Effect<Action>` — `.onAppear`(allowed 분기)와 `.locationPermissionResult`(allowed 분기) 양쪽에서 재사용
    - `.run { [locationUseCase = self.locationUseCase] send in` 값 캡처(값 타입 Reducer이므로 `[weak self]` 불필요)
    - `do { let coordinate = try await locationUseCase.fetchCurrentCoordinate(); await send(.coordinateResult(coordinate)) }`
    - `catch { guard !Task.isCancelled else { AppLogger.view.log(.debug, "좌표 조회 취소됨"); return }; await send(.fallbackToSeoul); AppLogger.view.log(.error, "현재 좌표 조회 실패: \(error.localizedDescription)") }`

---

#### [x] Task 4 — `MapView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Map/MapView.swift`
- `Tuist install && tuist generate` 필요: 새 `.swift` 파일이므로 작성 후 프로젝트 재생성 없이 빌드하면 stale 프로젝트로 오탐 에러 발생 (CLAUDE.md IMPORTANT)
- `public struct MapView: View`, `@Bindable private var store: StoreOf<MapFeature>` (또는 HomeView와 동일한 `@State private var store` 패턴 — HomeView 실제 방식 확인 후 통일)
- `public init(store: StoreOf<MapFeature>)`
- `body`: 루트 `ZStack` — 바닥에 지도 영역, 상단에 타이틀 오버레이
  - 지도 영역:
    - `self.store.hasResolvedInitialCenter == false`이면 전체 화면 placeholder(배경색 + `ProgressView`) 렌더링
    - `true`이면 `TabiMapView(centerLatitude: self.store.centerLatitude, centerLongitude: self.store.centerLongitude, showsLocationButton: self.store.showsUserLocation, followsUserLocation: false, onMapTapped: { _, _ in }, onMarkerTapped: { _ in })`
      - `followsUserLocation: false` 고정 — 마커만 갱신(`.normal`), 카메라 오토팔로우 없음 (Task 1에서 추가한 파라미터 사용)
      - `markers` 파라미터 미지정(기본값 빈 배열) — 관광지 마커 없음(스펙 범위 외)
    - `.ignoresSafeArea()` 적용 — 화면 전체를 채움(불변 조건: 지도는 항상 화면 전체 렌더링)
  - 타이틀 오버레이: `overlay(alignment: .top)` (또는 ZStack top 정렬)로 `TabiLabel(title: Strings.Tabbar.map, style: .titleL, color: .tabiTextPrimary)` 배치
    - 좌우 패딩 20 (`TabiNavigationBar`와 동일 스타일), safe area top 존중(지도 레이아웃에는 영향 없이 오버레이만)
    - 가독성 필요 시 배경 처리 검토(plan 참고 사항, 과도한 신규 컴포넌트 제작은 지양)
  - `.onAppear { self.store.send(.onAppear) }`

---

### Phase 4. Presentation (TabBar 연결)

#### [x] Task 5 — `TabBarFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- `State.mapState` 타입을 임시 `MapState`에서 `MapFeature.State`로 교체: `var mapState: MapFeature.State = .init()` (20번째 줄)
- 임시 `public struct MapState: Equatable { public init() {} }` 선언 삭제 (26번째 줄)
  - 삭제 사유: 지도 탭 미구현 상태의 placeholder였으며, 이번 기능(`MapFeature`)으로 완전히 대체되어 더 이상 참조되지 않음
- `Action`에 `case map(MapFeature.Action)` 추가 (기존 `case home(HomeFeature.Action)` 다음 위치, 38번째 줄 부근)
- `body`에 `Scope(state: \.mapState, action: \.map) { MapFeature() }` 추가 — 기존 `Scope(state: \.homeState, action: \.home) { HomeFeature() }` 바로 다음에 위치 (body 선언 순서 규칙: Scope들 나열 후 Reduce)
- `Reduce` switch에 `case .map: return .none` 추가 — 지도 탭은 상위(`TabBarFeature`)로 위임할 액션이 없으므로 단순 무시 (`case .home:` 처리부와 유사한 위치)

---

#### [x] Task 6 — `TabBarView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarView.swift`
- 지도 탭의 `Text(AppTab.map.title)` placeholder(37번째 줄)를 아래로 교체:
  - `MapView(store: self.store.scope(state: \.mapState, action: \.map))`
- `.tabItem { Image(systemName: AppTab.map.systemImage) }` / `.tag(AppTab.map)`은 그대로 유지 (MEMORY 규칙: tabItem에 텍스트 임의 추가 금지, Image only 유지)
- `import DesignSystem` 등 `MapView`/`TabiMapView` 참조에 필요한 import가 이미 있는지 확인, 없으면 추가

---

### Phase 5. 빌드/검증

#### [x] Task 7 — Tuist 재생성 및 빌드 검증
**파일**: 없음 (빌드/검증 전용 Task)
- `tuist install && tuist generate` 실행 — Task 3, 4에서 추가한 신규 `.swift` 파일(`MapFeature.swift`, `MapView.swift`)을 프로젝트에 반영 (CLAUDE.md IMPORTANT: 새 파일 추가 후 generate 없이 빌드하면 stale 프로젝트로 오탐 에러 발생)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` 로 빌드 성공 확인
- 시뮬레이터에서 수동 확인(권한 상태별):
  - `undetermined`: 지도 탭 최초 진입 시 시스템 위치 권한 요청 팝업 자동 노출
  - `allowed`: 카메라가 사용자 현재 위치로 최초 1회 이동, 이후 이동 시 실시간 내 위치 표시(파란 점) 갱신, 카메라 자동 재이동 없음(지도를 자유롭게 이동/확대 가능)
  - `denied` 또는 좌표 조회 실패: 지도 중심이 서울시청(37.5666102, 126.9783881)으로 표시, 위치 표시 꺼짐, `AppLogger.view`에 에러 로그 확인
  - 탭을 벗어났다가 재진입 시 카메라가 자동으로 재이동하지 않음(사용자가 탐색한 위치 유지) 확인
  - 기존 `DetailMapTabView`(Detail 화면 지도 탭)가 Task 1 수정 이후에도 기존과 동일하게 동작하는지 회귀 확인(`showsLocationButton` 미지정 → `positionMode = .disabled` 유지)

---

## 체크리스트

### 품질 (DoD)
- [x] 빌드 성공 (iPhone 16 Pro 시뮬레이터가 이 머신에 없어 iPhone 17 Pro로 대체 검증 — `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`)
- [ ] 테스트 통과 (현재 테스트 타겟 미구성 — 해당 없음, `.claude/CLAUDE.md` 참고)
- [x] `tuist install && tuist generate` 실행 후 stale 프로젝트 오탐 없음
- [x] 모듈 의존성 방향 규칙 준수 (DesignSystem은 NMapsMap 캡슐화 유지, Presentation은 Domain/DesignSystem/Resource/Core만 참조, 신규 크로스모듈 의존 없음)
- [x] TCA 의존성은 기존 `@Dependency(\.locationUseCase)`(testValue/liveValue) 재사용, 신규 DependencyKey 등록 없음

### 기능 (AC)
- [ ] 지도 탭 진입 시 화면 전체를 채우는 지도가 표시되고 상단에 "マップ" 타이틀이 오버레이된다
- [ ] 위치 권한이 `undetermined`이면 최초 진입 시 시스템 권한 요청 팝업이 자동으로 노출된다
- [ ] 위치 권한이 허용되면 최초 1회 지도 카메라가 사용자의 현재 위치로 이동하고, 이후 사용자가 이동하면 실시간 내 위치 표시(파란 점)가 갱신된다
- [ ] 위치 권한이 없거나(`denied`) 좌표 조회에 실패하면 지도 중심이 서울시청(37.5666102, 126.9783881)으로 설정되고 실시간 위치 표시는 꺼져 있다
- [ ] 최초 카메라 이동 이후 사용자가 지도를 임의로 이동/확대해도 자동으로 내 위치로 다시 이동하지 않는다
- [ ] 탭을 벗어났다가 다시 돌아와도 카메라가 자동으로 재이동하지 않는다
