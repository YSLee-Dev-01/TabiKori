# Plan: tabbar_map (지도 탭)

## 참조 Spec
- @specs/features/tabbar_map/spec.md

## 참조 Skill
신규 화면 생성 시
- @skills/create-feature/SKILL.md

## 현재 상태 파악

### 신규
- `Projects/Presentation/Sources/Map/MapFeature.swift` — 지도 탭 전용 TCA Reducer (State/Action/body)
- `Projects/Presentation/Sources/Map/MapView.swift` — 지도 탭 루트 SwiftUI View (TabiMapView + 상단 타이틀 오버레이)

### 재사용
- `LocationUseCaseProtocol` (Domain) — `checkAuthorization` / `requestAuthorization` / `fetchCurrentCoordinate` 를 그대로 사용. 이미 `@Dependency(\.locationUseCase)` 로 등록되어 있음(Domain `DependencyValues.swift` 19~22줄, testValue/liveValue 모두 존재). **의존성 신규 등록 불필요** — `MapFeature` 에서 `@Dependency(\.locationUseCase)` 로 주입만 하면 됨
- `TabiMapView` (DesignSystem) — 화면 전체 지도. `centerLatitude`/`centerLongitude`/`zoomLevel`/`showsLocationButton` 재사용 (단, positionMode 관련 파라미터는 아래 "수정" 참고)
- `TabiNavigationBar` (DesignSystem) — 상단 타이틀 오버레이. `subtitle` + `title` 2줄 구조라 지도 단일 타이틀에는 과함 → **재사용하지 않고** `MapView` 내부에서 `TabiLabel(style: .titleL)` 을 직접 오버레이 배치(HomeView 등에서 쓰는 기존 라벨 컴포넌트 재사용). Plan 결정사항 참고
- `HomeFeature` 의 위치 권한 처리 패턴(onAppear → checkAuthorization → undetermined면 requestAuthorization, allowed면 좌표 조회, 실패 시 로깅) — 로직 흐름을 참고하여 MapFeature에 맞게 재구성
- `Coordinate` (Domain Entity) — 좌표 전달 타입
- `LocationAuthorizationStatus` (Domain Entity) — 권한 상태 enum (`allowed`/`denied`/`undetermined`)
- `AppLogger.view` (Core) — 좌표 조회 실패 로깅

### 수정
- `Projects/DesignSystem/Sources/Map/TabiMapView.swift`
  - 현재 `updateUIView` 에서 `positionMode = showsLocationButton ? .direction : .disabled` 로 하드코딩되어 있어, 위치 버튼이 켜지면 무조건 카메라 오토팔로우(`.direction`)가 됨
  - "실시간 내 위치 마커만 갱신, 카메라는 따라가지 않음(`.normal`)" 요구를 만족하려면 `.normal` 을 선택할 수 있는 파라미터 추가 필요
  - NMapsMap 타입(`NMFMyPositionMode`)을 Presentation 으로 노출하지 않기 위해, DesignSystem 소유의 파라미터로 추가 (아래 기술적 결정사항 참고)
  - 기존 유일 호출부 `DetailMapTabView` 는 `showsLocationButton` 미지정(기본 false)이라 positionMode가 `.disabled` 로 유지되므로, 새 파라미터에 **기존 동작을 보존하는 기본값**을 주면 무수정 호환
- `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
  - `State.mapState` 타입을 임시 빈 `MapState` 에서 `MapFeature.State` 로 교체
  - 임시 `public struct MapState: Equatable { public init() {} }` 선언 삭제 (존재 이유: 지도 탭 미구현 상태의 placeholder. 이번 기능으로 대체되므로 삭제)
  - `Action` 에 `case map(MapFeature.Action)` 추가
  - `body` 에 `Scope(state: \.mapState, action: \.map) { MapFeature() }` 추가 (HomeFeature Scope와 동일 패턴, body 선언 순서 규칙상 Scope들 나열 후 Reduce)
  - Reduce switch에 `case .map: return .none` 추가 (지도 탭은 상위로 위임할 액션 없음)
- `Projects/Presentation/Sources/Tabbar/TabBarView.swift`
  - 지도 탭의 `Text(AppTab.map.title)` placeholder를 `MapView(store: self.store.scope(state: \.mapState, action: \.map))` 로 교체
  - `.tabItem { Image(systemName: AppTab.map.systemImage) }` / `.tag(AppTab.map)` 은 유지 (MEMORY: tabItem에 텍스트 추가 금지)
- `Projects/Resource/Sources/Strings/Strings.swift`
  - `Strings.Tabbar.map` 값 `"地図"` → `"マップ"` 로 교체(132줄). 신규 문자열 추가 아님. `AppTab.map.title` → 교체될 placeholder 에서만 참조되므로 영향 범위 없음
  - Detail 쪽 `tabMap`/`sectionMap`/`openInMaps`/`mapComingSoon` 의 `地図` 는 별개 문자열이라 변경 대상 아님

### 삭제
- `TabBarFeature.State` 의 임시 `MapState` struct (위 수정 항목에 포함)

## 기술적 결정사항

- **LocationUseCase 재사용, 신규 UseCase 미생성**: 필요한 3개 메서드(`checkAuthorization`/`requestAuthorization`/`fetchCurrentCoordinate`)가 이미 프로토콜에 존재하고 Home에서 검증됨. 대안(지도 전용 UseCase 신설)은 중복이라 배제
- **좌표 조회 후 지도 생성(makeUIView 1회 이동) 방식**: `TabiMapView` 는 `makeUIView` 에서만 카메라를 이동하고 `updateUIView` 에서는 재이동하지 않음(현행 구조). 따라서 "최초 1회만 이동 + 이후 자동 재이동 없음"을 만족시키려면, **초기 카메라 목표 좌표가 확정된 뒤에 `TabiMapView` 를 렌더링**해야 함
  - `MapFeature.State` 에 `hasResolvedInitialCenter: Bool` (초기 좌표 확정 여부) 플래그를 두고, 확정 전에는 전체 화면 placeholder(예: 배경색 + `ProgressView`)를, 확정 후에는 `TabiMapView` 를 렌더링
  - 확정 값은 성공 시 실제 좌표, denied/실패 시 서울시청 폴백 → 어느 경우든 최종적으로 지도는 반드시 렌더링됨(불변 조건 충족). placeholder는 좌표 확정 전 짧은 순간만 노출
  - 탭 재진입 시: `TabView` 가 탭 뷰를 살려두고 `mapState` 가 `TabBarFeature.State` 에 유지되므로 `MapView`/`TabiMapView` 인스턴스가 재생성되지 않음 → `makeUIView` 재호출 없음 → 카메라 자동 재이동 없음(사용자 탐색 위치 유지). 대안(TabiMapView에 "center 변경 시 1회 이동" 로직 추가)은 DesignSystem 수정 범위를 넘고 오토팔로우와 구분이 모호해져 배제
  - `onAppear` 는 탭 재진입마다 발생하므로 `MapFeature.State.hasLoadedInitial: Bool` 로 위치 조회 흐름을 최초 1회만 실행하도록 가드
- **TabiMapView positionMode 파라미터 추가 방식**: NMapsMap 의존을 DesignSystem에 가두기 위해 `NMFMyPositionMode` 를 직접 노출하지 않고, DesignSystem 소유의 불리언 파라미터 `followsUserLocation: Bool` 를 추가(기본값 `true` 로 기존 `.direction` 동작 보존)
  - 매핑: `positionMode = showsLocationButton ? (followsUserLocation ? .direction : .normal) : .disabled`
  - `MapView` 는 `showsLocationButton: true, followsUserLocation: false` 로 호출 → 마커만 갱신(`.normal`), 카메라 팔로우 없음
  - `DetailMapTabView` 는 `showsLocationButton` 미지정(false)이라 `.disabled` 유지 → 무수정 호환
  - (대안) enum `TabiMapPositionMode { disabled/normal/direction }` 신설도 가능하나, 현재 필요 분기가 normal/direction 2개뿐이라 불리언이 더 단순. 추후 확장 시 enum으로 승격 고려
- **상단 타이틀 오버레이는 TabiLabel 직접 배치**: `TabiNavigationBar` 는 subtitle+title 2줄 전제라 지도 단일 타이틀에 부적합. 지도 레이아웃에 영향 주지 않도록 `ZStack`(또는 `overlay(alignment: .top)`)으로 지도 위에 얹고, safe area top 정렬 + 좌우 패딩(기존 TabiNavigationBar와 동일한 `.horizontal, 20`) 적용. 타이틀 문자열은 `Strings.Tabbar.map`(="マップ") 사용
- **위치 스트리밍 자체 미구현**: 실시간 내 위치 표시는 네이버맵 SDK 내장 기능(`positionMode = .normal`)에 위임. Coordinate 재조회/타이머/스트림 없음(스펙 제약)
- **관광지 마커 없음**: `TabiMapView(markers:)` 에 빈 배열 전달(기본값)

## MapFeature State / Action 설계 (코드 없이 구조만)

폴더/파일 규칙: `Presentation/Sources/Map/` 아래 `MapFeature.swift`(Reducer) + `MapView.swift`(루트 뷰). swift-style TCA 규칙(State/Action/body 순서, private 헬퍼는 하단 `private extension` 분리) 준수

### State (선언 순서: 공개 프로퍼티 → fileprivate)
- `centerLatitude: Double` — 초기값 서울시청 위도 `37.5666102`
- `centerLongitude: Double` — 초기값 서울시청 경도 `126.9783881`
- `showsUserLocation: Bool = false` — allowed일 때만 true (지도 위치 버튼 + `.normal` 표시 on/off)
- `hasResolvedInitialCenter: Bool = false` — 초기 카메라 좌표 확정 여부(렌더링 게이트)
- `locationStatus: LocationAuthorizationStatus = .undetermined` — 현재 권한 상태
- `fileprivate var hasLoadedInitial: Bool = false` — onAppear 최초 1회 가드
- 서울시청 좌표 상수는 `MapFeature` 의 `private let` 상수(예: `seoulCityHallLatitude/Longitude`)로 정의하여 폴백 시 재사용

### Action (선언 순서: 생명주기 → 사용자 인터랙션 없음 → 비동기 결과)
- `onAppear` — 탭 진입
- `requestLocationPermission` — undetermined 시 시스템 팝업 요청 트리거
- `locationPermissionResult(LocationAuthorizationStatus)` — 요청 결과 수신
- `coordinateResult(Coordinate)` — 현재 좌표 조회 성공
- `fallbackToSeoul` — denied/조회 실패 시 서울시청 폴백 (내부 결과 액션)

> Action 은 `Equatable` 채택(Coordinate/LocationAuthorizationStatus 모두 Equatable). BindableAction 불필요(바인딩 상태 없음)

### body 흐름 (Reduce)
- `onAppear`:
  - `state.hasLoadedInitial == true` 면 `.none` (재진입 시 흐름 재실행 금지)
  - `state.hasLoadedInitial = true`
  - `state.locationStatus = locationUseCase.checkAuthorization()`
  - 분기:
    - `.undetermined` → `.send(.requestLocationPermission)`
    - `.allowed` → `.run { fetchCurrentCoordinate → send(.coordinateResult) / catch → send(.fallbackToSeoul) + AppLogger.view.log(.error, ...) }` (의존성은 값 캡처 `[locationUseCase = self.locationUseCase]`)
    - `.denied` → `.send(.fallbackToSeoul)`
- `requestLocationPermission`:
  - `.run { requestAuthorization → send(.locationPermissionResult(result)) }`
- `locationPermissionResult(let status)`:
  - `state.locationStatus = status`
  - `status == .allowed` → 좌표 조회 effect(성공 `.coordinateResult` / 실패 `.fallbackToSeoul` + 에러 로깅)
  - 그 외(denied 등) → `.send(.fallbackToSeoul)`
- `coordinateResult(let coordinate)`:
  - `state.centerLatitude = coordinate.latitude`, `state.centerLongitude = coordinate.longitude`
  - `state.showsUserLocation = true`
  - `state.hasResolvedInitialCenter = true`
  - `.none`
- `fallbackToSeoul`:
  - `state.centerLatitude/Longitude = 서울시청 좌표`
  - `state.showsUserLocation = false`
  - `state.hasResolvedInitialCenter = true`
  - `.none`

> 좌표 조회 effect는 `HomeFeature` 처럼 `private extension MapFeature` 의 헬퍼 메서드(`fetchCoordinateEffect()`)로 분리해 allowed 분기 2곳(onAppear/locationPermissionResult)에서 재사용. `[weak self]` 불필요(값 타입 Reducer), 의존성 값 캡처 사용. `Task.isCancelled` 가드로 취소 로그 처리(Home 패턴 참고)

## MapView 구조 (코드 없이 구조만)
- 루트: `ZStack` — 바닥에 지도, 상단에 타이틀 오버레이
- 지도 영역:
  - `store.hasResolvedInitialCenter == false` → 전체 화면 placeholder(배경 + `ProgressView`)
  - `true` → `TabiMapView(centerLatitude:centerLongitude: showsLocationButton: store.showsUserLocation, followsUserLocation: false, onMapTapped: { _,_ in }, onMarkerTapped: { _ in })`
  - `.ignoresSafeArea()` 로 화면 전체(탭바 영역 제외) 채움 → 불변 조건 "지도 항상 전체 렌더링" 충족
- 타이틀 오버레이: `overlay(alignment: .top)` 또는 ZStack top 정렬로 `TabiLabel(title: Strings.Tabbar.map, style: .titleL, color: .tabiTextPrimary)` 배치(가독성 위해 배경 처리 필요 시 재료 검토). 좌우 패딩 20, safe area top 존중
- `.onAppear { store.send(.onAppear) }` (`@Bindable`/`StoreOf` 방식은 HomeView 패턴 준수)

## 구현 순서

### Phase 1. DesignSystem (TabiMapView positionMode 파라미터)
- `TabiMapView` 에 `followsUserLocation: Bool = true` 저장 프로퍼티 + init 파라미터 추가
- `updateUIView` 의 positionMode 계산을 `showsLocationButton ? (followsUserLocation ? .direction : .normal) : .disabled` 로 변경
- `DetailMapTabView` 무수정 컴파일 확인(기본값 보존)

### Phase 2. Resource (문자열 값 교체)
- `Strings.Tabbar.map` 값 `"地図"` → `"マップ"` 교체

### Phase 3. Presentation (MapFeature / MapView 신규)
- `Presentation/Sources/Map/MapFeature.swift` 작성 (위 State/Action/body 설계)
- `Presentation/Sources/Map/MapView.swift` 작성 (위 View 구조)

### Phase 4. Presentation (TabBar 연결)
- `TabBarFeature`: `mapState` 타입 교체, 임시 `MapState` 삭제, `case map` 추가, `Scope` 추가, Reduce `case .map: return .none` 추가
- `TabBarView`: 지도 탭 placeholder를 `MapView(store: scope)` 로 교체

### Phase 5. 빌드/검증
- 새 `.swift` 파일 추가로 인해 `tuist install && tuist generate` 실행 후 빌드 (stale 프로젝트 오탐 방지 — CLAUDE.md IMPORTANT)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- 시뮬레이터 권한 상태별(미결정/허용/거부) 동작 확인 — 카메라 최초 1회 이동, 재진입 시 재이동 없음, 폴백 시 서울시청 중심 + 위치표시 off

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
  - [ ] 지도 탭 진입 시 전체 화면 지도 + 상단 "マップ" 타이틀 오버레이
  - [ ] undetermined면 최초 진입 시 시스템 권한 팝업 자동 노출
  - [ ] allowed면 최초 1회 현재 위치로 카메라 이동 + 실시간 내 위치 마커 갱신(`.normal`)
  - [ ] denied/조회 실패면 서울시청(37.5666102, 126.9783881) 중심 + 위치표시 off + 에러 로깅
  - [ ] 최초 이동 후 사용자 이동/확대 시 자동 재이동 없음(오토팔로우 없음)
  - [ ] 탭 재진입 시 카메라 자동 재이동 없음(탐색 위치 유지)
- [ ] DesignSystem/Presentation/Resource 각 모듈 의존성 방향 규칙 준수(신규 크로스모듈 의존 없음)
- [ ] TCA 의존성은 기존 `locationUseCase`(testValue/liveValue) 재사용, 신규 등록 없음
