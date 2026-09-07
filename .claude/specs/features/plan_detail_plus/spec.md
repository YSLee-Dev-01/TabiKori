# plan_detail_plus

## 무엇을 하는가
PlanDetail 화면(일정 상세)의 "+" 버튼(`PlanDetailAddSpotButton`, `addSpotButtonTapped`)을 눌렀을 때 열리는 하단 시트. 현재 선택된 일자(`selectedDayIndex`)에 추가할 관광지를 "관광지 검색" / "즐겨찾기" 두 개 탭 중에서 고르고, 시작·종료 시각을 입력해 해당 날짜의 스팟 목록에 저장한다.

## 동작 명세
- 트리거: `PlanDetailView`에서 `PlanDetailAddSpotButton` 탭 → `PlanDetailFeature`가 `.addSpotButtonTapped` 수신
- 결과:
  - `PlanDetailFeature.State`에 `@Presents var addSpotState: PlanDetailAddSpotFeature.State?` 추가, `.sheet(item:)`으로 표시 (기존 `AddToItineraryFeature`가 `DetailFeature`에서 표시되는 패턴과 동일)
  - 시트는 Step 1(스팟 선택, 탭 2개)과 Step 2(시간 설정)로 구성. 진입 시 `plan`/`selectedDayIndex`가 이미 PlanDetail에서 확정된 상태이므로 `AddToItineraryFeature`와 달리 일정/날짜 선택 단계는 없음
  - **Step 1 — 스팟 선택**: 상단에 "관광지 검색" / "즐겨찾기" 탭 전환 UI
    - "관광지 검색" 탭: `TabiSearchField(text:)`로 키워드 입력 → `touristSpotUseCase.searchByKeyword(keyword:pageNo:)` 호출, 결과를 `TabiSpotRow`(또는 기존 `MapSearchResultRowView`와 동일한 구성) 리스트로 표시
    - "즐겨찾기" 탭: `bookmarkUseCase.fetch()` 결과(`[Bookmark]`)를 리스트로 표시
    - 두 탭 어느 쪽에서든 스팟 행 탭 시 해당 `TouristSpot`을 `selectedSpot`에 저장하고 Step 2로 전환
  - **Step 2 — 시간 설정**: 기존 `AddToItineraryTimeConfigView` + `AddToItineraryTimeForm`을 그대로 재사용 (동일한 시작/종료 시각 입력 UI, 기본 시간대는 `AddToItineraryFeature.makeDefaultTimeRange`와 동일 로직으로 계산 — 해당 일자의 마지막 스팟 종료 시각 이후, 없으면 09:00 시작)
    - 저장 버튼 탭 시 `travelPlanDetailUseCase.add(_:)` 호출 (order는 해당 `dayIndex`의 기존 스팟 개수)
  - 저장 성공(`spotAdded`) 시 시트 닫힘 + `PlanDetailFeature`가 `travelPlanDetail`을 재조회(`fetchTravelPlanDetailEffect`)해 새 스팟이 목록에 즉시 반영됨
- 사이드이펙트:
  - 키워드 검색 시마다 `touristSpotUseCase.searchByKeyword` 네트워크 호출
  - "즐겨찾기" 탭 진입 시 `bookmarkUseCase.fetch()` 호출 (DB 조회)
  - Step 2 진입 시 기본 시간 계산을 위해 `travelPlanDetail`은 PlanDetail이 이미 보유한 값을 그대로 전달받아 사용 (재조회 없음)
  - 저장 시 `travelPlanDetailUseCase.add(_:)` 호출 (SwiftData 저장)
- 불변 조건:
  - Step 2에서 `endTime > startTime`이 아니면 저장 버튼 비활성화 (`AddToItineraryFeature.isSaveEnabled`와 동일 규칙)
  - `dayIndex`는 시트 진입 시 PlanDetail의 `selectedDayIndex`로 고정되며 시트 내에서 변경 불가
  - 저장 실패 시 시트는 닫히지 않고 State는 그대로 유지 (재시도 가능)

## 무엇이 잘못될 수 있는가
- `touristSpotUseCase.searchByKeyword` 실패 → `AppLogger.view.log(.error, ...)` 로깅 후 결과 빈 배열 처리, 검색 결과 없음 UI 노출
- `bookmarkUseCase.fetch()` 실패 → `AppLogger.view.log(.error, ...)` 로깅 후 빈 배열 처리
- `travelPlanDetailUseCase.add(_:)` 실패 → `AppLogger.view.log(.error, ...)` 로깅, `isSaving = false`로 복구, 시트 유지 (기존 `AddToItineraryFeature.saveFailed` 패턴과 동일)
- 검색 키워드가 빈 문자열 → API 호출하지 않고 빈 목록 표시 (또는 이전 결과 유지 — plan 단계에서 확정)

## 무엇에 의존하는가
### 의존성
- `TouristSpotUseCaseProtocol.searchByKeyword(keyword:pageNo:)` (Domain, 기존 재사용 — 신규 메서드 추가 없음)
- `BookmarkUseCaseProtocol.fetch()` (Domain, 기존 재사용)
- `TravelPlanDetailUseCaseProtocol.add(_:)` (Domain, 기존 재사용 — `AddToItineraryFeature.saveEffect`와 동일 사용법)
- `AddToItineraryTimeConfigView` / `AddToItineraryTimeForm` (Presentation/AddToItinerary/Sub, 기존 뷰 그대로 재사용 — 신규 복제 없음, `internal` 접근 수준이라 같은 Presentation 모듈 내에서만 재사용 가능)
- `TabiSearchField` (DesignSystem/SearchField, `text:` 바인딩 init 재사용)
- `TabiSpotRow` (DesignSystem/Card, 검색/즐겨찾기 행 표시에 재사용)
- 신규 탭 전환 UI: 기존 DesignSystem에 세그먼트/탭 컴포넌트 없음 확인 → 이번 화면 전용으로 간단한 탭 UI 신규 제작 (재사용 가능성 낮아 `Presentation/PlanDetailAddSpot/Sub/`에 위치, DesignSystem 승격은 하지 않음)
- 신규 `PlanDetailAddSpotFeature`/`PlanDetailAddSpotView` (Presentation/PlanDetailAddSpot) — `PlanDetailFeature`에 `@Presents`로 연결

### 제약
- `TouristSpotUseCaseProtocol`/`BookmarkUseCaseProtocol`/`TravelPlanDetailUseCaseProtocol`은 변경하지 않는다 (기존 메서드로만 구성)
- `AddToItineraryFeature`/`AddToItineraryView`는 수정하지 않는다 — Step 2 뷰(`AddToItineraryTimeConfigView`, `AddToItineraryTimeForm`)만 새 Feature에서 재사용
- 일정/날짜 선택 UI(`AddToItineraryPlanListView`, `AddToItineraryDayRow`)는 이번 화면에서 사용하지 않는다 (PlanDetail 진입 시점에 이미 plan+day가 확정되어 있으므로)
- 새 `.swift` 파일 추가 시 `tuist generate` 필수

## Acceptance Criteria
> 코드 구현·빌드·정적 리뷰까지 완료. 시뮬레이터 인터랙티브 탭 테스트(접근성 권한/idb 미설치로 자동화 불가)는 미수행 — 아래 항목 중 실제 탭/네비게이션 동작 확인이 필요한 항목은 사용자 수동 확인 필요
- [ ] PlanDetail에서 "+" 버튼 탭 시 하단 시트가 열리고 "관광지 검색"/"즐겨찾기" 탭이 표시된다 (구현 완료, 수동 확인 필요)
- [ ] "관광지 검색" 탭에서 키워드 입력 시 검색 결과가 목록으로 표시된다 (구현 완료, 수동 확인 필요)
- [ ] "즐겨찾기" 탭에서 북마크한 관광지 목록이 표시된다 (구현 완료, 수동 확인 필요)
- [ ] 검색/즐겨찾기 목록에서 스팟 탭 시 시간 설정 화면(Step 2)으로 전환된다 (구현 완료, 수동 확인 필요)
- [ ] 시간 설정 화면에서 시작/종료 시각을 입력하고 저장하면 시트가 닫히고 PlanDetail의 해당 날짜 목록에 새 스팟이 즉시 표시된다 (구현 완료, 수동 확인 필요)
- [ ] 종료 시각이 시작 시각보다 이르거나 같으면 저장 버튼이 비활성화된다 (구현 완료, 수동 확인 필요)
- [ ] 저장 실패 시 시트가 닫히지 않고 에러가 로깅된다 (구현 완료, 수동 확인 필요)
- [x] `tuist generate` 후 빌드 성공 — `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17'` BUILD SUCCEEDED 확인
