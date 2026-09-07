# naver_map (TabiMapView 네이버맵 통합)

## 무엇을 하는가
DesignSystem의 `TabiMapView`가 네이버맵 SDK(`NMapsMap`)를 `UIViewRepresentable`로 감싸 SwiftUI 화면에서 지도를 사용할 수 있게 한다. 네이버맵 SDK는 UIKit만 지원하므로 SwiftUI 쪽에 노출되는 컴포넌트는 이 래핑을 통해서만 제공된다. 목적은 관광지 좌표를 지도 위에 시각화하고, 사용자의 현재 위치 및 지도/마커 터치 인터랙션을 화면(Presentation) 레이어에 전달하는 것이다.

## 동작 명세
- 트리거: `TabiMapView(centerLatitude:centerLongitude:zoomLevel:markers:isClusteringEnabled:showsLocationButton:onMapTapped:onMarkerTapped:)`가 SwiftUI 뷰 계층에 배치될 때
- 결과:
  - 초기 카메라가 `centerLatitude`/`centerLongitude`/`zoomLevel`로 이동한 상태로 지도가 렌더링된다
  - `markers`에 담긴 좌표마다 마커가 표시된다 (`isClusteringEnabled == true`면 인접 마커가 클러스터 마커로 합쳐진다)
  - `showsLocationButton == true`면 현위치 버튼이 노출되고 위치 추적 모드(`.direction`)로 카메라/오버레이가 사용자 위치를 따라간다
  - 지도를 탭하면 `onMapTapped(latitude, longitude)`가, 마커를 탭하면 `onMarkerTapped(markerID)`가 호출된다
- 사이드이펙트:
  - 없음 — 지도 타일 로딩, 인증 통신은 SDK 내부에서 처리
  - `showsLocationButton == true`인 경우 SDK가 내부적으로 위치 권한 프롬프트를 트리거할 수 있음 (Info.plist `NSLocationWhenInUseUsageDescription`은 이미 등록됨)
- 불변 조건:
  - 초기 카메라 위치는 `makeUIView` 시점에 **1회만** 설정되고, 이후 SwiftUI가 `updateUIView`를 다시 호출해도 카메라는 리셋되지 않는다 (사용자가 지도를 움직인 뒤 리렌더링 때마다 원위치로 튕기는 문제 방지)
  - `markers` 배열 변경은 추가/삭제 diff로만 반영된다. 동일 id의 좌표 값 변경은 이번 스코프에서 반영하지 않는다 — 좌표가 바뀌는 화면은 호출부에서 `TabiMapView`를 `id(_:)`로 재생성해야 한다

## 무엇이 잘못될 수 있는가
- `Secret.xcconfig`의 `NAVERMAP_CLIENT_ID`가 비어있거나 잘못됨 → Info.plist `NMFGovClientId` 값이 비어 SDK 인증 실패, 지도가 빈 화면으로 표시됨 (앱 코드 문제 아님, 로컬 설정 문제)
- 위치 권한이 거부된 상태에서 `showsLocationButton == true` → 현위치 버튼은 보이지만 오버레이/추적은 동작하지 않음 (에러 throw 아님, SDK가 조용히 무시)
- `markers` 배열에 동일한 `id`가 중복 존재 → Coordinator 내부 `[String: NMFMarker]` 캐시에서 나중 항목이 이전 항목을 덮어씀 (마커 1개만 남음)

## 무엇에 의존하는가
### 의존성
- `NMapsMap` SPM 패키지 (`Tuist/Package.swift`, `from: "3.23.3"`) — 이미 등록됨
- `DependencyInformation.swift`의 `designSystem → naverMap` 외부 의존성 — 이미 등록됨
- Info.plist `NMFGovClientId` 키 (`NAVERMAP_CLIENT_ID` xcconfig 변수 매핑) — 이미 등록됨, gov-cloud 전용 인증 키로 Info.plist 등록만으로 SDK가 자동 인증
- `NSLocationWhenInUseUsageDescription` — 이미 등록됨 (`showsLocationButton` 기능에 필요)

### 제약
- `DesignSystem`은 `Domain`을 의존할 수 없음 (`internalDependencyInfo`: `designSystem: [.core, .resource]`) → `TabiMapView`의 public API는 `Domain.Coordinate`가 아닌 `Double` 위경도로 좌표를 노출한다
- `NMGLatLng`, `NMFMarker` 등 `NMapsMap` SDK 타입은 `TabiMapView`의 public 시그니처에 노출하지 않는다 (Presentation은 `NMapsMap`을 import하지 않음)
- `NMFNaverMapView.delegate`/`.positionMode`는 deprecated — `NMFMapView`의 `touchDelegate`/`addCameraDelegate(delegate:)`/`positionMode`를 사용해야 함
- 클러스터링(`NMC*` 네임스페이스)은 `NMapsMap` 프레임워크에 함께 번들되어 있어 별도 SPM 의존성 추가가 필요 없음. `NMCClusteringKey` 채택 타입은 `NSObject` + `NSCopying`을 요구함

## Acceptance Criteria
- [ ] `TabiMapView(centerLatitude:centerLongitude:)` 호출 시 해당 좌표를 중심으로 초기 카메라가 위치한 지도가 렌더링된다
- [ ] `markers` 배열의 각 항목이 지도 위에 마커로 표시되고, 배열이 갱신되면 추가/삭제분만 반영된다
- [ ] `isClusteringEnabled == true`일 때 인접한 마커들이 하나의 클러스터 마커로 합쳐지고, 확대하면 펼쳐진다
- [ ] `showsLocationButton == true`일 때 현위치 버튼이 노출되고 위치 추적(`.direction`)이 동작한다
- [ ] 지도를 탭하면 `onMapTapped(latitude, longitude)`가 정확한 좌표로 호출된다
- [ ] 마커를 탭하면 `onMarkerTapped(markerID)`가 해당 마커의 id로 호출되고, 지도 탭 이벤트로는 전파되지 않는다
- [ ] SwiftUI가 뷰를 리렌더링해도(예: 부모 상태 변경) 사용자가 이동시킨 카메라 위치가 임의로 초기 좌표로 리셋되지 않는다
- [x] `tuist generate` 후 `AppDebug` 스킴 빌드가 성공한다
