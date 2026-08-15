# Tasks: naver_map (TabiMapView 네이버맵 통합)

## 참조
- spec: `.claude/specs/features/naver_map/spec.md`
- plan: `.claude/specs/features/naver_map/plan.md`

## Task 목록

### Phase 1. Public API / 모델 (DesignSystem)

#### [x] Task 1 — `TabiMapMarker.swift` (신규)
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapMarker.swift`
- `TabiMapMarker` 구조체 정의: `id: String`, `latitude: Double`, `longitude: Double` — 모두 `public let`
- `Identifiable`, `Equatable` 채택 (SDK 타입 `NMGLatLng`/`NMFMarker` 등은 절대 노출하지 않음)
- `public init(id:latitude:longitude:)` 제공

---

#### [x] Task 2 — `TabiMapView.swift` public API 시그니처 확정
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapView.swift`
- 기존 `Color.clear`만 반환하는 스켈레톤 본체를 제거하고, `public struct TabiMapView` 저장 프로퍼티 선언
  - `centerLatitude: Double`, `centerLongitude: Double`, `zoomLevel: Double`
  - `markers: [TabiMapMarker]`
  - `isClusteringEnabled: Bool`
  - `showsLocationButton: Bool`
  - `onMapTapped: (Double, Double) -> Void`
  - `onMarkerTapped: (String) -> Void`
  - 모두 `private let`, 클로저 프로퍼티는 `@escaping`
- `public init(centerLatitude:centerLongitude:zoomLevel:markers:isClusteringEnabled:showsLocationButton:onMapTapped:onMarkerTapped:)` 작성 (spec 7번 트리거 시그니처와 일치시킬 것)
- 본체 채택(`UIViewRepresentable`)은 Task 3에서 이어서 구현 (이 Task에서는 프로퍼티/init까지만)

---

### Phase 2. UIViewRepresentable 본체 (DesignSystem)

#### [x] Task 3 — `TabiMapView.swift` — `UIViewRepresentable` 구현
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapView.swift`
- `import NMapsMap` 추가, `extension TabiMapView: UIViewRepresentable`로 프로토콜 채택 분리 (`swift-style.md` 컨벤션)
- `func makeCoordinator() -> Coordinator`: `onMapTapped`/`onMarkerTapped` 콜백을 전달해 Coordinator 생성
- `func makeUIView(context:) -> NMFNaverMapView`:
  - `NMFNaverMapView` 생성, `mapView.showLocationButton = showsLocationButton` 설정
  - `mapView.touchDelegate = context.coordinator` 연결
  - 초기 카메라: `NMFCameraUpdate(scrollTo: NMGLatLng(lat:centerLatitude, lng:centerLongitude))` + `zoomTo: zoomLevel`을 애니메이션 없이 1회 적용, 적용 후 `context.coordinator.isInitialCameraApplied = true`
  - `showsLocationButton == true`면 `mapView.positionMode = .direction`
  - `isClusteringEnabled` 값에 따라 Coordinator에 비클러스터/클러스터 경로 부착 위임 (Phase 3/4에서 구현할 메서드 호출)
  - 초기 `markers` 반영을 Coordinator에 위임
- `func updateUIView(_:context:)`:
  - 카메라는 절대 재설정하지 않음 (`isInitialCameraApplied` 플래그로 보호된 로직은 Coordinator 쪽에 위치)
  - `showLocationButton`/`positionMode` 등 토글 값이 바뀐 경우에만 반영
  - Coordinator를 통해 `markers` add/remove diff 동기화 호출

---

### Phase 3. Coordinator & 델리게이트 (DesignSystem)

#### [x] Task 4 — `TabiMapView+Coordinator.swift` (신규)
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapView+Coordinator.swift`
- `extension TabiMapView { final class Coordinator: NSObject { ... } }` 형태로 정의
  - 저장 프로퍼티: `onMapTapped: (Double, Double) -> Void`, `onMarkerTapped: (String) -> Void`, `markerCache: [String: NMFMarker] = [:]`, `isInitialCameraApplied: Bool = false`, 클러스터러 참조(Phase 4에서 채움)
  - `init(onMapTapped:onMarkerTapped:)` 제공
- `// MARK: - NMFMapViewTouchDelegate` extension 분리:
  - `func mapView(_:didTapMap:point:)`: `NMGLatLng` → `Double` lat/lng로 변환해 `onMapTapped(lat, lng)` 호출
- 마커 동기화 메서드(비클러스터 경로, `internal`/`private` 접근 제어 최소화 원칙 적용):
  - 신규 `markers` 배열의 id 집합과 `markerCache` 키 집합을 비교해 diff 계산
  - 추가분: `NMFMarker` 생성 → `position` 설정 → `touchHandler`에서 `onMarkerTapped(id)` 호출 후 `true` 반환(지도 탭으로 전파 차단) → `mapView` 대입 → `markerCache`에 저장
  - 삭제분: `mapView = nil` 처리 후 `markerCache`에서 제거
  - 동일 id 중복 시 나중 항목이 이전 항목을 덮어쓰는 동작은 spec에 명시된 대로 별도 방어 로직 없이 딕셔너리 특성에 맡김
- 클로저/델리게이트 콜백에서 `self` 키워드로 내부 프로퍼티 명시적 참조 (`swift-style.md` 네이밍 규칙)

---

### Phase 4. 클러스터링 (DesignSystem)

#### [x] Task 5 — `TabiClusteringKey.swift` (신규)
**파일**: `Projects/DesignSystem/Sources/Map/TabiClusteringKey.swift`
- `final class TabiClusteringKey: NSObject, NSCopying, NMCClusteringKey` 정의 (internal 접근 제어, 모듈 외부 미노출)
  - 저장 프로퍼티: 마커 `id`, `NMGLatLng` 좌표
  - `NMCClusteringKey` 요구사항인 `position: NMGLatLng` 프로퍼티 제공
  - `func copy(with zone: NSZone? = nil) -> Any` (`NSCopying`) 구현
  - `override func isEqual(_:)`, `override var hash: Int` 구현 (id 기준 동등성)
- 구현 전 `NMCClusteringKey` 프로토콜의 정확한 요구 멤버는 `Tuist/.build/artifacts/spm-nmapsmap/.../Headers/NMCClusteringKey.h` 헤더를 직접 확인 후 반영 (추측 금지, CLAUDE.md 원칙)

---

#### [x] Task 6 — `TabiMapView+Coordinator.swift` — 클러스터링 경로 확장
**파일**: `Projects/DesignSystem/Sources/Map/TabiMapView+Coordinator.swift`
- Coordinator에 클러스터러 보관 프로퍼티 추가 (예: `clusterer: NMCClusterer<TabiClusteringKey>?`)
- `NMCBuilder<TabiClusteringKey>().build()`로 `NMCClusterer` 생성 후 `mapView`에 부착하는 메서드 추가
- 클러스터 데이터 동기화(`addAll`/`removeAll` 또는 `add(key:tag:)`)로 `markers` 반영하는 메서드 추가
- leaf 마커 개별 탭 시 `onMarkerTapped` 연결: 구현 시점에 `NMCLeafMarkerUpdater.h`, `NMCDefaultLeafMarkerUpdater.h` 헤더(plan.md Critical Files 경로 참고)를 직접 확인해 leaf 마커의 터치 핸들러를 세팅하는 방식으로 구현 (추측 금지)
- `isClusteringEnabled` 값에 따라 Task 4의 비클러스터 경로 또는 이 Task의 클러스터 경로 중 하나만 활성화되도록 Coordinator 내부에서 분기하는 진입점 메서드 정리 (Task 3 `makeUIView`/`updateUIView`에서 호출)

---

### Phase 5. 생성 및 빌드 검증

#### [x] Task 7 — Tuist 프로젝트 생성 및 빌드 확인
**파일**: 해당 없음 (빌드/생성 명령 실행)
- 새 `.swift` 파일 3개(`TabiMapMarker.swift`, `TabiMapView+Coordinator.swift`, `TabiClusteringKey.swift`) 추가로 인한 stale 프로젝트 방지를 위해 `tuist install`(필요 시) → `tuist generate` 실행
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`로 빌드 성공 확인
- 컴포넌트 단위로 다음 동작을 확인 (DesignSystem에 `#Preview` 컨벤션이 아직 없으므로 프리뷰 신설은 스코프 밖, 실제 화면 연결 없이 코드 리뷰/빌드 성공 기준으로 검증):
  - 초기 카메라가 `centerLatitude`/`centerLongitude`/`zoomLevel`로 렌더링되는지
  - `markers` 표시 및 배열 갱신 시 추가/삭제분만 반영되는지
  - `isClusteringEnabled == true`일 때 클러스터링 동작
  - `showsLocationButton == true`일 때 현위치 버튼 노출 및 `.direction` 추적
  - 지도/마커 탭 콜백 및 마커 탭의 지도 탭 미전파
  - 리렌더링 시 카메라가 리셋되지 않는지
- `NMGLatLng`/`NMFMarker` 등 SDK 타입이 `TabiMapView`/`TabiMapMarker`의 public 시그니처에 노출되지 않았는지 최종 확인

---

## 체크리스트

### 품질 (DoD)
- [ ] `tuist generate` 후 `AppDebug` 스킴 빌드 성공
- [ ] `swift-style.md` 준수 (MARK 섹션 순서, 프로토콜 채택 extension 분리, 접근 제어 최소화, `self` 키워드 사용, `weak self`/값 캡처 규칙)
- [ ] `folder-structure.md` 준수 (`Map/` 폴더 단위 파일 배치)
- [ ] `TabiMapView`, `TabiMapMarker`만 `public`, Coordinator·`TabiClusteringKey`는 `internal`/`private`로 최소화
- [ ] `NMGLatLng`, `NMFMarker` 등 `NMapsMap` SDK 타입이 public 시그니처에 노출되지 않음
- [ ] 테스트 타겟 미구성 상태이므로 별도 테스트 코드 작성 없음 (`.claude/CLAUDE.md` 참조)

### 기능 (AC)
- [ ] `TabiMapView(centerLatitude:centerLongitude:)` 호출 시 해당 좌표를 중심으로 초기 카메라가 위치한 지도가 렌더링된다
- [ ] `markers` 배열의 각 항목이 지도 위에 마커로 표시되고, 배열이 갱신되면 추가/삭제분만 반영된다
- [ ] `isClusteringEnabled == true`일 때 인접한 마커들이 하나의 클러스터 마커로 합쳐지고, 확대하면 펼쳐진다
- [ ] `showsLocationButton == true`일 때 현위치 버튼이 노출되고 위치 추적(`.direction`)이 동작한다
- [ ] 지도를 탭하면 `onMapTapped(latitude, longitude)`가 정확한 좌표로 호출된다
- [ ] 마커를 탭하면 `onMarkerTapped(markerID)`가 해당 마커의 id로 호출되고, 지도 탭 이벤트로는 전파되지 않는다
- [ ] SwiftUI가 뷰를 리렌더링해도 사용자가 이동시킨 카메라 위치가 임의로 초기 좌표로 리셋되지 않는다
- [ ] `tuist generate` 후 `AppDebug` 스킴 빌드가 성공한다
