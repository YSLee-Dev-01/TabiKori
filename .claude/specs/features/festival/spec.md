# festival

## 무엇을 하는가
홈 화면의 recommendedEventBanner를 탭했을 때 이동하는 화면. 한국관광공사 `searchFestival2` API를 기반으로 날짜(기본: 오늘-30일 ~ 무제한) 범위 내 진행되는 행사/축제 목록을 조회하고, 시/도 단위 지역 필터로 결과를 좁혀볼 수 있게 한다. 사용자가 관심 있는 행사를 발견하고 상세 정보(기존 DetailFeature)로 이동할 수 있게 하는 것이 목적.

## 동작 명세
- 트리거: 홈 화면 recommendedEventBanner 탭 → Festival 화면으로 push 이동
- 결과:
  - 화면 진입 시 상단에 네비게이션 바(뒤로가기 가능), 날짜 범위 선택 뷰(TabiRangeCalendar, 상시 노출, 기본값 오늘-30일 ~ 무제한), 시/도 지역 필터가 표시됨
  - 날짜 박스(시작/종료)를 탭해 편집 대상 필드를 전환하는 방식으로 시작일/종료일을 독립적으로 선택함
  - 하단에 선택된 날짜/지역 조건에 맞는 행사 결과 리스트가 표시됨 (셀: 썸네일 + 제목 + 행사 기간 `M/d ~ M/d`, 종료일이 없으면 `M/d ~`)
  - 날짜 범위를 변경하면 결과 리스트가 즉시 재조회됨
  - 종료일을 선택하지 않은 상태(기본값)에서는 종료일 없이(시작일 이후 전체) 검색되어 장기 행사도 결과에 포함됨
  - 시/도 필터를 선택/해제하면 결과 리스트가 즉시 재조회됨
  - 결과 셀을 탭하면 기존 DetailFeature(상세 화면)로 push 이동
- 사이드이펙트:
  - `searchFestival2` 네트워크 요청 (날짜/지역 조건 변경 시마다). `eventEndDate`는 API상 필수 파라미터가 아니므로 종료일이 없으면 쿼리에서 생략됨
  - 화면 최초 진입 시 `ldongCode2` 네트워크 요청 1회 (시/도 목록 조회)
- 불변 조건:
  - `endDate`가 존재할 때는 항상 `startDate` 이후 또는 같은 날 (TabiRangeCalendar의 기존 규칙을 그대로 따름)
  - `endDate`는 옵셔널이며, 비어 있어도(=종료일 없음) 검색은 정상 동작해야 함
  - 지역 필터 로딩 실패 시에도 날짜 기반 검색 자체는 항상 동작해야 함 (필터는 옵셔널)

## 무엇이 잘못될 수 있는가
- `searchFestival2` 응답 실패(resultCode ≠ "0000") → `TabiError.apiFailed`, 빈 리스트 표시 + `AppLogger.network` 에러 로그
- `ldongCode2` 응답 실패 → 지역 필터 UI는 숨기거나 비활성화하고, 날짜 기반 검색은 계속 진행 (`AppLogger.view` 로그)
- 좌표(mapx/mapy) 파싱 실패 → 상세 이동 시 좌표 기반 기능(지도 등)에 영향 가능, 기존 TouristSpot 파싱 실패 로직과 동일하게 0,0 대체 + 에러 로그
- 행사 시작일(eventstartdate) 파싱 실패 → 해당 항목은 목록에서 제외하고 에러 로그 (종료일 eventenddate는 값이 없거나 파싱 실패해도 항목을 제외하지 않고 "종료일 없음"으로 처리)
- 네트워크 요청 중 화면 이탈/재요청 → 이전 요청은 취소되고 최신 조건 결과만 반영

## 무엇에 의존하는가
### 의존성
- `TouristSpotUseCase`/`TouristSpotRepository`/`TouristSpotEndpoint`/`TouristSpotDTO` — Entity/UseCase/Repository/Endpoint/DTO 계층 구조 패턴 참조
- `CategoryType+.swift`(Data) — `CategoryType.festival` ↔ apiCode `"85"` 매핑 (기존 값 재사용)
- `TabiRangeCalendar`(DesignSystem) — 날짜 범위 선택 UI 그대로 재사용
- `TabiSpotRow`/`TabiCard`(DesignSystem) — 결과 셀 구조 참고, 신규 셀(`TabiFestivalRow` 등)은 행사 기간 표시로 대체
- `TabiNavigationBar` — 푸시 화면 네비게이션 바 패턴 (`PlanDetailView` 참고)
- `StackPath`/`TabBarFeature` — 신규 `.festival` 스택 경로 추가 및 라우팅
- `DetailFeature` — 결과 셀 탭 시 이동할 기존 상세 화면 (Festival → TouristSpot 변환 필요)
- `Secret.tourAPIKey` — 기존 시크릿 재사용, 신규 시크릿 추가 없음

### 제약
- `searchFestival2`가 제공하는 응답 필드 범위 내에서만 정보를 표시 (지역기반 응답 필드 + `eventstartdate`/`eventenddate`)
- `searchFestival2`/`ldongCode2`는 기존 `TouristSpotEndpoint`와 동일하게 `JpnService2` 경로를 사용
- 지역 필터는 시/도(`lDongRegnCd`) 단위까지만 지원, 시군구(`lDongSignguCd`) 단위는 이번 스펙 범위 밖
- `ldongCode2`는 이 레포에 아직 연동되어 있지 않아 신규 Entity/UseCase/Repository/Endpoint를 새로 만들어야 함
- `eventEndDate`는 API 필수 파라미터가 아니므로, "종료일 없음" 상태에서는 쿼리에 포함하지 않음 (클라이언트 측 추가 필터링 로직 불필요)
- Domain은 Data를 참조하지 않음 — 실제 Repository 조립은 App 레이어에서만 수행

## Acceptance Criteria
- [ ] 홈 화면 recommendedEventBanner 탭 시 Festival 화면으로 push 이동한다
- [ ] Festival 화면 진입 시 오늘-30일 ~ 무제한 범위로 `searchFestival2` 결과가 기본 조회된다
- [ ] TabiRangeCalendar로 날짜 범위를 변경하면 목록이 재조회된다
- [ ] 종료일을 선택하지 않으면 종료일 제한 없이 검색되어 장기 행사가 결과에 포함된다
- [ ] 시/도 필터를 선택하면 해당 지역 행사만 필터링되어 조회된다
- [ ] 결과 셀에 썸네일, 제목, 행사 기간(`M/d ~ M/d`, 종료일 없으면 `M/d ~`)이 표시된다
- [ ] 결과 셀 탭 시 기존 DetailFeature로 이동해 상세 정보가 표시된다
- [ ] `searchFestival2`/`ldongCode2` 요청 실패 시 에러가 로그로 남고 화면이 크래시 없이 빈 상태를 보여준다
