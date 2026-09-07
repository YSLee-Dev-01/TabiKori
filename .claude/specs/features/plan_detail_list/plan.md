# Plan: plan_detail_list (일정 상세 - 선택 Day 스팟 목록 + 스와이프 삭제)

## 참조 Spec
- @.claude/specs/features/plan_detail_list/spec.md

## 참조 Skill
- 프로젝트에 `create-feature` 스킬 없음. 선행 기능 `@.claude/specs/features/plan_detail/plan.md`가 만든 `PlanDetail` 계층(Entity → RepositoryProtocol → UseCase → testValue/liveValue)을 그대로 확장한다
- 레퍼런스 패턴: `Bookmark`(SwiftData 삭제 + Repository 에러 매핑), `Plan`(빈 상태 컴포넌트 / fetch Effect), `Detail`(Mock + Preview)

---

## 현재 상태 파악

### 신규

**Domain**
- `Projects/Domain/Sources/Entity/TravelPlanDetailSpot.swift`
  - `id: UUID`, `dayIndex: Int`(0-based), `order: Int`, `category: CategoryType`, `title: String`, `subtitle: String?`, `startTime: Date`, `durationMinutes: Int`
  - `Equatable, Sendable, Identifiable`

**Data**
- `Projects/Data/Sources/SwiftData/TravelPlanDetailSpotModel.swift`
  - `@Relationship` 없이 `planId: UUID` 평면 참조 (`TravelPlanDetailModel`과 동일 방침)
  - `@Attribute(.unique) var id: UUID`, `planId`, `dayIndex`, `order`, `category: String`(rawValue 저장), `title`, `subtitle: String?`, `startTime: Date`, `durationMinutes: Int`
- `Projects/Data/Sources/Extension/TravelPlanDetailSpotModel+.swift`
  - `var toDomain: TravelPlanDetailSpot?` (category rawValue 파싱 실패 대비) / `convenience init(spot:planId:)`

**Presentation**
- `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailSpotEmptyState.swift` — 점선 테두리 빈 상태 카드
- `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailSpotRow.swift` — 시간 + 타임라인 dot/선 + 카드 1행
- `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailDayHeader.swift` — 캘린더 아이콘 + "M月d日（E）" + 스팟 개수 안내 (spec 파일 목록에는 없지만 `PlanDetailView` body 50줄 규칙을 지키려면 분리 필요)
- `Projects/Presentation/Sources/PlanDetail/Model/TravelPlanDetailSpot+.swift` — `startTimeTitle`("HH:mm"), `durationTitle`
- `Projects/Presentation/Sources/PlanDetail/PlanDetailMock.swift` — Preview용 `TravelPlan.mock` / `TravelPlanDetail.mock` (`DetailMock.swift` 패턴)

### 재사용
- **DesignSystem**: `TabiCard`(스팟 카드), `TabiTag`(카테고리 태그), `TabiLabel`, `TabiColor`(tabiSurface / tabiBorder / tabiTextPrimary / tabiTextSecondary / tabiTextTertiary / category*), `.tabiRadiusLg`, `.tabiRadiusMd`
- **Presentation**: `CategoryType+.swift`의 `icon` / `color` / `label` — 그대로 사용, 카테고리 추가 없음
- **Presentation**: `Plan/Model/TravelPlan+.swift`의 `dayCount`, `dayDates` — Day 헤더 날짜 산출에 재사용
- **Domain/Data**: `TravelPlanDetailRepository`, `TravelPlanModelContainer.shared.modelContainer` — 신규 컨테이너 만들지 않음
- **App**: `Projects/App/Sources/Dependency/TravelPlanDetailUseCaseDependencyKey.swift` — **변경 없음** (프로토콜에 메서드가 늘어도 `liveValue` 조립식은 동일)
- **Core**: `AppLogger.view`(Feature) / `AppLogger.core`(Repository)
- **Domain**: `TabiError.persistenceFailed`

### 수정
- `Projects/Domain/Sources/Entity/TravelPlanDetail.swift`
  - `public let spots: [TravelPlanDetailSpot]` 추가. `init(planId: UUID, spots: [TravelPlanDetailSpot] = [])`로 기본값 제공 → 기존 `TravelPlanDetail(planId:)` 호출부(`TravelPlanDetailModel+.swift`, `TestTravelPlanDetailUseCase`) 무변경 컴파일
- `Projects/Domain/Sources/RepositoryProtocol/TravelPlanDetailRepositoryProtocol.swift` — `func removeSpot(planId: UUID, spotId: UUID) async throws` 추가
- `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCaseProtocol.swift` — 동일 시그니처 추가
- `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCase.swift` — Repository 위임 1메서드 추가
- `Projects/Domain/Sources/UseCase/TravelPlanDetail/TestTravelPlanDetailUseCase.swift` — `removeSpot` 구현 추가 (기존 `public var details` 재사용, 해당 planId의 detail에서 spot 제거)
- `Projects/Data/Sources/SwiftData/TravelPlanModelContainer.swift` — `Schema([TravelPlanModel.self, TravelPlanDetailModel.self, TravelPlanDetailSpotModel.self])`
- `Projects/Data/Sources/Extension/TravelPlanDetailModel+.swift` — `toDomain` 프로퍼티 → `func toDomain(spots:)` 형태로 변경 (스팟을 함께 주입해 매핑)
- `Projects/Data/Sources/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift`
  - `fetch(planId:)`: 스팟 모델까지 조회해 `dayIndex` → `order` 정렬 후 매핑
  - `removeSpot(planId:spotId:)` 신규 구현 (`BookmarkRepository.remove(contentId:)` 패턴: 조회 → 없으면 조용히 return → `context.delete` → `save`)
- `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift`
  - Action에 `spotDeleteButtonTapped(id: UUID)`, `spotDeleted(id: UUID)` 추가
  - State에 선택 Day 스팟 계산 프로퍼티 추가, 삭제 성공 시에만 `travelPlanDetail?.spots`에서 제거
- `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift` — 기존 `Spacer()` 자리를 Day 헤더 / 지도(EmptyView) / 스팟 리스트로 교체
- `Projects/Presentation/Sources/Extension/Date+.swift` — `planDayHeaderTitle`("M月d日（E）", 전각 괄호) 추가
- `Projects/Resource/Sources/Strings/Strings.swift`의 `Strings.Plan` — 빈 상태 제목/설명, 스팟 개수 안내 문자열 추가

### 삭제
- 없음
- `Strings.Plan.totalSpotCountFixed`("合計 0スポット")는 `PlanCardView`(일정 목록 카드)가 사용 중인 별개 문구다. 이번 화면(상세 Day 헤더)과 표시 위치·의미가 다르므로 재사용하지 않고 그대로 둔다

---

## 기술적 결정사항

- **스팟 리스트는 `ScrollView`가 아닌 `List`로 구현**: spec은 "리스트만 스크롤" + "`.swipeActions(edge: .trailing)`으로만 삭제 제공"을 동시에 요구하는데, `.swipeActions`는 `List` 행에서만 동작하는 modifier다. `ScrollView`로 만들면 스와이프 제스처를 직접 구현해야 하고(spec이 금지한 삭제 버튼 UI를 손으로 그리게 됨), `List`를 쓰면 두 요구를 모두 만족한다. `List` 자체가 스크롤 컨테이너이므로 "헤더/지도는 스크롤 밖" 요구도 그대로 충족된다
- **`List` 기본 크롬 제거**: `.listStyle(.plain)` + `.listRowSeparator(.hidden)` + `.listRowBackground(Color.clear)` + `.listRowInsets(EdgeInsets())` + `.scrollContentBackground(.hidden)`으로 기존 화면들의 시각 언어(구분선 없는 카드 나열)에 맞춘다
- **빈 상태 카드도 `List` 안의 행으로 배치**: 헤더/지도 아래 영역을 한 컨테이너로 유지해야 Day 전환 시 레이아웃 점프가 없다. 빈 상태 행에는 `.swipeActions`를 붙이지 않는다
- **빈 상태 카드는 `TabiCard`를 쓰지 않고 직접 제작**: `TabiCard`는 `RoundedRectangle.stroke(tabiBorder.opacity(0.4))` 실선 테두리를 내부에 고정으로 갖는다. 위에 점선 overlay를 덧대면 실선+점선이 겹쳐 보인다. spec이 요구하는 건 점선 단독이므로 `RoundedRectangle(cornerRadius: .tabiRadiusLg).stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))`로 별도 구성한다 (`HomeView`에 이미 dash 스트로크 선례 있음). 스팟 카드 쪽은 `TabiCard` 그대로 재사용
- **타임라인 세로선은 각 행이 자기 구간만 그린다**: 행 사이를 관통하는 단일 선을 그리려면 전체 높이를 알아야 해서 `List`와 궁합이 나쁘다. 각 `PlanDetailSpotRow`가 dot 위/아래 세로선 세그먼트를 그리고, 첫 행은 위쪽, 마지막 행은 아래쪽 세그먼트를 숨겨(`isFirst` / `isLast` 파라미터) 연속된 하나의 선처럼 보이게 한다
- **dot 색상은 `CategoryType.color` 재사용**: 새 색 토큰을 만들지 않는다 (`swift-style.md` 8번)
- **삭제는 낙관적 업데이트 없이 결과 수신 후 반영**: spec 명시. `spotDeleteButtonTapped(id:)`는 State를 건드리지 않고 Effect만 반환, 성공 시 `spotDeleted(id:)`에서 `spots`를 필터링한다. 실패 시에는 아무 Action도 보내지 않고 `AppLogger.view.log(.error, ...)`만 남긴다 (재시도 UI 없음)
- **`removeSpot`은 존재하지 않는 `spotId`에 대해 에러를 던지지 않는다**: `BookmarkRepository.remove(contentId:)`와 동일하게 `guard let model = ... else { return }`. 이미 삭제된 항목 재탭이 에러 알림으로 이어지지 않게 한다
- **`removeSpot`은 `planId`와 `spotId`를 함께 조건으로 조회**: `spotId`만으로도 유일하지만, 다른 일정의 스팟을 실수로 지우는 경로를 구조적으로 차단한다
- **SwiftData에 `CategoryType`을 `String` rawValue로 저장**: `BookmarkModel` 등 기존 모델과 동일한 방식. enum을 직접 저장하면 케이스 추가/이름 변경 시 스토어 마이그레이션 리스크가 생긴다. 파싱 실패 시 `toDomain`이 `nil`을 반환하고 Repository에서 `compactMap`으로 제외한다 (`TravelPlanModel.toDomain`의 region 파싱 실패 처리와 동일한 감각)
- **`TravelPlanDetailSpot`은 별도 Repository/UseCase를 만들지 않고 `TravelPlanDetail` 계층에 흡수**: 스팟은 항상 특정 `planId`의 상세에 종속되며 단독 조회 유스케이스가 없다. 별도 계층을 만들면 Domain/Data/App/Test 4곳이 추가로 늘어난다
- **정렬·필터는 Repository(1차)와 Presentation(2차) 양쪽에서 보장**: Repository는 `SortDescriptor(dayIndex)` + `SortDescriptor(order)`로 정렬해 반환하고, Presentation State의 계산 프로퍼티가 `dayIndex == selectedDayIndex` 필터 + `order` 오름차순 정렬을 한 번 더 적용한다. spec의 불변 조건("항상 필터+정렬 상태로 렌더링")을 저장소 구현에 의존하지 않고 화면 레벨에서 확정하기 위함
- **선택 Day 스팟 산출은 새 파일 없이 `PlanDetailFeature.State`의 계산 프로퍼티로 배치**: `selectedDayIndex`와 `travelPlanDetail` 두 State에만 의존하는 파생값이라 State 밖으로 뺄 이유가 없다. `Model/TravelPlanDetailSpot+.swift`에는 spec이 명시한 표시용 포맷(`startTimeTitle`, `durationTitle`)만 둔다
- **`planDayHeaderTitle`은 기존 `homeDateTitle`("M月d日(E)")과 별도 프로퍼티**: 괄호가 반각/전각으로 달라 재사용 불가. `Date+.swift`의 기존 `ja_JP` `DateFormatter` 패턴을 따른다
- **지도 자리는 실제 `EmptyView()`**: spec 제약. `EmptyView()`는 공간을 차지하지 않으므로 헤더 바로 아래에 리스트가 붙는다. 자리를 비워두는 `Spacer`나 placeholder 박스를 넣으면 다음 지도 기능 착수 시 제거 대상 죽은 코드가 된다
- **드래그 핸들(⠿) / 휴지통 아이콘 미구현**: spec 제약. `.swipeActions`의 기본 `Button(role: .destructive)` 라벨 텍스트만 사용
- **`TravelPlanDetail`의 `spots`를 `let` + 기본값 `[]`으로 추가**: 기존 `init(planId:)` 호출부를 건드리지 않으면서 값 타입 불변성을 유지한다. 삭제 반영 시에는 Feature에서 새 `TravelPlanDetail`을 만들어 State에 재할당한다
- **App 레이어 DI 파일은 손대지 않음**: `TravelPlanDetailUseCaseDependencyKey`의 `liveValue`가 이미 `TravelPlanDetailUseCase(repository: TravelPlanDetailRepository())`로 조립돼 있어 프로토콜 메서드 추가만으로 자동 반영된다

---

## 구현 순서

### Phase 1. Domain

1. `Projects/Domain/Sources/Entity/TravelPlanDetailSpot.swift` 신규
   - `public struct TravelPlanDetailSpot: Equatable, Sendable, Identifiable`
   - 프로퍼티: `id`, `planId`는 두지 않음(상위 `TravelPlanDetail`이 이미 보유), `dayIndex`, `order`, `category`, `title`, `subtitle`, `startTime`, `durationMinutes`
   - `public init` 전부 노출 (Data 매핑 / Presentation Mock에서 생성)
2. `Projects/Domain/Sources/Entity/TravelPlanDetail.swift` 수정
   - `public let spots: [TravelPlanDetailSpot]` 추가
   - `init(planId: UUID, spots: [TravelPlanDetailSpot] = [])`
3. `Projects/Domain/Sources/RepositoryProtocol/TravelPlanDetailRepositoryProtocol.swift` 수정
   - `func removeSpot(planId: UUID, spotId: UUID) async throws` 추가
4. `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCaseProtocol.swift` 수정 — 동일 시그니처 추가
5. `Projects/Domain/Sources/UseCase/TravelPlanDetail/TravelPlanDetailUseCase.swift` 수정 — Repository 위임 구현
6. `Projects/Domain/Sources/UseCase/TravelPlanDetail/TestTravelPlanDetailUseCase.swift` 수정
   - `removeSpot(planId:spotId:)`: `details`에서 해당 planId 항목을 찾아 `spots`에서 `spotId` 제거한 새 값으로 교체
   - 기존 `public var details` 시그니처 유지

### Phase 2. Data

1. `Projects/Data/Sources/SwiftData/TravelPlanDetailSpotModel.swift` 신규
   - `@Model final class`, internal 접근 (`TravelPlanDetailModel`과 동일)
   - `@Attribute(.unique) var id: UUID`, `var planId: UUID`, `var dayIndex: Int`, `var order: Int`, `var category: String`, `var title: String`, `var subtitle: String?`, `var startTime: Date`, `var durationMinutes: Int`
2. `Projects/Data/Sources/SwiftData/TravelPlanModelContainer.swift` 수정
   - `Schema`에 `TravelPlanDetailSpotModel.self` 추가
3. `Projects/Data/Sources/Extension/TravelPlanDetailSpotModel+.swift` 신규
   - `var toDomain: TravelPlanDetailSpot?` — `CategoryType(rawValue:)` 실패 시 `AppLogger.core.log(.error, ...)` 후 `nil`
   - `convenience init(spot: TravelPlanDetailSpot, planId: UUID)`
4. `Projects/Data/Sources/Extension/TravelPlanDetailModel+.swift` 수정
   - `toDomain` 프로퍼티를 `func toDomain(spots: [TravelPlanDetailSpot]) -> TravelPlanDetail`로 변경
   - `convenience init(detail:)`은 그대로 (스팟은 별도 모델로 저장)
5. `Projects/Data/Sources/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift` 수정
   - `fetch(planId:)`: 기존 `TravelPlanDetailModel` 조회 → 있으면 `FetchDescriptor<TravelPlanDetailSpotModel>(predicate: #Predicate { $0.planId == planId }, sortBy: [SortDescriptor(\.dayIndex), SortDescriptor(\.order)])` 조회 → `compactMap { $0.toDomain }` → `model.toDomain(spots:)` 반환
   - `removeSpot(planId:spotId:)` 신규: 두 조건 `#Predicate` 조회 → `first`가 없으면 return → `context.delete` → `context.save()`, catch에서 `AppLogger.core` + `TabiError.persistenceFailed`
   - `add(_:)`는 변경하지 않음 (스팟 생성은 이번 범위 밖)

### Phase 3. Resource / Presentation 확장

1. `Projects/Resource/Sources/Strings/Strings.swift`의 `public extension Strings.Plan`에 추가
   - 빈 상태 제목: "まだスポットがありません"
   - 빈 상태 설명: "観光地や飲食店の詳細ページから「日程に追加する」で追加できます"
   - 스팟 0건 안내: "スポットがまだ追加されていません"
   - 스팟 N건 안내: `nonisolated(unsafe) static let ...: ((Int) -> String)` 형태로 "N件のスポットが追加されています" (기존 `durationBadge` / `dayChipTitle` 패턴)
   - 소요시간 포맷(분 단위)도 여기에 정의 — 기존 `Strings`에 해당 문구 없음 확인 완료
   - 네이밍은 기존 `emptyTitle` / `emptyDescription`(일정 목록용)과 충돌하지 않게 `spot` 접두 사용
2. `Projects/Presentation/Sources/Extension/Date+.swift` 수정
   - `var planDayHeaderTitle: String` — `ja_JP` + `"M月d日（E）"`(전각 괄호)
   - `var planSpotTimeTitle: String` — `"HH:mm"` (`TravelPlanDetailSpot+`에서 사용, Date 포맷은 Date 확장에 모아둔다)
3. `Projects/Presentation/Sources/PlanDetail/Model/TravelPlanDetailSpot+.swift` 신규
   - `var startTimeTitle: String` → `self.startTime.planSpotTimeTitle`
   - `var durationTitle: String` → `durationMinutes`를 Strings 포맷으로 변환
   - internal 접근

### Phase 4. Presentation - Feature

1. `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift` 수정
   - **State**
     - 기존 프로퍼티 유지 (`id`, `plan`, `travelPlanDetail`, `selectedDayIndex`, `isLoading`, `hasStartedLoading`)
     - 계산 프로퍼티 `var selectedDaySpots: [TravelPlanDetailSpot]` 추가 — `travelPlanDetail?.spots`에서 `dayIndex == selectedDayIndex` 필터 + `order` 오름차순 정렬, `nil`이면 `[]`
   - **Action** (선언 순서 규칙: 생명주기 → 인터랙션 → 비동기 결과)
     - 기존 `onAppear`, `dayButtonTapped(index:)` 유지
     - `case spotDeleteButtonTapped(id: UUID)` 추가 (인터랙션 구간, `dayButtonTapped` 다음)
     - `case spotDeleted(id: UUID)` 추가 (비동기 결과 구간, 기존 결과 케이스 다음)
   - **body**
     - `spotDeleteButtonTapped(let id)`: State 변경 없이 `self.removeSpotEffect(planId: state.id, spotId: id)` 반환
     - `spotDeleted(let id)`: `state.travelPlanDetail`이 있으면 `spots`에서 `id` 제거한 새 `TravelPlanDetail`로 재할당
   - **Method (`private extension`)**
     - `removeSpotEffect(planId:spotId:)`: `.run { [travelPlanDetailUseCase = self.travelPlanDetailUseCase] send in ... }` → 성공 시 `send(.spotDeleted(id: spotId))`, `catch`에서 `AppLogger.view.log(.error, ...)`만 수행하고 Action 미발송
   - 파일 상단 헤더 주석을 "선택된 날짜의 스팟 목록 표시 + 스와이프 삭제"까지 포함하도록 갱신

### Phase 5. Presentation - Sub 컴포넌트 / View / Mock

1. `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailDayHeader.swift` 신규
   - 입력: `dateTitle: String`, `spotCountTitle: String`
   - `HStack`: `Image(systemName: "calendar")` + `VStack`(날짜 `bodyMBold` / 개수 안내 `captionM`, `tabiTextSecondary`)
2. `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailSpotEmptyState.swift` 신규
   - `VStack`: `Image(systemName: "calendar")`(tabiTextTertiary) + 제목(`bodySBold`, `tabiTextSecondary`) + 설명(`captionM`, `tabiTextTertiary`, `alignment: .center`)
   - 점선 테두리: `RoundedRectangle(cornerRadius: .tabiRadiusLg).stroke(TabiColor.tabiBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))` overlay
   - `PlanEmptyState`의 구성/토큰을 최대한 따라간다
3. `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailSpotRow.swift` 신규
   - 입력: `spot: TravelPlanDetailSpot`, `isFirst: Bool`, `isLast: Bool`
   - 레이아웃: `HStack(alignment: .top)` — ① 시간 라벨(`startTimeTitle`, `captionMBold`, 고정 폭) ② 타임라인 컬럼(`VStack`: 위 세그먼트 / `Circle()` dot(`spot.category.color`) / 아래 세그먼트, 세그먼트는 `isFirst`/`isLast`로 숨김) ③ `TabiCard { VStack(alignment: .leading) { TabiTag(spot.category.label, color: spot.category.color); 제목(`bodyMBold`); 부제(옵셔널, `captionM`, `tabiTextSecondary`); 소요시간(`durationTitle`, `captionM`, `tabiTextTertiary`) } }`
   - 탭 액션 없음 (spec 범위 밖) — `Button`으로 감싸지 않는다
4. `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift` 수정
   - 기존 `Spacer()` → `self.dayHeader(plan: plan)` + `EmptyView()`(지도 자리, 주석으로 후속 기능임을 명시) + `self.spotList()`
   - `spotList()`: `List` + `.listStyle(.plain)` + 행별 `.listRowSeparator(.hidden)` / `.listRowBackground(Color.clear)` / `.listRowInsets(EdgeInsets(...))` + `.scrollContentBackground(.hidden)`
     - `store.selectedDaySpots.isEmpty`이면 `PlanDetailSpotEmptyState()` 단일 행
     - 아니면 `ForEach(Array(store.selectedDaySpots.enumerated()), id: \.element.id)`로 `PlanDetailSpotRow(spot:isFirst:isLast:)` 배치 + `.swipeActions(edge: .trailing, allowsFullSwipe: false) { Button(role: .destructive) { store.send(.spotDeleteButtonTapped(id: spot.id)) } label: { Text(삭제 문구) } }`
   - Day 헤더 날짜는 `plan.dayDates[safe: store.selectedDayIndex]` 대신 인덱스 범위 확인 후 접근 (강제 언래핑 금지)
   - `body` 50줄 초과 시 기존 `private extension` View 메서드로 계속 분리
   - `.toolbar` / `.navigationBarBackButtonHidden(true)` / `.interactivePopGestureEnabled(true)` / `.onAppear` 기존 유지
5. `Projects/Presentation/Sources/PlanDetail/PlanDetailMock.swift` 신규
   - `extension TravelPlan { static let mock }`, `extension TravelPlanDetail { static let mock }`(Day 0/1에 걸친 스팟 3~4개)
   - `PlanDetailView`에 `#Preview` 추가 — `withDependencies`로 `TestTravelPlanUseCase.plans` / `TestTravelPlanDetailUseCase.details` 주입, `PlanDetailFeature.State(id:)`에 mock과 **동일한 id** 전달

### Phase 6. 프로젝트 생성 및 빌드 검증

1. `tuist generate` — 신규 파일 7개(Domain 1 / Data 2 / Presentation 4)가 Domain·Data·Presentation 3개 타겟에 걸쳐 추가되므로 **필수**
2. `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`
3. 시뮬레이터 수동 확인
   - Plan 탭 → 일정 셀 탭 → 상세 진입 → Day 헤더/빈 상태 카드 표시 확인
   - Day pill 전환 시 헤더 날짜/개수 갱신 확인
   - 스팟이 있는 상태는 Preview로 확인 (아래 리스크 참조)

---

## 리스크 / 확인 필요

- **실기기/시뮬레이터에서는 스팟 목록이 항상 비어 있다**: 현재 `TravelPlanDetailModel`을 생성(`add`)하는 플로우가 어디에도 없고, 스팟 생성 기능도 spec 범위 밖이다. 따라서 `fetch(planId:)`는 계속 `nil`을 반환하고 빈 상태 카드만 보인다. 스팟 로우/타임라인/스와이프 삭제의 시각 검증은 **Preview(Mock) 경로로만 가능**하다 — 이 상태를 수용할지 확인 필요
- **`.swipeActions`는 `List` 전용 modifier**: spec 본문은 "리스트만 `ScrollView` 안"이라고 표현했지만, 스와이프 삭제를 네이티브로 쓰려면 `List`여야 한다. `List` 채택으로 "리스트만 스크롤" 요구 자체는 충족되지만 spec 문구와 컨테이너 종류가 다르다 — 착수 전 합의 필요
- **`TravelPlanDetailSpot` 필드 타입이 spec에 명시돼 있지 않다**: 본 plan은 `subtitle: String?`(옵셔널), `startTime: Date`, `durationMinutes: Int`(둘 다 non-optional)로 가정했다. 시간 미지정 스팟이나 소요시간 미입력을 허용해야 한다면 옵셔널로 바꾸고 View 분기가 추가돼야 한다 — **확인 필요**
- **SwiftData Schema 변경(엔티티 추가) 마이그레이션**: `TravelPlanModelContainer`에 새 모델을 추가하면 기존 스토어와 스키마가 달라진다. 새 엔티티 추가는 통상 lightweight migration 대상이지만 실패 시 컨테이너 생성이 실패하고 in-memory 폴백으로 떨어져 **기존 일정 데이터가 사라진 것처럼 보인다**. 기기 실행 전 앱 삭제 후 재설치로 확인하고, 로그(`TravelPlanModelContainer 생성 실패`)를 반드시 확인할 것
- **`TravelPlanDetailModel+.toDomain` 시그니처 변경의 파급**: 현재 호출부는 `TravelPlanDetailRepository.fetch(planId:)` 한 곳뿐이라 안전하지만, 프로퍼티 → 메서드 전환이므로 빌드 에러로 즉시 드러난다
- **`Action`에 `UUID` 페이로드 추가와 `Equatable`**: `UUID`는 `Equatable`이므로 `StackPath.Action: Equatable` 합성에 문제 없으나 빌드로 확인
- **`List` 내부 `TabiCard` 배경과 `List` 기본 배경 충돌**: `.scrollContentBackground(.hidden)`을 빠뜨리면 카드 뒤에 시스템 회색 배경이 남는다. Day 헤더/지도 영역과의 배경 연속성도 함께 확인
- **타임라인 세로선 이음새**: `List` 행 간 간격(`listRowInsets` / 행 spacing)이 남으면 세그먼트가 끊겨 보인다. 행 인셋의 세로 값을 0으로 두고 카드 내부 padding으로 간격을 만드는 방식이 안전하다
- **`selectedDayIndex` 범위**: `planResult` 수신 시 클램프 로직이 이미 있으나, Day 헤더가 `plan.dayDates[selectedDayIndex]`에 접근하므로 인덱스 범위 체크 없이 접근하면 크래시 가능 — View 단에서 방어 필요
- **`tuist generate` 누락 시** 신규 7개 파일이 "Cannot find ... in scope" 오탐을 낸다

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
- [ ] 선택 Day에 스팟이 없으면 점선 테두리 빈 상태 카드가 표시된다 (`travelPlanDetail == nil`인 경우 포함, 크래시 없음)
- [ ] 스팟이 있으면 "HH:mm" + 카테고리 색 dot/세로선 + 카드(태그/제목/부제/소요시간) 로우가 `order` 순으로 표시된다 (Preview로 검증)
- [ ] Day pill 전환 시 헤더 날짜("M月d日（E）")·스팟 개수 안내·리스트가 해당 Day 기준으로 갱신된다
- [ ] Day 헤더와 지도 자리는 리스트 스크롤과 무관하게 고정된다
- [ ] 스와이프 → 삭제 탭 시 SwiftData 레코드가 지워지고, 재진입(재조회) 시에도 복원되지 않는다
- [ ] `removeSpot` 실패 시 `AppLogger.view`에만 로그가 남고 화면 State는 유지된다
- [ ] 존재하지 않는 `spotId` 삭제 시도 시 에러 없이 조용히 종료된다
- [ ] 지도 자리에 `EmptyView()` 외 어떤 placeholder UI도 추가되지 않았다
- [ ] 드래그 핸들·휴지통 아이콘 UI가 없다
- [ ] `AddTravelPlanFeature` 및 `TravelPlanUseCaseProtocol`/`TravelPlanRepositoryProtocol`에 변경이 없다
- [ ] App 레이어 DI 파일(`TravelPlanDetailUseCaseDependencyKey`)에 변경이 없다
- [ ] `tuist generate` 후 AppDebug 스킴 빌드 성공
