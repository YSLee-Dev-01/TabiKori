# Plan: travel_items (툴박스 탭 준비물 마스터 리스트 → 플랜 저장 → PlanDetail 체크리스트)

## 참조 Spec
- @.claude/specs/features/travel_items/spec.md

## 참조 Skill
- 프로젝트에 `create-feature` 스킬 없음 (`.claude/skills/`에는 code-review / commit / feature / prompt만 존재)
- 레퍼런스 패턴:
  - `Data/Repository/ExchangeRate/ExchangeRateRepository.swift` — Firebase Realtime Database 조회 + 스냅샷 파싱 (유일한 RTDB 선례)
  - `Data/Repository/TravelPlanDetail/TravelPlanDetailRepository.swift` — `ModelContext` 기반 SwiftData CRUD + `TabiError.persistenceFailed` 변환
  - `Presentation/AddToItinerary` — `@Presents` + `.sheet(item:)` 로 플랜 목록을 고르고 저장하는 플로우
  - `Presentation/PlanDetailAddSpot` — PlanDetail이 자식 시트를 열고 `.presented(...)` 결과를 받아 재조회하는 연결부
  - `Presentation/Setting` — `AlertState` 확인 후 파괴적 동작(초기화) 실행

---

## 현재 상태 파악

### 신규

**Domain**
- `Projects/Domain/Sources/Entity/TravelItem.swift` — Firebase 마스터 항목. `id: String`(RTDB 키), `order: Int`, `title: String`, `note: String?`
- `Projects/Domain/Sources/Entity/TravelPlanItem.swift` — 플랜에 저장된 사본 1건. `id: UUID`, `planId: UUID`, `order: Int`, `title: String`, `note: String?`, `isChecked: Bool`
- `Projects/Domain/Sources/RepositoryProtocol/TravelItemRepositoryProtocol.swift` — `fetchMasterItems() async throws -> [TravelItem]`
- `Projects/Domain/Sources/RepositoryProtocol/TravelPlanItemRepositoryProtocol.swift` — `fetch(planId:)` / `replace(planId:items:)` / `updateChecked(planId:itemId:isChecked:)`
- `Projects/Domain/Sources/UseCase/TravelItem/TravelItemUseCaseProtocol.swift`
- `Projects/Domain/Sources/UseCase/TravelItem/TravelItemUseCase.swift` — 두 Repository를 함께 주입받는 단일 UseCase
- `Projects/Domain/Sources/UseCase/TravelItem/TestTravelItemUseCase.swift` — `testValue`용 더블
- `Projects/Domain/Sources/Dependency/Keys/TravelItemUseCaseDependencyKey.swift` — `TestDependencyKey` 채택, `testValue`만

**Data**
- `Projects/Data/Sources/SwiftData/TravelPlanItemModel.swift` — `@Model`, `@Attribute(.unique) id: UUID`, `planId: UUID`, `order: Int`, `title: String`, `note: String?`, `isChecked: Bool`
- `Projects/Data/Sources/Extension/TravelPlanItemModel+.swift` — `init(item:)` / `toDomain` (기존 `TravelPlanDetailSpotModel+.swift`와 동일 관례)
- `Projects/Data/Sources/Repository/TravelItem/TravelItemRepository.swift` — Firebase RTDB `TabiKori/travelItems` 조회
- `Projects/Data/Sources/Repository/TravelPlanItem/TravelPlanItemRepository.swift` — SwiftData 영속화

**App**
- `Projects/App/Sources/Dependency/TravelItemUseCaseDependencyKey.swift` — `@retroactive DependencyKey`로 `liveValue` 조립

**Presentation**
- `Projects/Presentation/Sources/TravelItems/TravelItemsFeature.swift` — 툴박스 탭 루트(마스터 리스트) Reducer
- `Projects/Presentation/Sources/TravelItems/TravelItemsView.swift`
- `Projects/Presentation/Sources/TravelItems/Sub/TravelItemRow.swift` — 마스터 항목 행(체크박스 없음, 읽기 전용)
- `Projects/Presentation/Sources/TravelItemsPlanPicker/TravelItemsPlanPickerFeature.swift` — "플랜에 저장" 시트 Reducer (플랜 목록 조회 + 덮어쓰기 확인 + 저장)
- `Projects/Presentation/Sources/TravelItemsPlanPicker/TravelItemsPlanPickerView.swift`
- `Projects/Presentation/Sources/TravelItemsPlanPicker/Sub/TravelItemsPlanPickerRow.swift` — 플랜 1건 행
- `Projects/Presentation/Sources/PlanTravelItems/PlanTravelItemsFeature.swift` — 플랜에 저장된 체크리스트 화면 Reducer
- `Projects/Presentation/Sources/PlanTravelItems/PlanTravelItemsView.swift`
- `Projects/Presentation/Sources/PlanTravelItems/Sub/PlanTravelItemCheckRow.swift` — 체크박스 + 제목 + note 행

**Resource**
- `Strings.Tabbar.toolbox` 1개
- `Strings.TravelItems` enum 신규 (화면 타이틀 / 저장 버튼 / 빈 상태 / 에러 / 덮어쓰기 알림 문구)

### 재사용
- **DesignSystem**: `TabiLabel`, `TabiButton`, `TabiCard`, `TabiEmptyState`(`.fill` / `.card`), `TabiRetryableEmptyState`(Firebase 조회 실패 재시도), `TabiCircleIconButton`(시트 닫기), `TabiPressStyle`, `TabiColor`, `TypographyStyle`, `.tabiRadius*`, `.tabiStandard` / `.tabiFast`
- **Presentation 공용 모델**: `Plan/Entity/PlanSection.swift`, `Plan/Model/TravelPlan+.swift`(`section` / `dayCount` / `displayRegionTitle`) — 플랜 선택 목록의 진행중/예정/지난 그룹핑에 재사용 (`AddToItineraryPlanListView`가 이미 폴더를 넘어 사용 중인 모듈 내부 공용 헬퍼)
- **Domain**: `TravelPlanUseCaseProtocol.fetch()` (플랜 목록), `TabiError.dataNotFound` / `.persistenceFailed`
- **Data**: `TravelPlanModelContainer.shared.modelContainer` (동일 스토어에 신규 모델 합류)
- **Core**: `AppLogger.network`(Firebase 조회 실패), `AppLogger.core`(SwiftData 실패), `AppLogger.view`(Feature 로직 실패)
- **App**: `FirebaseApp.configure()`는 `TabiKoriApp.swift`에 이미 존재 — 추가 초기화 불필요
- **Tuist**: `Data`가 이미 `firebaseDatabase` 외부 의존을 가짐 (`DependencyInformation.swift`) — 의존성 그래프 변경 없음

### 수정
- `Projects/Data/Sources/SwiftData/TravelPlanModelContainer.swift` — `Schema([...])`에 `TravelPlanItemModel.self` 추가
- `Projects/Data/Sources/Repository/TravelPlan/TravelPlanRepository.swift`
  - `remove(planId:)` — 해당 플랜의 `TravelPlanItemModel` 삭제 추가 (고아 데이터 방지)
  - `removeAll()` — `try context.delete(model: TravelPlanItemModel.self)` 추가 (설정 > 데이터 초기화에 자동 반영)
- `Projects/Domain/Sources/Dependency/DependencyValues.swift` — `travelItemUseCase` 프로퍼티 추가
- `Projects/Presentation/Sources/Tabbar/Entity/AppTab.swift` — `case toolbox` 추가 (+ `title` / `systemImage` 분기)
- `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
  - `State`에 `toolboxState: TravelItemsFeature.State`, `Action`에 `case toolbox(TravelItemsFeature.Action)`
  - `Scope(state: \.toolboxState, action: \.toolbox)` 추가
  - `.path(.element(id: _, action: .planDetail(.travelItemsButtonTapped)))` 수신 시 `path.append(.planTravelItems(...))`
- `Projects/Presentation/Sources/Tabbar/TabBarView.swift` — `TabView`에 툴박스 탭 추가, `destination` switch에 `.planTravelItems` 분기 추가
- `Projects/Presentation/Sources/Navigation/StackPath.swift` — `case planTravelItems(PlanTravelItemsFeature)` 추가
- `Projects/Presentation/Sources/PlanDetail/PlanDetailFeature.swift` — `Action`에 `case travelItemsButtonTapped` 추가 (상태 변화 없이 부모가 가로채는 액션, `spotRowTapped`와 동일 성격)
- `Projects/Presentation/Sources/PlanDetail/PlanDetailView.swift` — `dayHeader(plan:)`에서만 헤더에 준비물 버튼 액션을 주입
- `Projects/Presentation/Sources/PlanDetail/Sub/PlanDetailDayHeader.swift` — `onTravelItemsTapped: (() -> Void)? = nil` 옵셔널 파라미터 추가, 값이 있을 때만 우측 버튼 렌더링
- `Projects/Resource/Sources/Strings/Strings.swift` — `Strings` 네임스페이스에 `enum TravelItems {}` 등록 + 문구 extension, `Strings.Tabbar.toolbox` 추가

### 삭제
- 없음
- `TravelPlanDetail` / `TravelPlanDetailSpot` / `TravelPlanDetailRepository` / `TravelPlanDetailUseCase`는 **수정하지 않는다** (아래 결정사항 참조)

---

## 기술적 결정사항

- **준비물은 `TravelPlanDetail`이 아니라 별도 모델 계열로 만든다**: spec의 의존성 목록은 `TravelPlanDetail` 계열을 "확장 대상"으로 적었지만, `TravelPlanDetail`은 `planId` + `spots`(일자·순서 기반 타임라인) 구조이고 준비물은 일자 개념이 없는 플랜 단위 1개 리스트다. `TravelPlanDetail.spots`에 섞으면 `dayIndex` / `startTime` / `coordinate` 같은 필수 필드가 의미 없는 더미로 채워지고, 이미 5곳(`spots(forDay:)`, 지도 마커, 편집 저장, 공유 텍스트, 전체보기)에서 `spots`를 그대로 소비하고 있어 전부 필터를 추가해야 한다. 같은 SwiftData 스토어(`TravelPlanModelContainer`)를 공유하는 **독립 모델 `TravelPlanItemModel`** 로 분리해 기존 일정 로직에 0줄 영향을 준다
- **마스터 조회(Firebase)와 사본 영속화(SwiftData)는 Repository 2개, UseCase 1개**: 저장소 성격이 완전히 달라 Repository는 분리하지만, 화면 관점에서는 "준비물"이라는 한 도메인이므로 `TravelItemUseCase`가 두 Repository를 주입받는다 (`DataResetUseCase`가 3개 Repository를 받는 선례와 동일). DependencyKey / `DependencyValues` 항목이 1개만 늘어난다
- **RTDB 스키마는 `ExchangeRateRepository`와 같은 딕셔너리 직접 파싱 방식**: 프로젝트에 RTDB용 DTO/Decodable 관례가 없고 유일한 선례가 스냅샷을 `[String: Any]`로 캐스팅해 읽는다. 경로와 형태는 아래로 확정한다
  ```
  TabiKori/travelItems
    └─ items
         └─ <key> : { "order": Number, "title": String, "note": String(optional) }
  ```
  - `snapshot.value as? [String: Any]` → `items` 딕셔너리를 순회해 키를 `TravelItem.id`로, `order` 오름차순 정렬
  - `items`가 없거나 비면 `TabiError.dataNotFound`
  - **선행 작업**: Firebase 콘솔에 위 경로/형태로 실제 준비물 데이터를 먼저 입력해야 한다 (코드 외 작업). 필드명(`items` / `order` / `title` / `note`)을 다르게 쓰기로 하면 Repository 파싱만 수정
- **저장 사본은 원본 키를 들고 가지 않는다**: 불변 조건 3(마스터 갱신이 사본에 소급되지 않음)을 구조적으로 보장하려면 사본이 원본을 참조할 이유가 없다. 저장 시점에 `UUID()`를 새로 발급하고 `title` / `note` / `order`를 값 복사한다
- **이미 저장된 플랜에 재저장 (spec 미결 항목 확정) → 덮어쓰기 확인 알림**: 플랜 선택 시 해당 플랜의 저장 여부를 먼저 조회하고, 이미 있으면 `AlertState`로 "기존 목록을 덮어쓸까요?"를 물어 확인한 경우에만 진행한다. 확인 시 Repository의 `replace(planId:items:)`가 기존 항목 전체 삭제 후 삽입하는 단일 트랜잭션으로 처리해 "플랜당 리스트 1개" 불변 조건을 저장소 레벨에서 지킨다. (병합 방식은 체크 상태를 어떻게 승계할지 규칙이 더 필요하고 spec에 근거가 없어 채택하지 않음)
- **"준비물" 버튼은 일자 모드(비-전체보기)의 일자 헤더에만 노출**: `PlanDetailDayHeader`는 일자 모드에서 1회, 전체보기에서는 Section 헤더로 N회 렌더링된다. 옵셔널 액션 파라미터를 두고 일자 모드에서만 주입하면 "플랜당 1회" 불변 조건이 렌더링 구조상 자동으로 보장된다. 전체보기는 이미 편집 진입도 막힌 읽기 전용 조망 모드(`editButtonTapped`가 `isFullOverview == false` 가드)라 액션 진입점이 없는 것이 기존 동작과 일관된다. (전체보기에서도 접근이 필요하다는 판단이 나오면 toolbar 항목 추가가 후속 최소 변경)
- **저장된 체크리스트 화면은 sheet가 아니라 NavigationStack push**: PlanDetail 자체가 `TabBarFeature`의 `path`에 push된 화면이고, 체크리스트는 "잠깐 입력하고 닫는 폼"이 아니라 체류하며 여러 항목을 체크하는 목록이다. `StackPath`에 케이스를 추가하고 `TabBarFeature`가 `.planDetail(.travelItemsButtonTapped)`를 가로채 append하는 기존 관례(`spotRowTapped` → `.detail`)를 그대로 따른다
- **플랜 선택 화면은 sheet**: 툴박스 탭 루트에서 "고르고 즉시 끝나는" 단발 선택이라 `AddToItinerary`와 동일하게 `@Presents` + `.sheet(item:)`. 툴박스 탭도 `TabBarView`의 `NavigationStack` 안에 있어 push도 가능하지만, 저장 후 목록 화면으로 되돌아오는 흐름이 sheet dismiss가 더 자연스럽다
- **툴박스 탭 루트 = 준비물 화면 직결**: spec이 "툴박스의 현재 유일한 기능"이라고 명시했다. 도구 목록을 먼저 보여주는 허브 화면은 항목이 1개인 리스트가 되어 탭이 하나 늘어난 만큼의 이득이 없다. 탭 라벨만 "툴박스", 루트 뷰는 `TravelItemsView`로 두고, 도구가 2개 이상이 되는 시점에 허브 화면을 그 위에 끼우면 `TravelItemsFeature`는 그대로 재사용된다
- **탭 순서는 `bookmark` 다음(마지막)**: `AppTab`은 `CaseIterable`이지만 `TabBarView`가 탭을 하드코딩하므로 열거 순서가 곧 표시 순서는 아니다. 두 곳 모두 마지막에 추가해 기존 4개 탭의 위치와 사용자 근육 기억을 바꾸지 않는다. 아이콘은 SF Symbols `shippingbox`(준비물/짐 함의) 사용 — `TabBarView` 탭은 이미지 전용이며 **텍스트 라벨을 추가하지 않는다**
- **플랜 목록 행은 `AddToItineraryPlanRow`를 재사용하지 않고 새로 만든다**: 그 뷰는 아코디언 펼침 상태(`isExpanded` + chevron 회전)를 전제로 만들어졌고 `AddToItinerary/Sub/`에 있는 화면 전용 뷰다. 준비물 저장은 날짜 선택 없이 플랜 1건만 고르므로 펼침 개념이 없다. `Domain.TravelPlan`을 직접 받는 뷰라 `DesignSystem` 승격도 불가능(DesignSystem은 Domain에 의존하지 않음)하므로, `TabiCard` + `TabiLabel` 조합의 얇은 행을 새 화면 `Sub/`에 만든다
- **체크박스는 DesignSystem에 올리지 않는다**: 체크 UI가 필요한 화면은 `PlanTravelItemsView` 하나뿐이다(마스터 리스트는 읽기 전용). SF Symbols `checkmark.circle.fill` / `circle` + `TabiColor.tabiPrimary` 조합으로 `Sub/PlanTravelItemCheckRow.swift`에 만들고, 두 번째 사용처가 생기면 그때 승격한다
- **체크 토글은 낙관적 갱신 + 실패 시 롤백**: 로컬 SwiftData 쓰기라 지연이 거의 없지만 실패 시 UI와 저장소가 어긋나면 안 된다. State를 먼저 뒤집어 즉시 반응시키고, `updateChecked` 실패 시 해당 항목만 되돌리고 `AppLogger.view`로 로깅한다
- **`TravelPlanRepository`의 삭제 경로에 신규 모델을 함께 정리한다**: 준비물은 `planId`로만 플랜에 묶이는 별도 모델이라 SwiftData의 관계 기반 cascade가 없다. 플랜 삭제(`remove(planId:)`) / 전체 초기화(`removeAll()`)에서 함께 지우지 않으면 삭제된 플랜의 준비물이 스토어에 영구히 남는다. 두 메서드 모두 이미 `TravelPlanDetailModel` / `TravelPlanDetailSpotModel`을 명시적으로 정리하고 있어 같은 자리에 한 줄씩 추가하는 최소 변경이며, 설정 > 데이터 초기화도 자동으로 커버된다 (`DataResetUseCase` 수정 불필요)
- **SwiftData 스키마 변경은 신규 모델 추가뿐**: 기존 3개 모델의 필드를 건드리지 않으므로 SwiftData 경량 마이그레이션 범위 안이며 별도 `VersionedSchema` / `MigrationPlan`을 도입하지 않는다
- **문구는 일본어, 아래 값은 제안값**: 앱 UI 문자열이 전부 일본어이므로 동일하게 작성한다. 실제 표기(특히 탭 라벨 "ツール", 화면 타이틀 "持ち物リスト")는 구현 전 확정 필요
- **에러 표현**: Firebase 조회 실패는 `TabiRetryableEmptyState`(재시도 버튼) + `AppLogger.network`, SwiftData 실패는 `TabiError.persistenceFailed` 변환 + `AppLogger.core`, Feature 레벨 처리 실패는 `AppLogger.view`. 신규 알림 UI는 덮어쓰기 확인 1건만 만든다
- **접근 제어**: Feature / State / Action / `init`은 `public`(TabBarFeature·StackPath에서 참조), View는 기존 화면 관례대로 `TravelItemsView`만 `public`(탭 루트), 나머지 View와 `Sub/`는 `internal`

---

## 구현 순서

### Phase 1. Domain
1. `Entity/TravelItem.swift` — `public struct TravelItem: Equatable, Sendable, Identifiable`, 프로퍼티 `id: String` / `order: Int` / `title: String` / `note: String?`
2. `Entity/TravelPlanItem.swift` — `public struct TravelPlanItem: Equatable, Sendable, Identifiable`, 프로퍼티 `id: UUID` / `planId: UUID` / `order: Int` / `title: String` / `note: String?` / `isChecked: Bool`
3. `RepositoryProtocol/TravelItemRepositoryProtocol.swift` — `fetchMasterItems() async throws -> [TravelItem]`
4. `RepositoryProtocol/TravelPlanItemRepositoryProtocol.swift`
   - `fetch(planId: UUID) async throws -> [TravelPlanItem]`
   - `replace(planId: UUID, items: [TravelPlanItem]) async throws`
   - `updateChecked(planId: UUID, itemId: UUID, isChecked: Bool) async throws`
5. `UseCase/TravelItem/TravelItemUseCaseProtocol.swift` — 위 4개 메서드를 그대로 노출 (`fetchMasterItems` / `fetchSavedItems(planId:)` / `save(planId:items:)` / `updateChecked(planId:itemId:isChecked:)`)
6. `UseCase/TravelItem/TravelItemUseCase.swift`
   - `init(travelItemRepository:travelPlanItemRepository:)`
   - `save(planId:items:)`에서 `[TravelItem]` → `[TravelPlanItem]` 변환(신규 `UUID`, `isChecked: false`, `order` 승계) 후 `replace` 호출 — 변환 책임을 UseCase에 두어 Presentation이 사본 생성 규칙을 모르게 한다
7. `UseCase/TravelItem/TestTravelItemUseCase.swift` — `public final class ... : TravelItemUseCaseProtocol, @unchecked Sendable`, 주입용 `var masterItems: [TravelItem]` / `var savedItems: [TravelPlanItem]`
8. `Dependency/Keys/TravelItemUseCaseDependencyKey.swift` — `TestDependencyKey` 채택, `testValue`만
9. `Dependency/DependencyValues.swift` — `travelItemUseCase` 프로퍼티 추가 (파일 하단, 기존 선언 스타일 유지)

### Phase 2. Data
1. `SwiftData/TravelPlanItemModel.swift` — `@Model final class`, `@Attribute(.unique) var id: UUID`, 나머지 필드는 기본값을 가진 non-optional로 선언 (기존 `TravelPlanDetailSpotModel` 관례)
2. `SwiftData/TravelPlanModelContainer.swift` — `Schema([TravelPlanModel.self, TravelPlanDetailModel.self, TravelPlanDetailSpotModel.self, TravelPlanItemModel.self])`
3. `Extension/TravelPlanItemModel+.swift` — `convenience`가 아닌 `init(item: TravelPlanItem)` + `var toDomain: TravelPlanItem?`
4. `Repository/TravelItem/TravelItemRepository.swift`
   - `public final class TravelItemRepository`, `public init() {}`
   - `extension TravelItemRepository: TravelItemRepositoryProtocol` 로 분리 (스타일 규칙 3번)
   - `Database.database().reference(withPath: "TabiKori/travelItems")` → `getData()` → `items` 파싱 → `order` 정렬
   - 파싱 실패 시 `TabiError.dataNotFound`, 실패 로그는 `AppLogger.network.log(.error, ...)`
5. `Repository/TravelPlanItem/TravelPlanItemRepository.swift`
   - `init(modelContainer: ModelContainer = TravelPlanModelContainer.shared.modelContainer)`
   - `fetch(planId:)` — `FetchDescriptor` + `#Predicate { $0.planId == planId }` + `SortDescriptor(\.order)`
   - `replace(planId:items:)` — 같은 `ModelContext`에서 기존 planId 항목 전체 `delete` 후 신규 `insert`, 마지막에 `save()` 1회
   - `updateChecked(planId:itemId:isChecked:)` — 대상 1건 조회 후 플래그 갱신, 없으면 조용히 return (`removeSpot` 관례)
   - 모든 `catch`에서 `AppLogger.core` 로깅 + `TabiError.persistenceFailed(message:)` 변환
6. `Repository/TravelPlan/TravelPlanRepository.swift`
   - `remove(planId:)` — `TravelPlanItemModel` planId 매칭분 삭제 추가
   - `removeAll()` — `try context.delete(model: TravelPlanItemModel.self)` 추가

### Phase 3. App (DI 조립)
1. `App/Sources/Dependency/TravelItemUseCaseDependencyKey.swift`
   - `extension TravelItemUseCaseDependencyKey: @retroactive DependencyKey`
   - `liveValue = TravelItemUseCase(travelItemRepository: TravelItemRepository(), travelPlanItemRepository: TravelPlanItemRepository())`

### Phase 4. Resource
1. `Strings.swift`의 `public enum Strings` 블록에 `public enum TravelItems {}` 추가
2. `Strings.Tabbar`에 `toolbox` 추가 (제안값 `"ツール"`)
3. `public extension Strings.TravelItems` 신설 — 각 항목에 한국어 주석 (기존 파일 관례)
   - 마스터 화면: `title`(제안 `"持ち物リスト"`), `saveToPlanButton`(제안 `"旅程に保存"`)
   - 마스터 로드 실패: `loadFailedDescription`
   - 플랜 선택 시트: `planPickerTitle`, `planPickerEmptyTitle` / `planPickerEmptyDescription`(플랜 0건)
   - 덮어쓰기 알림: `overwriteAlertTitle` / `overwriteAlertMessage` / `overwriteAlertConfirm`(취소는 `Strings.Common` 기존 항목 확인 후 없으면 추가)
   - 저장 완료/실패: `saveFailedDescription`
   - PlanDetail 진입 버튼: `planDetailEntryTitle`(접근성 라벨용)
   - 저장된 체크리스트 화면: `savedEmptyTitle` / `savedEmptyDescription`(아직 저장 안 된 플랜), `checkedCountTitle(_:_:)`(예: 완료 n/m)
   - 재시도 버튼은 `Strings.RegionSpot.retryButtonTitle`을 쓰는 `TabiRetryableEmptyState` 내부 처리라 신규 정의 불필요

### Phase 5. Presentation — 툴박스 탭 + 준비물 마스터 화면
1. `TravelItems/TravelItemsFeature.swift`
   - `@Dependency(\.travelItemUseCase)`
   - `State`: `items: [TravelItem] = []`, `isLoading: Bool = false`, `hasLoadFailed: Bool = false`, `fileprivate var hasStartedLoading: Bool = false`, `@Presents var planPickerState: TravelItemsPlanPickerFeature.State?`
   - `Action`: `onAppear`, `retryButtonTapped`, `saveToPlanButtonTapped`, `masterItemsResult([TravelItem])`, `masterItemsFailed`, `planPicker(PresentationAction<...>)`
   - `.onAppear` — `hasStartedLoading` 가드(`PlanDetailFeature` 관례) 후 조회 Effect, `.retryButtonTapped`은 가드 없이 재조회 + `cancellable(id:cancelInFlight: true)`
   - `.saveToPlanButtonTapped` — `items.isEmpty == false` 가드 후 `planPickerState = .init(items: state.items)`
   - `.planPicker(.presented(.savedToPlan))` — 시트 닫기(`planPickerState = nil`)
   - body 마지막에 `.ifLet(\.$planPickerState, action: \.planPicker) { TravelItemsPlanPickerFeature() }`
   - `private extension`에 `fetchMasterItemsEffect()` (실패 시 `AppLogger.view` 로깅 + `masterItemsFailed`)
2. `TravelItems/Sub/TravelItemRow.swift` — `title` + `note`(있을 때만) 2줄, `TabiCard` 또는 구분선 목록 중 기존 목록 화면과 동일한 시각 언어 선택
3. `TravelItems/TravelItemsView.swift`
   - `@Bindable private var store`, `public init(store:)`
   - 상태 3분기: 로딩 `ProgressView` / 실패 `TabiRetryableEmptyState(description:onRetry:)` / 성공 `List`(`.plain`, 구분선·배경 제거)
   - 하단 고정 `TabiButton(Strings.TravelItems.saveToPlanButton, style: .primary, isExpanded: true)` — 로딩·실패 상태에서는 비활성
   - `.sheet(item: self.$store.scope(state: \.planPickerState, action: \.planPicker))`
   - `.navigationTitle(Strings.TravelItems.title)` + `.navigationBarTitleDisplayMode(.inline)` (탭 루트가 `TabBarView`의 `NavigationStack` 안이므로 자체 스택 생성 금지)
   - `#Preview` — `TestTravelItemUseCase.masterItems` 주입
4. `Tabbar/Entity/AppTab.swift` — `case toolbox` + `title`/`systemImage`(`"shippingbox"`) 분기
5. `Tabbar/TabBarFeature.swift` — `toolboxState` / `toolbox` 액션 / `Scope` 추가, `case .toolbox: return .none` 기본 처리
6. `Tabbar/TabBarView.swift` — `TravelItemsView(...)`를 `.tabItem { Image(systemName: AppTab.toolbox.systemImage) }` + `.tag(AppTab.toolbox)`로 마지막에 추가 (**Label/Text 추가 금지**)

### Phase 6. Presentation — 플랜 선택 시트 (저장 확정)
1. `TravelItemsPlanPicker/TravelItemsPlanPickerFeature.swift`
   - `@Dependency(\.travelPlanUseCase)`, `@Dependency(\.travelItemUseCase)`, `@Dependency(\.dismiss)`
   - `State`: `let items: [TravelItem]`, `plans: [TravelPlan] = []`, `isLoading: Bool = false`, `isSaving: Bool = false`, `@Presents var alert: AlertState<Action.Alert>?`
   - `Action`: `onAppear`, `closeButtonTapped`, `planRowTapped(TravelPlan)`, `plansResult([TravelPlan])`, `existingItemsResult(plan: TravelPlan, hasSaved: Bool)`, `saveFailed`, `savedToPlan`, `alert(PresentationAction<Alert>)` / `enum Alert { case overwriteConfirmed(TravelPlan) }`
   - `.onAppear` — `travelPlanUseCase.fetch()`
   - `.planRowTapped` — `isSaving == false` 가드 후 해당 플랜의 저장 여부 조회 Effect
   - `.existingItemsResult` — 저장분 없으면 즉시 저장 Effect, 있으면 `alert = AlertState { 덮어쓰기 확인 }`
   - `.alert(.presented(.overwriteConfirmed(plan)))` — 저장 Effect
   - 저장 Effect — `travelItemUseCase.save(planId:items:)` → 성공 `savedToPlan` / 실패 `AppLogger.view` + `saveFailed`
   - `.savedToPlan` — `.run { await dismiss() }` (부모도 `planPickerState = nil` 처리하므로 sheet 상태가 확실히 정리됨)
   - body: `Reduce` → `.ifLet(\.$alert, action: \.alert)`
2. `TravelItemsPlanPicker/Sub/TravelItemsPlanPickerRow.swift` — `plan` + `onTap`, 제목 · `displayRegionTitle` · 기간 표시, `TabiPressStyle` 적용
3. `TravelItemsPlanPicker/TravelItemsPlanPickerView.swift`
   - 헤더: 타이틀 + `TabiCircleIconButton`(닫기) — `AddCustomPlace`/`PlanDetailAddSpot` 헤더와 동일 배치
   - 본문 3분기: 로딩 `ProgressView` / 플랜 0건 `TabiEmptyState(systemImageName:title:description:)` / 목록은 `PlanSection`(진행중·예정·지난) 그룹 헤더 + 행
   - 저장 중에는 목록 `disabled` + `ProgressView` 오버레이 (`AddToItineraryPlanListView` 관례)
   - `.alert($store.scope(state: \.alert, action: \.alert))`
   - `.presentationDetents([.medium, .large])` + `.presentationDragIndicator(.visible)`

### Phase 7. Presentation — PlanDetail 연결 + 저장된 체크리스트 화면
1. `PlanTravelItems/PlanTravelItemsFeature.swift`
   - `@Dependency(\.travelItemUseCase)`
   - `State`: `let plan: TravelPlan`, `items: [TravelPlanItem] = []`, `isLoading: Bool = false`, `fileprivate var hasStartedLoading: Bool = false`
   - 계산 프로퍼티 `checkedCount` / `isEmpty`
   - `Action`: `onAppear`, `itemTapped(id: UUID)`, `savedItemsResult([TravelPlanItem])`, `checkUpdateFailed(id: UUID, previous: Bool)`
   - `.itemTapped` — State에서 즉시 토글(낙관적) 후 `updateChecked` Effect, 실패 시 `checkUpdateFailed`로 원복 + `AppLogger.view`
   - `public init(plan:)` (StackPath에서 생성)
2. `PlanTravelItems/Sub/PlanTravelItemCheckRow.swift` — `item` + `onTap`, 체크 아이콘 `.tabiFast` 애니메이션, 체크 시 제목 색상 `tabiTextTertiary`
3. `PlanTravelItems/PlanTravelItemsView.swift`
   - 로딩 `ProgressView` / 저장분 0건 `TabiEmptyState(.fill)`(`savedEmpty*`) / 목록 `List(.plain)`
   - `.navigationTitle(Strings.TravelItems.title)`, 진행률(`checkedCountTitle`)은 서브타이틀 또는 목록 상단 라벨로 표시
   - `#Preview` — `TestTravelItemUseCase.savedItems` 주입
4. `Navigation/StackPath.swift` — `case planTravelItems(PlanTravelItemsFeature)` 추가
5. `PlanDetail/Sub/PlanDetailDayHeader.swift` — `let onTravelItemsTapped: (() -> Void)?`(기본값 `nil`) 추가, 존재할 때만 `Spacer()` + 우측 버튼(아이콘 + 라벨, `TabiPressStyle`) 렌더링. 기존 호출부(전체보기 Section 헤더)는 파라미터를 넘기지 않아 무변경
6. `PlanDetail/PlanDetailFeature.swift` — `Action`에 `case travelItemsButtonTapped` 추가, `Reduce`에서 `.none` 반환(부모가 가로챔)
7. `PlanDetail/PlanDetailView.swift` — `dayHeader(plan:)`의 `PlanDetailDayHeader`에만 `onTravelItemsTapped: { self.store.send(.travelItemsButtonTapped) }` 주입
8. `Tabbar/TabBarFeature.swift` — `case .path(.element(id: _, action: .planDetail(.travelItemsButtonTapped)))`에서 해당 `planDetail` state의 `plan`을 꺼내 `path.append(.planTravelItems(PlanTravelItemsFeature.State(plan: plan)))` (`photoCellTapped` 케이스처럼 `state.path[id: id]` 패턴 매칭으로 plan 획득)
9. `Tabbar/TabBarView.swift` — `destination` switch에 `case .planTravelItems(let store): PlanTravelItemsView(store: store)` 추가

### Phase 8. 빌드 / 검증
1. Firebase 콘솔에 `TabiKori/travelItems` 데이터 입력 (Phase 4 이전에 해두면 Phase 5 검증이 수월)
2. `tuist install && tuist generate` — 신규 `.swift` 약 18개 추가이므로 필수
3. `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`
4. 시나리오 확인
   - 툴박스 탭 → 마스터 리스트 로드 / 기내모드에서 재시도 빈 상태
   - "플랜에 저장" → 플랜 0건 빈 상태 / 플랜 선택 → 저장 → 시트 닫힘
   - 같은 플랜에 재저장 → 덮어쓰기 알림 → 확인 시 1개 리스트 유지
   - PlanDetail 일자 헤더 버튼 1회 노출, 전체보기 전환 시 중복 노출 없음
   - 체크 토글 → 앱 강제 종료 후 재실행에도 상태 유지
   - 준비물 미저장 플랜에서 버튼 탭 → 빈 상태
   - 플랜 삭제 / 설정 > 데이터 초기화 후 해당 준비물도 사라지는지 확인

---

## 완료 조건
- [ ] Spec Acceptance Criteria 충족
- [ ] 툴박스 탭이 기존 4개 탭 뒤에 노출되고(이미지 전용 `tabItem`), 진입 시 준비물 마스터 리스트가 보인다
- [ ] Firebase RTDB `TabiKori/travelItems` 조회 결과가 `order` 순으로 표시되고, 실패 시 재시도 가능한 에러 상태가 표시되며 `AppLogger.network` 로그가 남는다
- [ ] "플랜에 저장" → 플랜 선택 → 저장 시 `TravelPlanItemModel`에 사본이 영속화되고 시트가 닫힌다
- [ ] 플랜이 0건이면 플랜 선택 시트에 빈 상태가 표시된다
- [ ] 이미 저장된 플랜을 다시 선택하면 덮어쓰기 확인 알림이 뜨고, 확인 시에도 해당 플랜의 준비물 리스트는 1개만 유지된다
- [ ] PlanDetail 일자 헤더에 "준비물" 버튼이 플랜당 1회만 노출되고, 전체보기 목록에서는 반복 노출되지 않는다
- [ ] 버튼 탭 시 체크리스트 화면으로 push되고, 항목 체크/해제가 즉시 반영·영속화되며 앱 재시작 후에도 유지된다
- [ ] 준비물 미저장 플랜에서는 체크리스트 화면에 빈 상태가 표시된다
- [ ] 플랜 삭제 및 설정 > 데이터 초기화 시 해당 준비물 데이터도 함께 제거된다
- [ ] `TravelPlanDetail` / `TravelPlanDetailSpot` 및 기존 일정 로직에 변경이 없다
- [ ] `tuist generate` 후 빌드 성공
