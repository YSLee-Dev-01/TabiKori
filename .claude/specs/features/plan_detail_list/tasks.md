# Tasks: plan_detail_list

## 참조
- spec: `.claude/specs/features/plan_detail_list/spec.md`
- plan: `.claude/specs/features/plan_detail_list/plan.md`

## Task 목록

### Phase 1. Domain

#### [x] Task 1 — `TravelPlanDetailSpot.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/TravelPlanDetailSpot.swift`
- `public struct TravelPlanDetailSpot: Equatable, Sendable, Identifiable` 선언
- 프로퍼티: `id: UUID`, `dayIndex: Int`(0-based), `order: Int`, `category: CategoryType`, `title: String`, `subtitle: String?`, `startTime: Date`, `durationMinutes: Int`
- `planId`는 두지 않음(상위 `TravelPlanDetail`이 이미 보유)
- 모든 프로퍼티를 초기화 가능하도록 `public init` 전부 노출 (Data 매핑 / Presentation Mock에서 생성)

---

#### [x] Task 2 — `TravelPlanDetail.swift` (수정)
**파일**: `Projects/Domain/Sources/Entity/TravelPlanDetail.swift`
- `public let spots: [TravelPlanDetailSpot]` 프로퍼티 추가
- `init(planId: UUID, spots: [TravelPlanDetailSpot] = [])`로 기본값 제공
- 기존 `TravelPlanDetail(planId:)` 호출부(`TravelPlanDetailModel+.swift`, `TestTravelPlanDetailUseCase`)가 무변경으로 컴파일되는지 확인

---

#### [x] Task 3 — `TravelPlanDetailRepositoryProtocol.swift` (수정)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/TravelPlanDetailRepositoryProtocol.swift`
- `func removeSpot(planId: UUID, spotId: UUID) async throws` 시그니처 추가

---

#### [x] Task 4 — `TravelPlanDetailUseCaseProtocol.swift` (수정)
**파일**: `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCaseProtocol.swift`
- `func removeSpot(planId: UUID, spotId: UUID) async throws` 동일 시그니처 추가

---

#### [x] Task 5 — `TravelPlanDetailUseCase.swift` (수정)
**파일**: `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCase.swift`
- `removeSpot(planId:spotId:)` 구현 — Repository로 위임하는 1메서드 추가

---

#### [x] Task 6 — `TestTravelPlanDetailUseCase.swift` (수정)
**파일**: `Projects/Domain/Sources/UseCase/TravelPlanDetail/TestTravelPlanDetailUseCase.swift`
- `removeSpot(planId:spotId:)` 구현 추가 — 기존 `public var details` 재사용, 해당 `planId`의 detail을 찾아 `spots`에서 `spotId` 제거한 새 값으로 교체
- 기존 `public var details` 시그니처는 그대로 유지

---

### Phase 2. Data

#### [x] Task 7 — `TravelPlanDetailSpotModel.swift` (신규)
**파일**: `Projects/Data/Sources/SwiftData/TravelPlanDetailSpotModel.swift`
- `@Model final class`, internal 접근 (`TravelPlanDetailModel`과 동일 방침)
- `@Relationship` 없이 `planId: UUID` 평면 참조
- 프로퍼티: `@Attribute(.unique) var id: UUID`, `var planId: UUID`, `var dayIndex: Int`, `var order: Int`, `var category: String`(rawValue 저장), `var title: String`, `var subtitle: String?`, `var startTime: Date`, `var durationMinutes: Int`

---

#### [x] Task 8 — `TravelPlanModelContainer.swift` (수정)
**파일**: `Projects/Data/Sources/SwiftData/TravelPlanModelContainer.swift`
- `Schema`에 `TravelPlanDetailSpotModel.self` 추가 — `Schema([TravelPlanModel.self, TravelPlanDetailModel.self, TravelPlanDetailSpotModel.self])`

---

#### [x] Task 9 — `TravelPlanDetailSpotModel+.swift` (신규)
**파일**: `Projects/Data/Sources/Extension/TravelPlanDetailSpotModel+.swift`
- `var toDomain: TravelPlanDetailSpot?` — `CategoryType(rawValue:)` 파싱 실패 시 `AppLogger.core.log(.error, ...)` 후 `nil` 반환
- `convenience init(spot: TravelPlanDetailSpot, planId: UUID)` 추가

---

#### [x] Task 10 — `TravelPlanDetailModel+.swift` (수정)
**파일**: `Projects/Data/Sources/Extension/TravelPlanDetailModel+.swift`
- 기존 `toDomain` 프로퍼티를 `func toDomain(spots: [TravelPlanDetailSpot]) -> TravelPlanDetail`로 변경(프로퍼티 → 메서드 전환)
- `convenience init(detail:)`은 변경 없음 (스팟은 별도 모델로 저장)

---

#### [x] Task 11 — `TravelPlanDetailRepository.swift` (수정)
**파일**: `Projects/Data/Sources/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift`
- `fetch(planId:)` 수정: 기존 `TravelPlanDetailModel` 조회 → 있으면 `FetchDescriptor<TravelPlanDetailSpotModel>(predicate: #Predicate { $0.planId == planId }, sortBy: [SortDescriptor(\.dayIndex), SortDescriptor(\.order)])`로 스팟 조회 → `compactMap { $0.toDomain }` → `model.toDomain(spots:)` 반환
- `removeSpot(planId:spotId:)` 신규 구현: `planId`+`spotId` 두 조건 `#Predicate` 조회 → `first`가 없으면 조용히 `return`(에러 throw 없음) → `context.delete` → `context.save()`, catch에서 `AppLogger.core.log(.error, ...)` + `TabiError.persistenceFailed` throw (`BookmarkRepository.remove(contentId:)` 패턴 참고)
- `add(_:)`는 변경하지 않음 (스팟 생성은 이번 범위 밖)

---

### Phase 3. Resource / Presentation 확장

#### [x] Task 12 — `Strings.swift` (수정)
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `public extension Strings.Plan`에 추가
  - 빈 상태 제목: "まだスポットがありません"
  - 빈 상태 설명: "観光地や飲食店の詳細ページから「日程に追加する」で追加できます"
  - 스팟 0건 안내: "スポットがまだ追加されていません"
  - 스팟 N건 안내: `nonisolated(unsafe) static let ...: ((Int) -> String)` 형태로 "N件のスポットが追加されています" (기존 `durationBadge` / `dayChipTitle` 패턴 참고)
  - 소요시간(분 단위) 포맷 문구 추가
- 네이밍은 기존 `emptyTitle` / `emptyDescription`(일정 목록용)과 충돌하지 않게 `spot` 접두 사용

---

#### [x] Task 13 — `Date+.swift` (수정)
**파일**: `Projects/Presentation/Sources/Extension/Date+.swift`
- `var planDayHeaderTitle: String` 추가 — `ja_JP` locale + `"M月d日（E）"`(전각 괄호) 포맷, 기존 `ja_JP` `DateFormatter` 패턴 따름
- `var planSpotTimeTitle: String` 추가 — `"HH:mm"` 포맷 (`TravelPlanDetailSpot+`에서 사용)

---

#### [x] Task 14 — `TravelPlanDetailSpot+.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetail/Model/TravelPlanDetailSpot+.swift`
- `var startTimeTitle: String` → `self.startTime.planSpotTimeTitle` 위임
- `var durationTitle: String` → `durationMinutes`를 Strings 포맷으로 변환
- internal 접근

---

### Phase 4. Presentation - Feature

#### [x] Task 15 — `PlanDetailFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift`
- **State**
  - 기존 프로퍼티 유지 (`id`, `plan`, `travelPlanDetail`, `selectedDayIndex`, `isLoading`, `hasStartedLoading`)
  - 계산 프로퍼티 `var selectedDaySpots: [TravelPlanDetailSpot]` 추가 — `travelPlanDetail?.spots`에서 `dayIndex == selectedDayIndex` 필터 + `order` 오름차순 정렬, `travelPlanDetail`이 `nil`이면 `[]`
- **Action** (선언 순서: 생명주기 → 인터랙션 → 비동기 결과)
  - 기존 `onAppear`, `dayButtonTapped(index:)` 유지
  - `case spotDeleteButtonTapped(id: UUID)` 추가 (인터랙션 구간, `dayButtonTapped` 다음)
  - `case spotDeleted(id: UUID)` 추가 (비동기 결과 구간, 기존 결과 케이스 다음)
- **body**
  - `spotDeleteButtonTapped(let id)`: State 변경 없이 `removeSpotEffect(planId: state.id, spotId: id)` Effect 반환
  - `spotDeleted(let id)`: `state.travelPlanDetail`이 있으면 `spots`에서 `id` 제거한 새 `TravelPlanDetail`로 재할당
- **Method (`private extension`)**
  - `removeSpotEffect(planId:spotId:)`: `.run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in ... }` → 성공 시 `send(.spotDeleted(id: spotId))`, `catch`에서 `AppLogger.view.log(.error, ...)`만 수행하고 Action은 보내지 않음
- 파일 상단 헤더 주석을 "선택된 날짜의 스팟 목록 표시 + 스와이프 삭제"까지 포함하도록 갱신

---

### Phase 5. Presentation - Sub 컴포넌트 / View / Mock

#### [x] Task 16 — `PlanDetailDayHeader.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailDayHeader.swift`
- 입력 파라미터: `dateTitle: String`, `spotCountTitle: String`
- 레이아웃: `HStack` — `Image(systemName: "calendar")` + `VStack`(날짜 `bodyMBold` / 개수 안내 `captionM`, `tabiTextSecondary`)
- `PlanDetailView` `body` 50줄 규칙을 지키기 위해 별도 분리(spec 파일 목록에는 없으나 plan에서 필요성 명시)

---

#### [x] Task 17 — `PlanDetailSpotEmptyState.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailSpotEmptyState.swift`
- `VStack`: `Image(systemName: "calendar")`(`tabiTextTertiary`) + 제목(`bodySBold`, `tabiTextSecondary`, "まだスポットがありません") + 설명(`captionM`, `tabiTextTertiary`, `alignment: .center`, "観光地や飲食店の詳細ページから「日程に追加する」で追加できます")
- 점선 테두리: `RoundedRectangle(cornerRadius: .tabiRadiusLg).stroke(TabiColor.tabiBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))` overlay로 구성
- `TabiCard`는 사용하지 않음 (실선 테두리와 점선이 겹쳐 보이는 문제 방지) — `PlanEmptyState`의 구성/토큰을 최대한 따라감

---

#### [x] Task 18 — `PlanDetailSpotRow.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailSpotRow.swift`
- 입력 파라미터: `spot: TravelPlanDetailSpot`, `isFirst: Bool`, `isLast: Bool`
- 레이아웃: `HStack(alignment: .top)`
  - ① 시간 라벨(`startTimeTitle`, `captionMBold`, 고정 폭)
  - ② 타임라인 컬럼(`VStack`: 위 세그먼트 / `Circle()` dot(`spot.category.color`) / 아래 세그먼트) — 세그먼트는 `isFirst`/`isLast`로 각각 숨겨 연속된 하나의 선처럼 보이게 함
  - ③ `TabiCard { VStack(alignment: .leading) { TabiTag(spot.category.label, color: spot.category.color); 제목(bodyMBold); 부제(옵셔널, captionM, tabiTextSecondary); 소요시간(durationTitle, captionM, tabiTextTertiary) } }`
- 탭 액션 없음(spec 범위 밖) — `Button`으로 감싸지 않음

---

#### [x] Task 19 — `PlanDetailView.swift` (수정)
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift`
- 기존 `Spacer()` 자리를 `dayHeader(plan:)` + `EmptyView()`(지도 자리, 후속 기능임을 주석으로 명시) + `spotList()`로 교체
- `spotList()`: `List` + `.listStyle(.plain)` + 행별 `.listRowSeparator(.hidden)` / `.listRowBackground(Color.clear)` / `.listRowInsets(EdgeInsets(...))` + `.scrollContentBackground(.hidden)`
  - `store.selectedDaySpots.isEmpty`이면 `PlanDetailSpotEmptyState()` 단일 행 (`.swipeActions` 미부착)
  - 아니면 `ForEach(Array(store.selectedDaySpots.enumerated()), id: \.element.id)`로 `PlanDetailSpotRow(spot:isFirst:isLast:)` 배치 + `.swipeActions(edge: .trailing, allowsFullSwipe: false) { Button(role: .destructive) { store.send(.spotDeleteButtonTapped(id: spot.id)) } label: { Text(삭제 문구) } }`
- Day 헤더 날짜는 `plan.dayDates`에 강제 언래핑 없이 인덱스 범위 확인 후 접근
- `body` 50줄 초과 시 기존 `private extension` View 메서드로 계속 분리
- `.toolbar` / `.navigationBarBackButtonHidden(true)` / `.interactivePopGestureEnabled(true)` / `.onAppear` 기존 로직은 유지

---

#### [x] Task 20 — `PlanDetailMock.swift` (신규)
**파일**: `Projects/Presentation/Sources/PlanDetail/PlanDetailMock.swift`
- `extension TravelPlan { static let mock }` 추가
- `extension TravelPlanDetail { static let mock }` 추가 (Day 0/1에 걸친 스팟 3~4개, `DetailMock.swift` 패턴 참고)
- `PlanDetailView`에 `#Preview` 추가 — `withDependencies`로 `TestTravelPlanUseCase.plans` / `TestTravelPlanDetailUseCase.details` 주입, `PlanDetailFeature.State(id:)`에 mock과 **동일한 id** 전달

---

### Phase 6. 프로젝트 생성 및 빌드 검증

#### [x] Task 21 — `tuist generate`
**파일**: 없음 (프로젝트 생성 명령)
- 신규 파일 7개(Domain 1 / Data 2 / Presentation 4)가 Domain·Data·Presentation 3개 타겟에 걸쳐 추가되므로 `tuist generate` 필수 실행
- 누락 시 "Cannot find ... in scope" 오탐 발생 가능

---

#### [x] Task 22 — 빌드 검증
**파일**: 없음 (빌드 명령)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 실행
- BUILD SUCCEEDED 확인

---

#### [ ] Task 23 — 시뮬레이터/Preview 수동 확인
**파일**: 없음 (수동 검증)
- Plan 탭 → 일정 셀 탭 → 상세 진입 → Day 헤더/빈 상태 카드 표시 확인
- Day pill 전환 시 헤더 날짜/개수 안내 갱신 확인
- 스팟이 있는 상태(타임라인/카드/스와이프 삭제)는 Preview(Mock)로 시각 검증 — 실기기에서는 스팟 생성 플로우가 없어 항상 빈 상태로만 보임(plan 리스크 항목 참고)

---

## 체크리스트

### 품질 (DoD)
- [x] `tuist generate` 후 AppDebug 스킴 빌드 성공 (BUILD SUCCEEDED)
- [x] `TravelPlanDetailModel+.toDomain` 시그니처 변경(프로퍼티 → 메서드)이 호출부(`TravelPlanDetailRepository.fetch(planId:)`) 한 곳에 정상 반영됨
- [x] `AddTravelPlanFeature`, `TravelPlanUseCaseProtocol`/`TravelPlanRepositoryProtocol`에 변경 없음
- [x] App 레이어 DI 파일(`TravelPlanDetailUseCaseDependencyKey`)에 변경 없음
- [x] 테스트 타겟 미구성 상태이므로 별도 테스트 실행 없음 (`.claude/CLAUDE.md` 참조)

### 기능 (AC)
- [x] 선택된 Day에 스팟이 없으면 점선 테두리의 빈 상태 카드("まだスポットがありません")가 표시된다
- [x] 선택된 Day에 스팟이 있으면 시간+타임라인+카드 형태의 로우가 `order` 순으로 표시된다
- [x] Day 탭 버튼 전환 시 해당 Day의 스팟만 필터링되어 표시된다
- [x] 지도(EmptyView) 영역은 리스트를 스크롤해도 함께 움직이지 않는다(헤더/지도 고정, 리스트만 스크롤)
- [x] 스팟 카드를 오른쪽에서 왼쪽으로 스와이프 → 삭제 버튼 탭 → 카드가 사라지고 SwiftData에서도 삭제되어 재조회 시 복원되지 않는다
- [x] `removeSpot` 실패 시 크래시 없이 `AppLogger.view`로 로깅만 되고 화면은 그대로 유지된다
- [x] 존재하지 않는 `spotId` 삭제 시도 시 에러 없이 조용히 종료된다
- [x] 지도 자리에 `EmptyView()` 외 어떤 placeholder UI도 추가되지 않았다
- [x] 드래그 핸들(⠿)·휴지통 아이콘 UI가 없다
