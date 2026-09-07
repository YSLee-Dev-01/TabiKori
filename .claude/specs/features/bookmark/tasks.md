# Tasks: bookmark

## 참조
- spec: `.claude/specs/features/bookmark/spec.md`
- plan: `.claude/specs/features/bookmark/plan.md`

## Task 목록

### Phase 1. Resource / Domain 모델

#### [x] Task 1 — `Strings.swift` (수정)
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `public enum Strings` 내부에 `public enum Bookmark {}` 케이스 추가 (`Common`/`Tabbar`/`Home`/`Region`/`Detail`/`Map` 옆)
- `public extension Strings.Bookmark` 블록 추가
  - `static let title = "保存済み"` (화면 타이틀)
  - 저장 개수 포맷: `Strings.Home.festivalRecommendationTitle`(`nonisolated(unsafe) static let ... : ((Int) -> String)`) 패턴 그대로 따라 `static let savedCountTitle: ((Int) -> String) = { "\($0)件のスポットを保存中" }` 정의
  - `Strings.Common.contentTypeAll`("すべて")는 그대로 재사용 — 신규 문자열 추가하지 않음

---

#### [x] Task 2 — `Bookmark.swift` (신규)
**파일**: `Projects/Domain/Sources/Entity/Bookmark.swift`
- `TouristSpot`을 감싸는 도메인 모델 정의: `public struct Bookmark: Equatable, Sendable, Identifiable`
- 프로퍼티: `touristSpot: TouristSpot`(또는 spec/plan 표현대로 `TouristSpot` 필드 유지), `savedAt: Date`
- `id`는 `touristSpot.id`로 위임 (Identifiable 준수, contentId와 동일한 유니크 키)
- `public init(touristSpot: TouristSpot, savedAt: Date)` 정의

---

#### [x] Task 3 — `TabiError.swift` (수정)
**파일**: `Projects/Domain/Sources/Error/TabiError.swift`
- 기존 `case apiFailed(code: String, message: String)`, `case dataNotFound`에 영속성 실패 케이스 추가
- `case persistenceFailed(message: String)` (SwiftData 저장/조회/삭제 실패 표현용, plan 결정 4 참조)

---

### Phase 2. Domain UseCase 계층

#### [x] Task 4 — `BookmarkRepositoryProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/BookmarkRepositoryProtocol.swift`
- `public protocol BookmarkRepositoryProtocol: Sendable` 정의
- 메서드 (plan 결정 5, 모두 async throws):
  - `func fetch() async throws -> [Bookmark]`
  - `func add(_ spot: TouristSpot) async throws`
  - `func remove(contentId: String) async throws`
  - `func isBookmarked(contentId: String) async throws -> Bool`

---

#### [x] Task 5 — `BookmarkUseCaseProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/Bookmark/BookmarkUseCaseProtocol.swift`
- `public protocol BookmarkUseCaseProtocol: Sendable` 정의
- Repository와 동일한 시그니처(fetch/add/remove/isBookmarked, async throws) 노출 — Feature는 UseCase만 의존

---

#### [x] Task 6 — `BookmarkUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/Bookmark/BookmarkUseCase.swift`
- `public struct BookmarkUseCase: BookmarkUseCaseProtocol`
- `private let repository: BookmarkRepositoryProtocol` 주입받는 `public init(repository:)`
- `fetch()` — repository.fetch() 위임, 정렬(예: `savedAt` 내림차순)은 필요 시 여기서 처리
- `add(_ spot:)` — plan 결정 3: 저장 전 `isBookmarked(contentId: spot.id)` 조회 후 이미 존재하면 no-op, 없으면 repository.add 위임 (중복 저장 방지, 불변 조건)
- `remove(contentId:)` — repository.remove 위임 (이미 삭제된 레코드도 에러 없이 no-op은 Repository/Data 레이어 책임, plan 결정 4)
- `isBookmarked(contentId:)` — repository.isBookmarked 위임

---

#### [x] Task 7 — `TestBookmarkUseCase.swift` (신규)
**파일**: `Projects/Domain/Sources/UseCase/Bookmark/TestBookmarkUseCase.swift`
- `test-style.md` 패턴 준수: `public final class TestBookmarkUseCase: BookmarkUseCaseProtocol, @unchecked Sendable`
- 데이터 주입용 `public var bookmarks: [Bookmark] = []` 프로퍼티 공개
- `fetch()` → `self.bookmarks` 반환
- `add(_ spot:)` → `self.bookmarks`에 추가(중복 방지 로직 간단 반영 가능)
- `remove(contentId:)` → `self.bookmarks`에서 제거
- `isBookmarked(contentId:)` → `self.bookmarks`에 해당 id 존재 여부 반환

---

#### [x] Task 8 — `BookmarkUseCaseDependencyKey.swift` (신규, testValue)
**파일**: `Projects/Domain/Sources/Dependency/Keys/BookmarkUseCaseDependencyKey.swift`
- 기존 `SearchHistoryUseCaseDependencyKey.swift`와 동일 패턴 참조
- `public enum BookmarkUseCaseDependencyKey: TestDependencyKey`
- `public static let testValue: BookmarkUseCaseProtocol = TestBookmarkUseCase()`

---

#### [x] Task 9 — `DependencyValues.swift` (수정)
**파일**: `Projects/Domain/Sources/Dependency/DependencyValues.swift`
- 기존 `searchHistoryUseCase` 프로퍼티 옆에 추가:
  ```
  public var bookmarkUseCase: BookmarkUseCaseProtocol {
      get {self[BookmarkUseCaseDependencyKey.self]}
      set {self[BookmarkUseCaseDependencyKey.self] = newValue}
  }
  ```

---

### Phase 3. Data SwiftData 스택

#### [x] Task 10 — `BookmarkModel.swift` (신규)
**파일**: `Projects/Data/Sources/SwiftData/BookmarkModel.swift`
- `import SwiftData`
- `@Model public final class BookmarkModel` 정의 (plan 결정 2 속성안)
  - `contentId: String`(유니크 키), `title: String`, `thumbnailURLString: String?`, `contentTypeRaw: String`, `latitude: Double`, `longitude: Double`, `savedAt: Date`
- `public init(contentId:title:thumbnailURLString:contentTypeRaw:latitude:longitude:savedAt:)` 정의

---

#### [x] Task 11 — `BookmarkModel+.swift` (신규, Domain ↔ Model 매핑)
**파일**: `Projects/Data/Sources/Extension/BookmarkModel+.swift`
- `BookmarkModel` → `Bookmark`(Domain) 변환 (`contentTypeRaw`를 `CategoryType(rawValue:)`로 복원, 실패 시 로깅 후 스킵 또는 기본값 처리)
- `TouristSpot`/`Bookmark` → `BookmarkModel` 변환 헬퍼 (add 시 사용)
- `Data/Sources/Extension/CategoryType+.swift`(기존 DTO 매핑용 확장)와 겹치지 않도록 확인 후 배치

---

#### [x] Task 12 — `BookmarkModelContainer.swift` (신규)
**파일**: `Projects/Data/Sources/SwiftData/BookmarkModelContainer.swift`
- `ModelContainer`를 생성/보관하는 싱글턴 (예: `public final class BookmarkModelContainer`, `public static let shared`)
- `Schema([BookmarkModel.self])` 기반 `ModelContainer` 생성, 실패 시 `AppLogger.core` 로깅 (컨테이너 생성 실패는 앱 치명적 상황이므로 처리 방식 확인 필요)
- `public var modelContext: ModelContext` 노출 (또는 `mainContext` 접근자)

---

#### [x] Task 13 — `BookmarkRepository.swift` (신규)
**파일**: `Projects/Data/Sources/Repository/Bookmark/BookmarkRepository.swift`
- `SearchHistoryRepository`가 `TabiUserDefault.shared`를 주입받는 패턴 참조, `public init(modelContext: ModelContext = BookmarkModelContainer.shared.modelContext)` 형태로 주입 가능하게 설계
- `fetch()` — `#Predicate`/`FetchDescriptor`로 전체 조회, `savedAt` 정렬, `BookmarkModel+` 매핑으로 `[Bookmark]` 반환. 실패 시 `AppLogger.core.log(.error, ...)` 후 `TabiError.persistenceFailed` throw
- `add(_ spot:)` — `BookmarkModel` 생성 후 `modelContext.insert` + `save()`. 실패 시 로깅 후 `TabiError.persistenceFailed` throw
- `remove(contentId:)` — `#Predicate`로 contentId 일치 레코드 조회 후 `modelContext.delete` + `save()`. 대상이 없으면 에러 없이 no-op (spec: 이미 삭제된 레코드 처리)
- `isBookmarked(contentId:)` — `#Predicate`로 존재 여부 조회 후 Bool 반환

**MARK**: `BookmarkRepositoryProtocol` 채택은 별도 `extension BookmarkRepository: BookmarkRepositoryProtocol { ... }`로 분리 (swift-style.md 3번)

---

#### [x] Task 14 — `tuist generate` 반영
- 신규 `.swift` 파일 추가 후 `tuist generate` 실행 (CLAUDE.md IMPORTANT — stale 프로젝트 오탐 방지)
- `Data/Project.swift`의 `hasResource` 변경 불필요 (plan 결정 2: `@Model`은 순수 Swift 코드, 리소스 번들 불필요) — 확인만 하고 실제 변경 없음

---

### Phase 4. App DI 조립

#### [x] Task 15 — `BookmarkUseCaseDependencyKey.swift` (신규, liveValue)
**파일**: `Projects/App/Sources/Dependency/BookmarkUseCaseDependencyKey.swift`
- 기존 `SearchHistoryUseCaseDependencyKey.swift`(App) 패턴 참조
- `extension BookmarkUseCaseDependencyKey: @retroactive DependencyKey`
- `public static let liveValue: BookmarkUseCaseProtocol = BookmarkUseCase(repository: BookmarkRepository())`

---

### Phase 5. DesignSystem 공용 셀

#### [x] Task 16 — `TabiSpotRow.swift` (신규)
**파일**: `Projects/DesignSystem/Sources/Card/TabiSpotRow.swift`
- plan 결정 1: DesignSystem은 Domain을 import할 수 없으므로 primitive 파라미터만 받는 `public struct TabiSpotRow: View` 정의
- 파라미터: `thumbnailURL: URL?`, `japaneseTitle: String`, `koreanTitle: String?`, `tagTitle: String`, `tagColor: TabiColor`, `distance: String?`, `onTap: () -> Void`
- 내부 레이아웃은 `MapView.searchResultRow(_:)`(KFImage 썸네일 64x64 + `TabiLabel`(japaneseTitle bodyMBold, koreanTitle captionM) + `TabiTag` + distance 라벨 + `TabiPressStyle`)를 그대로 이식 — 동작/레이아웃 동일 유지
- Kingfisher(`KFImage`) 의존성이 이미 DesignSystem에서 사용 가능한지 확인 (`Tuist` 의존성 설정, 기존 `Map` 폴더 등에서 사용 여부 확인 후 필요 시 추가)

---

#### [x] Task 17 — `MapView.swift` (수정, `searchResultRow` 위임)
**파일**: `Projects/Presentation/Sources/Map/MapView.swift`
- `func searchResultRow(_ spot: TouristSpot) -> some View` 내부 구현을 `TabiSpotRow` 호출로 교체
  - `thumbnailURL: spot.thumbnailURL`, `japaneseTitle: spot.japaneseTitle`, `koreanTitle: spot.koreanTitle`, `tagTitle: spot.contentType.label`, `tagColor: spot.contentType.color`, `distance: spot.formattedDistance`, `onTap: { self.selectSearchResult(spot) }`
- 기존 동작(탭 시 `selectSearchResult(spot)` 호출, 다음 페이지 로딩 트리거 등 `searchResultList()`의 `.onAppear` 로직)은 변경하지 않음 — 셀 내부 구현만 `TabiSpotRow` 위임으로 교체

---

### Phase 6. Presentation BookmarkFeature

#### [x] Task 18 — `BookmarkFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/Bookmark/BookmarkFeature.swift`
- `@Reducer public struct BookmarkFeature`
- `@Dependency(\.bookmarkUseCase) var bookmarkUseCase`
- **State** (swift-style.md 5번 순서): `bookmarks: [Bookmark] = []`(전체 목록), `selectedCategory: CategoryType? = nil`(필터), `isLoading: Bool = false`
  - computed `filteredBookmarks: [Bookmark]` — `selectedCategory`가 nil이면 전체, 아니면 `touristSpot.contentType` 일치 항목만 반환
  - 저장 개수는 필터와 무관하게 `bookmarks.count` 사용 (plan 결정 7, 불변 조건)
- **Action**: `onAppear`, `categoryFilterTapped(CategoryType?)`, `deleteSwiped(contentId: String)`, `bookmarksResult([Bookmark])`
- **body**: `onAppear` → `bookmarkUseCase.fetch()` 호출 effect → `bookmarksResult` 수신 후 `state.bookmarks` 갱신
  - `categoryFilterTapped` → `state.selectedCategory` 토글(같은 카테고리 재탭 시 전체 해제 등 UX 결정 필요 시 구현 중 확인)
  - `deleteSwiped(contentId:)` → `bookmarkUseCase.remove(contentId:)` effect 호출, 성공 시 `state.bookmarks`에서 즉시 제거(낙관적 갱신) — spec: "삭제 시 목록에서 즉시 제거"
  - 실패 시 `AppLogger.view`/`core` 로깅 (Task 12/13과 동일 원칙)

---

#### [x] Task 19 — `BookmarkView.swift` (신규)
**파일**: `Projects/Presentation/Sources/Bookmark/BookmarkView.swift`
- `public struct BookmarkView: View`, `@State private var store: StoreOf<BookmarkFeature>` 패턴 (기존 View 파일 참조)
- 레이아웃 순서 (spec): `TabiNavigationBar`(타이틀 `Strings.Bookmark.title`) → 카테고리 필터 바(`Sub/BookmarkCategoryFilterBar.swift`, `TabiChip` + `Strings.Common.contentTypeAll` "전체" 칩 포함) → 저장 개수 타이틀(`Strings.Bookmark.savedCountTitle(state.bookmarks.count)`) → `List` + `TabiSpotRow`
- `List`는 plan 결정 6: `.listStyle(.plain)` + separator/배경 숨김, row에 `TabiSpotRow` 배치 + `.swipeActions(edge: .trailing) { Button(role: .destructive) { store.send(.deleteSwiped(contentId:)) } }`
- 빈 상태: `state.bookmarks.isEmpty`일 때 `Sub/BookmarkEmptyState.swift` 표시 (Map의 `searchResultEmptyState()` 패턴 참조)
- `body`가 50줄 초과 시 서브뷰 분리 (swift-style.md 6번)

---

#### [x] Task 20 — `Sub/BookmarkCategoryFilterBar.swift` (신규)
**파일**: `Projects/Presentation/Sources/Bookmark/Sub/BookmarkCategoryFilterBar.swift`
- `CategoryType.allItems` + "전체"(`Strings.Common.contentTypeAll`) 칩을 가로 스크롤로 배치
- 각 칩은 `TabiChip(title, isSelected: selectedCategory == category, action: onSelect)`
- 선택 상태는 `BookmarkFeature.State.selectedCategory`와 바인딩

---

#### [x] Task 21 — `Sub/BookmarkEmptyState.swift` (신규)
**파일**: `Projects/Presentation/Sources/Bookmark/Sub/BookmarkEmptyState.swift`
- `MapView.searchResultEmptyState()` 구조(아이콘 + `TabiLabel` 타이틀/설명, `Spacer` 상하) 참조하여 북마크 빈 상태 전용 문구로 작성
- 문구 필요 시 `Strings.Bookmark`에 추가 (Task 1에서 누락 시 여기서 보완)

---

#### [x] Task 22 — `TabBarFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- `State.PlanState`는 유지, `State.BookmarkState`(placeholder 빈 구조체) 제거
- `var bookmarkState: BookmarkState = .init()` → `var bookmarkState: BookmarkFeature.State = .init()`로 교체
- `Action`에 `case bookmark(BookmarkFeature.Action)` 추가
- `body`에 `Scope(state: \.bookmarkState, action: \.bookmark) { BookmarkFeature() }` 추가
- 필요 시 `case .bookmark(...)`, `case .bookmark:` 분기 추가 (현재 `map`/`home` 처리 패턴 참조 — 북마크 Cell 탭 시 DetailView 이동 등 필요 여부 확인 후 `path.append(.detail(...))` 추가)

---

#### [x] Task 23 — `TabBarView.swift` (수정)
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarView.swift`
- `Text(AppTab.bookmark.title)` placeholder를 `BookmarkView(store: self.store.scope(state: \.bookmarkState, action: \.bookmark))`로 교체
- `.tabItem`/`.tag(AppTab.bookmark)`는 기존 그대로 유지 (MEMORY: tabItem에 텍스트 임의 추가 금지, Image only 유지)

---

### Phase 7. Detail 영속화 연동

#### [x] Task 24 — `DetailFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/Detail/DetailFeature.swift`
- `@Dependency(\.bookmarkUseCase) var bookmarkUseCase` 추가 (기존 `touristSpotUseCase`/`naverMapUseCase` 옆)
- `Action`에 `case isBookmarkedResult(Bool)` 추가 (비동기 결과 수신)
- `.onAppear` 분기에 `isBookmarked(contentId: state.touristSpot.id)` 조회 effect를 `.merge`에 추가, 결과 수신 시 `state.isSaved` 세팅
- `.saveButtonTapped` 분기: 기존 `state.isSaved.toggle()`(메모리 토글)을 제거하고, 현재 `isSaved` 값에 따라 `bookmarkUseCase.add(state.touristSpot)` 또는 `bookmarkUseCase.remove(contentId: state.touristSpot.id)` effect 호출로 교체. 성공 시 `state.isSaved` 갱신(낙관적 갱신 또는 결과 수신 후 갱신 — 구현 중 결정)
- 실패 시 `AppLogger.view.log(.error, ...)` 로깅 (기존 `fetchDetailEffect` 등과 동일한 에러 로깅 패턴)

---

### Phase 8. 빌드/검증

#### [x] Task 25 — 빌드 및 동작 검증
- `tuist generate` 실행 후 `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`(또는 MEMORY 기준 iPhone 17)로 빌드 확인
- 시뮬레이터에서 수동 확인: BookmarkView 진입 시 타이틀/필터/개수/리스트 순서, 필터 칩 강조, 스와이프 삭제, DetailView 하트 저장 후 앱 재실행 시 상태 유지, 저장 개수 정확성

---

## 체크리스트

### 품질 (DoD)
- [ ] 빌드 성공 (`tuist generate` 반영 후)
- [ ] `DependencyInformation` 의존성 방향 위반 없음 (DesignSystem은 Domain 미참조 — `TabiSpotRow`는 primitive 파라미터만 사용)
- [ ] SwiftData 저장/조회/삭제 실패 시 `TabiError.persistenceFailed` + `AppLogger.core` 로깅 처리
- [ ] 테스트 타겟 미구성 상태 — `TestBookmarkUseCase`/`BookmarkUseCaseDependencyKey.testValue`만 우선 정의 (테스트 코드 자체는 작성하지 않음)

### 기능 (AC)
- [ ] BookmarkView 진입 시 타이틀/필터/총 개수/Cell 리스트가 순서대로 표시된다
- [ ] 카테고리 필터 칩을 탭하면 해당 카테고리로 목록이 필터링되고 칩이 강조 표시된다
- [ ] Cell을 오른쪽으로 스와이프하면 삭제할 수 있고, 삭제 시 SwiftData와 목록에서 함께 제거된다
- [ ] DetailView 등에서 하트 버튼을 탭하면 SwiftData에 저장/삭제되며 앱 재실행 후에도 상태가 유지된다
- [ ] 저장 개수 타이틀이 실제 북마크 총 개수와 항상 일치한다 (필터와 무관)
