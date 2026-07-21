# tabbar_map

## 무엇을 하는가
탭바 2번째 탭(지도)에 진입하면 사용자의 현재 위치(또는 위치 권한이 없을 경우 서울시청)를 중심으로 한 지도를 화면 전체에 보여준다. 사용자가 여행 중 자신의 위치를 기준으로 주변을 지도 앱처럼 탐색할 수 있도록 하기 위함.

## 동작 명세
- 트리거:
  - 지도 탭 최초 선택(진입) 시
- 결과:
  - 화면 전체를 채우는 지도(TabiMapView) 위에 상단 타이틀("マップ")이 오버레이됨 (지도 레이아웃에 영향 없음)
  - 위치 권한이 `undetermined`이면 시스템 위치 권한 요청 팝업이 자동으로 노출됨 (Home과 동일 패턴)
  - 위치 권한이 `allowed`가 되면:
    - 최초 1회, 지도 카메라가 사용자의 현재 좌표로 이동
    - 이후 네이버맵 SDK 자체 실시간 내 위치 표시(파란 점)가 켜져 사용자가 이동하면 위치 표시가 계속 갱신됨 (`positionMode = .normal` — 마커만 갱신, 카메라 오토팔로우 없음)
    - 카메라는 최초 이동 이후 자동으로 따라가지 않으며, 사용자가 지도를 자유롭게 이동/확대할 수 있음
  - 위치 권한이 `denied`이거나 좌표 조회(fetchCurrentCoordinate)가 실패하면:
    - 지도 카메라가 서울시청 좌표(37.5666102, 126.9783881)를 중심으로 표시됨
    - 실시간 내 위치 표시는 꺼진 상태(`showsLocationButton = false`)
- 사이드이펙트:
  - `LocationUseCase`를 통한 위치 권한 조회/요청, 최초 좌표 조회 (CLLocationManager)
  - 네트워크/DB 호출 없음, 관광지 마커 없음
- 불변 조건:
  - 지도는 항상 화면 전체를 가득 채운 상태로 렌더링됨 (권한/조회 결과와 무관)
  - 위치 조회 실패/미허용 시에도 지도 자체는 항상 렌더링됨 (서울시청 폴백)
  - 탭을 벗어났다가 다시 돌아와도 최초 진입 이후에는 카메라를 자동으로 재이동하지 않음 (사용자가 탐색한 위치 유지)

## 무엇이 잘못될 수 있는가
- 위치 조회(`fetchCurrentCoordinate`) 실패(에러 throw) → 서울시청 좌표로 폴백, `AppLogger.view`에 에러 로그
- 위치 권한 거부(`denied`) → 서울시청 좌표로 폴백, 권한 요청 팝업 재노출 안 함
- 위치 권한 `undetermined` 상태에서 사용자가 권한 요청 팝업을 거부 → 결과적으로 `denied`와 동일하게 서울시청 좌표로 폴백

## 무엇에 의존하는가
### 의존성
- `LocationUseCaseProtocol`(Domain) — `checkAuthorization`, `requestAuthorization`, `fetchCurrentCoordinate`
  - `TabiMapView`가 init 시점에 `centerLatitude`/`centerLongitude`를 필수로 요구하므로, 네이버맵 자체 위치 기능만으로는 최초 카메라 좌표를 결정할 수 없음 → `fetchCurrentCoordinate()`로 최초 좌표(또는 서울시청 폴백)를 조회한 뒤 `TabiMapView`에 전달
- `TabiMapView`(DesignSystem) — `centerLatitude`/`centerLongitude`로 최초 카메라 위치 지정, 실시간 내 위치 표시 on/off 및 모드 제어
  - **수정 필요**: 현재 `showsLocationButton=true`일 때 `positionMode`가 `.direction`(오토팔로우)로 고정되어 있음. "마커만 실시간 갱신, 카메라는 따라가지 않음" 요구사항을 만족하려면 `.normal` 모드를 선택할 수 있는 파라미터 추가가 필요함
- 상단 타이틀 오버레이 UI (기존 `TabiNavigationBar` 재사용 가능 여부는 plan 단계에서 확인)
- `AppTab.map`, `TabBarFeature.State.mapState`(현재 임시 빈 State) → 신규 `MapFeature`로 대체
- `Strings.Tabbar.map` 값을 기존 `"地図"`에서 `"マップ"`로 교체 (신규 문자열 추가 아님, 값 교체)
  - 이 값은 `AppTab.map.title` → `TabBarView.swift`의 임시 placeholder(`Text(AppTab.map.title)`, 이번 기능으로 교체될 부분)에서만 참조되므로 교체해도 다른 화면에 영향 없음
  - `Detail` 쪽의 다른 `地図` 문자열들(`tabMap`, `sectionMap`, `openInMaps`, `mapComingSoon`)은 이 기능과 무관한 별개 문자열이라 변경 대상 아님

### 제약
- Naver Map SDK(NMapsMap) 인증키 필요 (기 설정됨)
- 관광지 마커(TouristSpot) 표시는 이번 스펙 범위 아님 (추후 별도 기능)
- 위치 스트리밍(지속 조회) 로직은 자체 구현하지 않고 네이버맵 SDK의 내장 위치 표시 기능(`positionMode = .normal`)에 위임

## Acceptance Criteria
- [ ] 지도 탭 진입 시 화면 전체를 채우는 지도가 표시되고 상단에 "マップ" 타이틀이 오버레이된다
- [ ] 위치 권한이 `undetermined`이면 최초 진입 시 시스템 권한 요청 팝업이 자동으로 노출된다
- [ ] 위치 권한이 허용되면 최초 1회 지도 카메라가 사용자의 현재 위치로 이동하고, 이후 사용자가 이동하면 실시간 내 위치 표시(파란 점)가 갱신된다
- [ ] 위치 권한이 없거나(`denied`) 좌표 조회에 실패하면 지도 중심이 서울시청(37.5666102, 126.9783881)으로 설정되고 실시간 위치 표시는 꺼져 있다
- [ ] 최초 카메라 이동 이후 사용자가 지도를 임의로 이동/확대해도 자동으로 내 위치로 다시 이동하지 않는다
- [ ] 탭을 벗어났다가 다시 돌아와도 카메라가 자동으로 재이동하지 않는다
