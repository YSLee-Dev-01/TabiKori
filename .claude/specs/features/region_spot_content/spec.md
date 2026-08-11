# region_spot_content

## 무엇을 하는가
홈 화면에서 지역 카드를 탭하면 이동하는 `RegionSpotView`가 현재 "Coming Soon" 안내만 표시하는 빈 화면이다. 이 화면에 실제 콘텐츠(해당 지역의 관광지 목록, 진행 중인 축제)를 채워 사용자가 지역을 선택했을 때 그 지역을 탐색할 수 있게 한다.

데이터 소스는 지역코드 기반 조회 API인 **`areaBasedList2`**를 신규 연동하는 방식(A안)을 사용한다. 기존 좌표 기반(`locationBasedList2`) 방식은 반경 밖 관광지가 누락되고 지역 경계와 정확히 일치하지 않아 "지역 전체" 탐색이라는 화면 목적에 맞지 않기 때문이다.

## 동작 명세

- 트리거:
  - 홈 화면 지역 카드 탭 → `HomeFeature.Action.regionCardTapped(KoreanRegion)` → `TabBarFeature`가 `StackPath.region(RegionSpotFeature.State(region:))`로 push (기존 라우팅 유지, 변경 없음)
  - `RegionSpotView` 진입 시 `Action.onAppear`에서 콘텐츠 로딩 시작

- 결과:
  - 헤더(지역 이미지 + 지역명)는 기존 유지
  - 카테고리 탭(관광지/맛집/숙박 등 `CategoryType` 기반)으로 전환 가능한 관광지 리스트 섹션 표시
  - 해당 지역에서 진행 중인 축제 섹션 표시 (기존 `FestivalEndpoint.searchFestival2`의 `lDongRegnCd` 파라미터 재사용)
  - 로딩 중 스켈레톤/로딩 인디케이터, 데이터 없음 시 빈 상태 UI 표시

- 사이드이펙트:
  - `areaBasedList2` API 호출 (신규)
  - `searchFestival2` API 호출 (지역 파라미터로 재호출, 기존 축제 화면과 별개 호출)

- 불변 조건:
  - `KoreanRegion` 값이 유효한 `areaCode`로 매핑되지 못하는 케이스는 없어야 한다 (앱에 정의된 모든 `KoreanRegion` 케이스는 매핑 테이블에 존재해야 함)
  - 카테고리 탭 전환 시 이전 요청의 응답이 늦게 도착해도 현재 선택된 탭과 다른 결과로 리스트가 덮어써지지 않아야 한다

## 무엇이 잘못될 수 있는가
- `areaBasedList2` 호출 실패(네트워크 오류, API 응답 에러) → `TabiError`로 변환 후 `AppLogger.network` 로깅, 화면에는 에러/재시도 UI 표시
- `KoreanRegion` → `areaCode` 매핑이 없는 케이스 진입 → 컴파일 타임에 매핑 누락이 드러나도록 처리 (switch exhaustiveness 활용), 런타임 옵셔널 강제 언래핑 금지
- 지역 내 관광지/축제 데이터가 0건인 정상 응답 → 에러가 아닌 빈 상태(empty state)로 구분 표시
- 카테고리 탭 빠르게 연속 전환 시 이전 in-flight 요청과 경쟁 상태(race condition) 발생 가능 → TCA `.cancellable(id:)`로 이전 요청 취소 필요

## 무엇에 의존하는가

### 의존성
- `Domain/Sources/UseCase/TouristSpot/TouristSpotUseCaseProtocol.swift` — `areaBasedList2` 호출 메서드 신규 추가 필요 (예: `fetchSpots(areaCode: String, contentType: CategoryType, pageNo: Int)`)
- `Data/Sources/Network/EndPoint/TouristSpotEndpoint.swift` — `areaBasedList2` 케이스 신규 추가
- `Data/Sources/Repository/TouristSpot/TouristSpotRepository.swift` — 신규 메서드 구현체 추가
- `Domain/Sources/Entity/KoreanRegion.swift` / `Projects/Presentation/Sources/Home/Model/KoreanRegion+.swift` — `areaCode` 매핑 추가 (한국관광공사 지역코드: 서울=1, 부산=6, 제주=39 등 공식 값 확인 필요)
- 기존 `FestivalUseCaseProtocol` / `FestivalEndpoint.swift`의 `searchFestival2` — 지역 파라미터로 재사용
- `DesignSystem` 내 기존 리스트/카드/탭 컴포넌트 (신규 컴포넌트 제작 전 재사용 여부 확인 필요 — `swift-style.md` 9번 규칙)
- `Domain/Sources/Dependency/Keys/TouristSpotUseCaseDependencyKey.swift`(testValue) / `App/Sources/Dependency/TouristSpotUseCaseDependencyKey.swift`(liveValue) — 신규 메서드 대응 업데이트

### 제약
- `areaCode` 등 한국관광공사 API 파라미터 값은 추측하지 않고 공식 문서에서 확인 후 사용 (CLAUDE.md 원칙)
- API 키 등 시크릿 하드코딩 금지, 기존 `Secret.xcconfig` 체계 그대로 사용
- 신규 `.swift` 파일 추가 후 `tuist generate` 필요

## Acceptance Criteria
- [x] 홈 화면에서 지역 카드 탭 시 RegionSpot 화면에 해당 지역의 관광지 리스트가 표시된다
- [x] 카테고리 탭 전환 시 선택한 카테고리에 맞는 관광지 리스트로 갱신된다
- [x] 해당 지역에서 진행 중인 축제가 있을 경우 축제 섹션에 노출된다
- [x] API 호출 실패 시 에러 상태가 표시되고 재시도가 가능하다
- [x] 관광지/축제 데이터가 없는 지역은 빈 상태 UI로 구분 표시된다
- [x] 모든 `KoreanRegion` 케이스가 유효한 areaCode로 매핑되어 있다 (`.etc`는 의도적으로 `nil`)

> 코드/빌드 기준 충족. 시뮬레이터 자동 UI 탐색은 이 환경에서 macOS 접근성 권한이 없어 수행하지 못했으므로, 실제 화면 동작은 사용자가 직접 확인 필요.
