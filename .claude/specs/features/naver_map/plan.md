# Plan: naver_map (TabiMapView 네이버맵 통합)

## 참조 Spec
- @specs/features/naver_map/spec.md

## 참조 Skill
- 해당 없음 (신규 화면 생성이 아닌 DesignSystem 단일 컴포넌트 구현)

## 현재 상태 파악
- 신규:
  - `Projects/DesignSystem/Sources/Map/TabiMapMarker.swift` — 지도에 표시할 마커의 public 모델 (`id: String`, `latitude: Double`, `longitude: Double`). SDK 타입 미노출, `Identifiable`/`Equatable` 채택.
  - `Projects/DesignSystem/Sources/Map/TabiMapView+Coordinator.swift` — `UIViewRepresentable.Coordinator`. 마커 캐시(`[String: NMFMarker]`), 클러스터러 보관, 터치/카메라 델리게이트 채택, 콜백 보관.
  - `Projects/DesignSystem/Sources/Map/TabiClusteringKey.swift` — 클러스터링용 내부 키 타입 (`NSObject` + `NSCopying` + `NMCClusteringKey` 채택, `position: NMGLatLng` 제공). SDK 요구 프로토콜 충족용, 모듈 외부 미노출(internal).
- 재사용:
  - `Projects/DesignSystem/Sources/Button/TabiButton.swift` — "본체 + 보조 타입을 `// MARK: -`로 구분" 파일 구성 컨벤션 참고.
  - 이미 등록된 인프라: `Tuist/Package.swift`(`SPM-NMapsMap 3.23.3`), `DependencyInformation.swift`(`designSystem → naverMap`), `App/Info.plist`의 `NMFGovClientId` / `NSLocationWhenInUseUsageDescription`, `Data/Sources/Secret.xcconfig`의 `NAVERMAP_CLIENT_ID`. → 추가 등록/수정 불필요.
- 수정:
  - `Projects/DesignSystem/Sources/Map/TabiMapView.swift` — 현재 `Color.clear`만 반환하는 스켈레톤을 `UIViewRepresentable` 기반 본체로 전면 재작성.
- 삭제:
  - 없음 (기존 `TabiMapView` public 심볼은 유지하며 내부만 교체).

## 기술적 결정사항
- **`UIViewRepresentable` 래핑**: 네이버맵 SDK는 UIKit(`NMFNaverMapView`)만 제공하므로 SwiftUI 노출은 `UIViewRepresentable`로만 가능. 대안(`UIViewControllerRepresentable`)은 뷰 컨트롤러 수명주기가 불필요해 채택하지 않음.
- **좌표 타입은 `Double` 위경도로 노출**: `DesignSystem`은 `Domain`을 의존할 수 없고(`internalDependencyInfo: designSystem: [.core, .resource]`), Presentation은 `NMapsMap`을 import하지 않아야 하므로 `NMGLatLng`/`NMFMarker` 등 SDK 타입을 public 시그니처에 노출 금지. 내부에서만 `Double → NMGLatLng` 변환.
- **초기 카메라 1회 설정**: `makeUIView`에서만 `moveCamera`(애니메이션 없이)로 초기 위치를 잡고, `updateUIView`에서는 카메라를 절대 다시 세팅하지 않음. 재설정 방지를 위해 Coordinator에 `isInitialCameraApplied` 플래그를 둔다. → Acceptance "리렌더링 시 카메라 리셋 방지" 충족.
- **마커 diff 반영**: Coordinator가 `[String: NMFMarker]` 캐시를 보유. `updateUIView`에서 신규 `markers`의 id 집합과 캐시 키를 비교해 추가분만 생성(`.mapView` 대입)·삭제분만 제거(`.mapView = nil`). 동일 id의 좌표 변경은 스코프 밖(호출부가 `id(_:)`로 재생성). 중복 id는 딕셔너리 특성상 마지막 항목만 잔존(Spec의 "잘못될 수 있는 것"과 일치).
- **델리게이트 API 선택**: deprecated된 `NMFNaverMapView.delegate`/`.positionMode` 대신 `NMFMapView`의 `touchDelegate`, `positionMode`(`.direction`), `showLocationButton`을 사용.
- **마커 탭의 지도 탭 전파 차단**: `NMFMarker.touchHandler`에서 `true`를 반환해 지도 탭(`didTapMap`)으로 이벤트가 전파되지 않도록 함. → Acceptance "마커 탭이 지도 탭으로 전파되지 않음" 충족.
- **클러스터링은 별도 SPM 의존성 없이 번들된 `NMC*` 사용**: 확인된 헤더(`NMCBuilder.h`, `NMCClusterer.h`, `NMCClusteringKey.h`, `NMCDefaultLeafMarkerUpdater.h` 등)가 `NMapsMap.framework/Headers`에 동봉됨. 내부 키 타입 `TabiClusteringKey`(`NSObject`+`NSCopying`+`NMCClusteringKey`)로 `NMCBuilder<TabiClusteringKey>().build()` → `NMCClusterer`를 `mapView`에 부착하고 `addAll`/`removeAll`로 관리.
- **클러스터 leaf 마커 탭 연결은 구현 시점 헤더 확인**: 클러스터링 모드에서 leaf 마커 개별 탭(`onMarkerTapped`)을 연결하려면 `NMCLeafMarkerUpdater`/`NMCDefaultLeafMarkerUpdater` 커스터마이징이 필요할 수 있음. 정확한 프로토콜 요구사항은 추측하지 말고 구현 시점에 `Tuist/.build/artifacts/spm-nmapsmap/.../Headers/NMCLeafMarkerUpdater.h`, `NMCDefaultLeafMarkerUpdater.h`를 직접 열어 확인 후 반영.
- **파일 분리 기준**: `TabiButton`은 단일 파일 컨벤션이나, 본 컴포넌트는 Representable 본체·Coordinator·클러스터 키·마커 모델로 관심사가 커 `swift-style.md`(대형 뷰 분리)·`folder-structure.md`(`Map/` 폴더 단위) 원칙에 따라 `Map/` 폴더 내 파일로 분리. 프로토콜 채택은 `swift-style.md` 규칙대로 별도 `extension`으로 분리.
- **접근 제어**: `TabiMapView`, `TabiMapMarker`만 `public`. Coordinator·`TabiClusteringKey`·헬퍼는 `internal`/`private`로 최소화.

## 구현 순서

### Phase 1. Public API / 모델 (DesignSystem)
- `TabiMapMarker` 모델 정의: `id: String`, `latitude: Double`, `longitude: Double`. `Identifiable`, `Equatable` 채택. SDK 타입 미포함.
- `TabiMapView`의 public `init` 시그니처 확정: `centerLatitude: Double`, `centerLongitude: Double`, `zoomLevel: Double`, `markers: [TabiMapMarker]`, `isClusteringEnabled: Bool`, `showsLocationButton: Bool`, `onMapTapped: (Double, Double) -> Void`, `onMarkerTapped: (String) -> Void`. 저장 프로퍼티는 모두 `private let`, 콜백은 `@escaping`.

### Phase 2. UIViewRepresentable 본체 (TabiMapView.swift 재작성)
- `import SwiftUI`, `import NMapsMap` 추가. `struct TabiMapView: UIViewRepresentable`로 전환.
- `makeCoordinator()` → Coordinator 생성 시 콜백 전달.
- `makeUIView(context:)`:
  - `NMFNaverMapView` 생성, `showLocationButton = showsLocationButton` 설정.
  - `mapView.touchDelegate = context.coordinator` 연결.
  - 초기 카메라 `NMFCameraUpdate(scrollTo:)` + `zoomTo` 로 애니메이션 없이 1회 이동, Coordinator `isInitialCameraApplied = true`.
  - `showsLocationButton == true`면 `mapView.positionMode = .direction`.
  - `isClusteringEnabled`에 따라 Coordinator에서 클러스터러 부착 여부 결정(Phase 4에서 상세).
  - 초기 `markers` 반영.
- `updateUIView(_:context:)`:
  - 카메라 재설정 금지.
  - `showLocationButton`·`positionMode` 등 토글 반영(필요 시).
  - Coordinator를 통해 마커 add/remove diff 수행.

### Phase 3. Coordinator & 델리게이트 (TabiMapView+Coordinator.swift)
- `final class Coordinator: NSObject`: `onMapTapped`/`onMarkerTapped` 콜백, `[String: NMFMarker]` 캐시, `isInitialCameraApplied`, 클러스터러 참조 보유.
- `// MARK: - NMFMapViewTouchDelegate` extension: `mapView(_:didTapMap:point:)`에서 좌표를 `Double` lat/lng로 변환해 `onMapTapped(lat, lng)` 호출.
- 마커 동기화 메서드(비클러스터 경로): 신규 id 집합 대비 캐시 diff → 추가 마커 생성 시 `iconImage`(기본), `position`, `touchHandler`(내부에서 `onMarkerTapped(id)` 호출 후 `true` 반환) 설정하고 `.mapView` 대입 / 삭제분은 `.mapView = nil` 후 캐시 제거.
- `weak self` 규칙 준수(`class`이므로 `touchHandler`/콜백 클로저에서 캡처 주의), `self` 키워드로 내부 프로퍼티 참조.

### Phase 4. 클러스터링 (TabiClusteringKey.swift + Coordinator 확장)
- `TabiClusteringKey: NSObject, NSCopying, NMCClusteringKey`: `id`, `NMGLatLng` 보관, `position` 프로퍼티 제공, `NSCopying`/`isEqual`/`hash` 구현.
- Coordinator에 클러스터링 경로 추가: `NMCBuilder<TabiClusteringKey>().build()`로 `NMCClusterer` 생성 후 `mapView`에 부착. 데이터 동기화는 `addAll`/`removeAll`(또는 `add(key:tag:)`)로 처리.
- leaf 마커 개별 탭(`onMarkerTapped`) 연결: 구현 시점에 `NMCLeafMarkerUpdater.h`/`NMCDefaultLeafMarkerUpdater.h` 헤더를 직접 확인해 leaf 마커의 `touchHandler`를 세팅하는 방식으로 반영(추측 금지).
- `isClusteringEnabled` 값에 따라 비클러스터(Phase 3) / 클러스터(Phase 4) 경로 중 하나만 활성화하도록 분기.

### Phase 5. 생성 및 빌드 검증
- 새 `.swift` 파일 추가로 인한 stale 프로젝트 방지: `tuist install`(불필요 시 생략) 후 `tuist generate`.
- `AppDebug` 스킴 빌드: `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`.
- 컴포넌트 단위 동작(초기 카메라, 마커 표시, 클러스터, 현위치 버튼, 지도/마커 탭 콜백)을 확인. (DesignSystem에는 아직 `#Preview` 컨벤션이 없으므로 프리뷰 신설은 스코프 밖.)

## 스코프 밖 (명시)
- Presentation 화면에서의 `TabiMapView` 소비/통합, 새 화면 생성.
- 동일 id 마커의 좌표 값 변경 반영(호출부 `id(_:)` 재생성으로 처리).
- `DependencyInformation.swift`, `Package.swift`, `Info.plist`, `Secret.xcconfig` 변경(모두 이미 등록됨).

## 완료 조건
- [ ] Spec Acceptance Criteria 전 항목 충족
  - [ ] `TabiMapView(centerLatitude:centerLongitude:)` 초기 카메라 위치 렌더링
  - [ ] `markers` 표시 및 배열 갱신 시 추가/삭제분만 반영
  - [ ] `isClusteringEnabled == true`에서 인접 마커 클러스터링 및 확대 시 펼침
  - [ ] `showsLocationButton == true`에서 현위치 버튼 노출 및 `.direction` 추적
  - [ ] 지도 탭 시 `onMapTapped(latitude, longitude)` 정확 좌표 호출
  - [ ] 마커 탭 시 `onMarkerTapped(markerID)` 호출 및 지도 탭 미전파
  - [ ] 리렌더링 시 사용자 이동 카메라가 초기 좌표로 리셋되지 않음
- [ ] `tuist generate` 후 `AppDebug` 빌드 성공
- [ ] `NMGLatLng`/`NMFMarker` 등 SDK 타입이 `TabiMapView`/`TabiMapMarker`의 public 시그니처에 노출되지 않음
- [ ] `swift-style.md`(MARK 순서, 프로토콜 extension 분리, 접근 제어 최소화, `self` 사용) 준수

---

### Critical Files for Implementation
- /Users/yslee/Desktop/Project/TabiKori/Projects/DesignSystem/Sources/Map/TabiMapView.swift
- /Users/yslee/Desktop/Project/TabiKori/Projects/DesignSystem/Sources/Map/TabiMapView+Coordinator.swift (신규)
- /Users/yslee/Desktop/Project/TabiKori/Projects/DesignSystem/Sources/Map/TabiMapMarker.swift (신규)
- /Users/yslee/Desktop/Project/TabiKori/Projects/DesignSystem/Sources/Map/TabiClusteringKey.swift (신규)
- /Users/yslee/Desktop/Project/TabiKori/Tuist/.build/artifacts/spm-nmapsmap/NMapsMapBinary/framework/NMapsMap.xcframework/ios-arm64/NMapsMap.framework/Headers/NMCDefaultLeafMarkerUpdater.h (구현 시 확인용)
