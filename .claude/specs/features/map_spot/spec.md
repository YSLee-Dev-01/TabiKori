# map_spot

## 무엇을 하는가
MapView에서 키워드 검색 시, 현재는 검색 결과를 sheet 리스트에만 표시한다. 사용자가 지도 위에서도 검색 결과의 위치와 가게 이름을 한눈에 파악할 수 있도록, 동일한 검색 결과를 네이버지도 위에 마커(가게 이름 캡션 포함)로도 함께 표시한다.

## 동작 명세
- 트리거: MapView 상단 검색창에서 키워드를 입력하고 검색을 제출(`searchSubmitted`)하여 첫 페이지 검색 결과(`searchResultsResult`)가 도착했을 때
- 결과:
  - sheet 리스트와 동일한 `searchResults` 항목들이 지도 위에 `TabiMapMarker`로 표시된다 (마커 캡션 = `spot.title`, DetailMapTabView와 동일한 표기 방식)
  - 검색 결과가 처음 로드된 시점에 지도 카메라가 결과 전체가 화면에 들어오도록 자동으로 이동/줌된다 (bounds-fit)
  - 지도 마커를 탭하면 sheet 리스트의 동일 항목을 탭한 것과 같은 동작(`searchResultTapped`)이 발생해 상세화면(`DetailView`)으로 이동한다
  - 검색 취소(`searchCancelTapped`) 또는 검색어가 비워져 `searchResults`가 초기화되면 지도 위 마커도 함께 사라진다
- 사이드이펙트:
  - 없음 (기존 `searchByKeyword` 네트워크 호출 결과를 재사용, 추가 네트워크 요청 없음)
  - 단, `TouristSpot` 엔티티에 `coordinate: Coordinate` 프로퍼티가 신규로 추가되므로 DTO 매핑(`TouristSpotItemDTO.toEntity()`)이 `mapx`/`mapy` 필드를 새로 디코딩해야 함
- 불변 조건:
  - 무한 스크롤로 다음 페이지가 추가 로드(`searchNextPageResultsResult`)되어도 카메라는 재이동하지 않는다 (최초 결과 도착 시 1회만 이동)
  - 사용자가 지도를 수동으로 드래그/줌한 이후에는, 동일 검색 결과에 대해 카메라가 강제로 재이동되지 않는다
  - 클러스터링은 적용하지 않는다 (`TabiMapView.isClusteringEnabled` 기본값 유지)

## 무엇이 잘못될 수 있는가
- 검색/주변목록 API 응답에 `mapx`/`mapy` 필드가 실제로 포함되지 않는 경우 → 좌표를 파싱할 수 없으므로, 해당 항목을 마커 목록에서 제외할지 원점(0,0) 등으로 포함할지 결정 필요 (`TouristSpotDetailDTO`와의 처리 방식 일관성 유지)
- `mapx`/`mapy` 문자열이 숫자로 변환 불가능한 경우(`toDouble()` 실패) → 해당 항목은 좌표 없이 처리(마커 미표시), sheet 리스트 표시에는 영향 없음
- 검색 결과가 0건인데 카메라 bounds-fit이 시도되는 경우 → 카메라를 이동하지 않고 현재 위치/줌 유지
- 검색 결과가 1건뿐인 경우 → bounds-fit 계산 시 유효한 영역이 만들어지지 않을 수 있으므로 별도 처리(단일 좌표로 중심 이동 등) 필요
- 마커 탭 시 전달된 `id`가 `searchResults`에서 매칭되지 않는 경우(동시성으로 목록이 이미 갱신된 경우 등) → 아무 동작도 하지 않음

## 무엇에 의존하는가
### 의존성
- `Domain/Sources/Entity/TouristSpot.swift` — `coordinate: Coordinate` 프로퍼티 추가 대상
- `Domain/Sources/Entity/Coordinate.swift` — 기존 좌표 타입 재사용
- `Data/Sources/DTO/TouristSpot/TouristSpotDTO.swift` — `TouristSpotItemDTO`에 `mapx`/`mapy` 필드 추가 및 `toEntity()` 매핑
- `Data/Sources/DTO/TouristSpotDetail/TouristSpotDetailDTO.swift` (60~93행) — `mapx`/`mapy` → `Coordinate` 변환의 기존 참조 패턴
- `DesignSystem/Sources/Map/TabiMapView.swift`, `TabiMapView+Coordinator.swift`, `TabiMapMarker.swift` — 마커 표시/탭 콜백 재사용, 카메라 bounds-fit 기능 신규 확장 필요
- `Presentation/Sources/Detail/Sub/DetailMapTabView.swift` — 마커 title 표기 참조 패턴 (`spot.title` 사용)
- `Presentation/Sources/Map/MapFeature.swift` — `searchResults`, `searchResultTapped(TouristSpot)` 액션
- `Presentation/Sources/Map/MapView.swift` — `mapBackground()`의 `TabiMapView` 호출부
- `Presentation/Sources/Tabbar/TabBarFeature.swift` (68~70행) — `.map(.searchResultTapped)` 수신 시 기존 상세화면 네비게이션 로직 재사용
- NMapsMap/NMapsGeometry — `NMFCameraUpdate`(bounds-fit 카메라 이동), `NMGLatLngBounds`(좌표 목록 → bounds 생성). 정확한 Swift 브릿징 시그니처는 구현 시 Xcode에서 재확인

### 제약
- Domain은 Data를 참조하지 않는다 (DTO→Entity 매핑은 Data 모듈에서만 수행)
- `TouristSpot`은 기존에 DTO 매핑, `DetailView.swift` 프리뷰 mock 등에서 생성되고 있으므로, `coordinate` 추가 시 모든 생성 지점을 함께 수정해야 컴파일이 유지된다
- API 필드명(`mapx`/`mapy`가 검색/주변목록 응답에도 존재하는지)은 추측하지 않고 실제 응답으로 검증한다
- NMapsMap 관련 API 시그니처는 추측하지 않고 헤더/Xcode에서 확인 후 사용한다
- 새 `.swift` 파일이 추가되는 경우 `tuist generate` 필요 (기존 파일 수정만으로 끝나면 불필요)
- 카테고리 칩, 최근검색 placeholder 등 현재 기능과 무관한 기존 코드는 수정하지 않는다

## Acceptance Criteria
- [x] `TouristSpot`에 `coordinate`가 추가되고 모든 생성 지점이 정상 컴파일된다
- [x] 키워드 검색 시 sheet 목록과 동일한 항목들이 지도 위에 마커(가게 이름 캡션 포함)로 표시된다
- [x] 검색 결과가 처음 로드될 때 지도 카메라가 결과 전체가 보이도록 자동 이동/줌되며, 다음 페이지 추가 로드 시에는 재이동하지 않는다
- [x] 지도 마커를 탭하면 sheet의 해당 항목을 탭한 것과 동일하게 상세화면으로 이동한다
- [x] 검색 취소/검색어 비움 시 지도 위 마커가 사라진다
- [x] `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 빌드 성공
