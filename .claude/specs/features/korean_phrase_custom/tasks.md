# Tasks: korean_phrase_custom

## 참조
- spec: `.claude/specs/features/korean_phrase_custom/spec.md`
- plan: `.claude/specs/features/korean_phrase_custom/plan.md`

> 각 Phase는 앞 Phase에 컴파일 의존한다. Phase 2 완료 후, Phase 5 완료 후 각각 `tuist install && tuist generate` 실행 필요(신규 `.swift` 파일 추가 반영).

## Task 목록

### Phase 1. Domain

#### [x] Task 1 — `KoreanPhrase.swift` (수정)
**파일**: `Projects/Domain/Sources/Entity/KoreanPhrase.swift`
- `public let isCustom: Bool` 프로퍼티 추가
- `init`의 **마지막** 파라미터로 `isCustom: Bool = false` 추가 — 기본값을 줘야 `KoreanPhraseRepository`, `KoreanPhraseListView` Preview, `KoreanPhraseDetailView` Preview의 기존 호출부가 무변경으로 컴파일됨
- `Equatable` / `Sendable` / `Identifiable` 채택 유지

---

#### [x] Task 2 — `CustomKoreanPhraseRepositoryProtocol.swift` (신규)
**파일**: `Projects/Domain/Sources/RepositoryProtocol/CustomKoreanPhraseRepositoryProtocol.swift`
- `Sendable` 채택
- `fetchCustomPhrases() async throws -> [KoreanPhrase]` 정의
- `addCustomPhrase(_ phrase: KoreanPhrase) async throws` 정의 — `KoreanPhrase`를 통째로 받는다(id/createdAt 생성 책임은 UseCase가 가짐)
- `deleteCustomPhrase(id: String) async throws` 정의

---

#### [x] Task 3 — `KoreanPhraseUseCaseProtocol.swift` (수정)
**파일**: `Projects/Domain/Sources/UseCase/KoreanPhrase/KoreanPhraseUseCaseProtocol.swift`
- `fetchCustomPhrases() async throws -> [KoreanPhrase]` 추가
- `addCustomPhrase(korean: String, japanese: String, pronunciation: String?) async throws -> KoreanPhrase` 추가
- `deleteCustomPhrase(id: String) async throws` 추가
- 기존 `fetchPhrases()` 시그니처는 무변경

---

#### [x] Task 4 — `KoreanPhraseUseCase.swift` (수정)
**파일**: `Projects/Domain/Sources/UseCase/KoreanPhrase/KoreanPhraseUseCase.swift`
- `init(repository:customRepository:)`로 확장 — 기존 `repository` 프로퍼티명 유지, `customRepository: CustomKoreanPhraseRepositoryProtocol` 신규 추가
- `fetchCustomPhrases()`: `customRepository.fetchCustomPhrases()` 위임
- `addCustomPhrase(korean:japanese:pronunciation:)`: id 생성(`"custom_" + UUID().uuidString`), `isCustom: true`, `order`는 임시로 `0`, `createdAt = Date()`로 `KoreanPhrase` 구성 후 `customRepository.addCustomPhrase(_:)`에 위임, 저장된 Entity 반환
- `deleteCustomPhrase(id:)`: `customRepository.deleteCustomPhrase(id:)` 위임
- `MARK: - Properties / Init / Method` 순서 준수

---

#### [x] Task 5 — `TestKoreanPhraseUseCase.swift` (수정)
**파일**: `Projects/Domain/Sources/UseCase/KoreanPhrase/TestKoreanPhraseUseCase.swift`
- `public var customPhrases: [KoreanPhrase] = []` 추가
- `fetchCustomPhrases()` / `addCustomPhrase(korean:japanese:pronunciation:)` / `deleteCustomPhrase(id:)` 3개 메서드를 인메모리 배열 조작으로 구현
- `@unchecked Sendable` 채택 유지
- Preview에서 커스텀 Section을 확인할 수 있도록 데이터 주입 가능한 형태 유지

---

### Phase 2. Data

#### [x] Task 6 — `CustomKoreanPhraseModel.swift` (신규)
**파일**: `Projects/Data/Sources/SwiftData/CustomKoreanPhraseModel.swift`
- `@Model final class`(internal 접근) 선언
- `@Attribute(.unique) var id: String`
- `var korean: String`, `var japanese: String`, `var pronunciation: String?`, `var createdAt: Date`
- `order`는 저장하지 않음 — 정렬 기준이 `createdAt`이므로 중복 진실 원천을 만들지 않음

---

#### [x] Task 7 — `KoreanPhraseModelContainer.swift` (신규)
**파일**: `Projects/Data/Sources/SwiftData/KoreanPhraseModelContainer.swift`
- `BookmarkModelContainer` 구조를 그대로 본떠 작성
- `public final class ... Sendable` + `static let shared`
- `ModelConfiguration("KoreanPhrase", schema:)` 사용, in-memory 폴백 처리 포함
- `isFallbackToMemory` 플래그를 `BookmarkModelContainer`처럼 노출(이번 스펙에서는 소비하지 않음)
- 컨테이너 생성 실패 시 `AppLogger.core` 로깅

---

#### [x] Task 8 — `CustomKoreanPhraseModel+.swift` (신규)
**파일**: `Projects/Data/Sources/Extension/CustomKoreanPhraseModel+.swift`
- `ToolBarPlanItemModel+.swift`와 동일 구성으로 작성
- `var toDomain: KoreanPhrase` — `isCustom: true`로 매핑, `order`는 호출측(Repository)에서 덮어씀을 전제로 임시값 채움
- `convenience init(phrase: KoreanPhrase, createdAt: Date)` — 도메인 → SwiftData 모델 매핑

---

#### [x] Task 9 — `CustomKoreanPhraseRepository.swift` (신규)
**파일**: `Projects/Data/Sources/Repository/CustomKoreanPhrase/CustomKoreanPhraseRepository.swift`
- `public init(modelContainer: ModelContainer = KoreanPhraseModelContainer.shared.modelContainer)`
- 본문에는 프로퍼티/init만 두고, 프로토콜 채택은 `// MARK: - CustomKoreanPhraseRepositoryProtocol` extension으로 분리
- `fetchCustomPhrases()`: `FetchDescriptor(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])`로 조회 후 `enumerated()`로 `order` 값 부여해 반환
- `addCustomPhrase(_:)`: `context.insert` 후 `save()`
- `deleteCustomPhrase(id:)`: `#Predicate { $0.id == id }` + `fetchLimit = 1`로 조회, 없으면 `AppLogger.core` 경고 로그 후 return
- 모든 catch 구문에서 `AppLogger.core.log(.error, ...)` 로깅 후 `TabiError.persistenceFailed(message:)` throw
- `ToolBarPlanItemRepository.swift`를 직접 템플릿으로 참고

---

#### [x] Task 10 — Tuist 프로젝트 재생성
**명령**: `tuist install && tuist generate`
- Phase 1~2에서 추가한 신규 `.swift` 파일(`CustomKoreanPhraseRepositoryProtocol`, `CustomKoreanPhraseModel`, `KoreanPhraseModelContainer`, `CustomKoreanPhraseModel+`, `CustomKoreanPhraseRepository`)을 프로젝트에 반영
- 이 단계 없이 빌드 시 stale 프로젝트로 인한 오탐 에러가 발생하므로 반드시 선행

---

### Phase 3. App (DI 조립)

#### [x] Task 11 — `KoreanPhraseUseCaseDependencyKey.swift` (수정, App)
**파일**: `Projects/App/Sources/Dependency/KoreanPhraseUseCaseDependencyKey.swift`
- `liveValue`를 `KoreanPhraseUseCase(repository: KoreanPhraseRepository(), customRepository: CustomKoreanPhraseRepository())`로 변경
- `Domain/Sources/Dependency/Keys/KoreanPhraseUseCaseDependencyKey.swift`, `Domain/Sources/Dependency/DependencyValues.swift`는 **변경 없음**(키·프로퍼티가 이미 존재하고, `testValue`는 `TestKoreanPhraseUseCase()` 그대로 유지)

---

### Phase 4. Resource

#### [x] Task 12 — `Strings.swift` (수정)
**파일**: `Projects/Resource/Sources/Strings/Strings.swift`
- `public extension Strings.KoreanPhrase`에 아래 신규 문자열 추가(기존 항목과 동일하게 각 항목 위에 한국어 주석 작성):
  - 목록 화면: 커스텀 Section 헤더, Firebase Section 헤더, "+" 버튼 accessibilityLabel
  - 입력 폼: 화면 타이틀, 한국어 라벨/플레이스홀더, 일본어 라벨/플레이스홀더, 발음 라벨/플레이스홀더(선택 표기 포함), 번역 버튼 타이틀, 저장 버튼 타이틀
  - 안내/에러: 번역 실패 토스트 메시지, 일본어 미입력 상태에서 번역 시도 시 안내 토스트 메시지, 저장 실패 얼럿 타이틀/메시지
- 삭제 스와이프 라벨은 기존 `Strings.Common.delete` 재사용, 얼럿 확인 버튼은 기존 `Strings.Plan.alertConfirm` 재사용 — 신규 정의 불필요

---

### Phase 5. Presentation

#### [x] Task 13 — `AddKoreanPhraseFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/AddKoreanPhrase/AddKoreanPhraseFeature.swift`
- State(선언 순서: 공개 → fileprivate → `@Presents`): `korean` / `japanese` / `pronunciation` / `pendingTranslationJapanese: String?` / `isTranslating` / `isSaving`, `@Presents var alert: AlertState<Action.Alert>?`
- 계산 프로퍼티: `trimmedKorean` / `trimmedJapanese` / `trimmedPronunciation` / `isSaveEnabled`(`trimmedKorean.isEmpty == false && trimmedJapanese.isEmpty == false && isSaving == false`)
- Action(선언 순서: 바인딩 → 생명주기 → 인터랙션 → 비동기 결과 → 하위): `binding` / `closeTapped` / `translateButtonTapped` / `saveButtonTapped` / `translationResultReceived(String)` / `translationFailed` / `saveResult(KoreanPhrase?)` / `alert(PresentationAction<Alert>)`
- body: `BindingReducer()` → `Reduce` → `.ifLet(\.$alert, action: \.alert)`
- `translateButtonTapped`: `trimmedJapanese`가 비었으면 안내 토스트 이펙트만 반환, 아니면 `pendingTranslationJapanese` 세팅 + `isTranslating = true`
- `translationResultReceived`: `pendingTranslationJapanese = nil`, `isTranslating = false`, 결과가 비어있지 않으면 `korean`에 대입(사용자가 이후 직접 수정 가능)
- `translationFailed`: 상태 정리 + 실패 토스트 이펙트(`AppLogger.view` 로깅은 Modifier 쪽에서 이미 수행)
- `saveButtonTapped`: `isSaveEnabled` 동일 조건 guard로 이중 방어 후 저장 이펙트 실행
- `saveResult(nil)`: `isSaving = false` + 저장 실패 `AlertState` 표시(입력값 보존)
- `saveResult(.some)`: 부모(`KoreanPhraseListFeature`)가 소비하므로 이 Feature에서는 `.none`
- 발음(`pronunciation`)은 trim 후 빈 문자열이면 `nil`로 저장 이펙트에 전달
- 이펙트는 하단 `private extension`에 `saveEffect(...)` 등으로 분리, `CancelID`는 `private enum`으로 정의
- 번역 방향이 일본어→한국어로 바뀌면서 별도 `.translationTask` Modifier가 불필요해짐 — 기존 `TranslateSearchTaskModifier`(`translateSearchTask(pendingQuery:onResult:onFailure:)`)가 이미 동일 방향이라 그대로 재사용(`AddKoreanPhraseTranslateTaskModifier.swift`는 삭제됨)

---

#### [x] Task 14 — `AddKoreanPhraseView.swift` (신규)
**파일**: `Projects/Presentation/Sources/AddKoreanPhrase/AddKoreanPhraseView.swift`
- `AddTravelPlanView` 레이아웃을 참고해 `ScrollView` + `safeAreaBar(edge: .top) { TabiNavigationBar(...) { TabiCircleIconButton("xmark") } }` + `safeAreaBar(edge: .bottom) { TabiButton(저장, style: .primary, isExpanded: true, isLoading:) }` 구성
- 필드 순서는 일본어 → 한국어 → 발음(사용자가 입력하는 순서와 일치)
- 일본어 필드: `TabiTextField` + 우측에 `TabiButton(번역, style: .ghost, isLoading: store.isTranslating)`를 `HStack`으로 배치
- 한국어 필드 / 발음 필드: `TabiTextField` 사용
- `.presentationDetents([.medium, .large])` + `.presentationDragIndicator(.visible)` 적용
- `.alert($store.scope(state: \.alert, action: \.alert))` 연결
- `.translateSearchTask(pendingQuery: store.pendingTranslationJapanese, onResult:, onFailure:)` 연결 — `TranslateSearch/TranslateSearchTaskModifier.swift`가 이미 제공하는 공용 Modifier 재사용
- `body`가 50줄을 넘으면 필드 묶음을 같은 파일 내 `private extension`의 `@ViewBuilder` 함수로 분리(`Sub/` 폴더 불필요)
- `#Preview`에서 `TestKoreanPhraseUseCase` 주입
- 신규 UI 컴포넌트를 만들지 않고 DesignSystem 기존 컴포넌트만 사용

---

#### [x] Task 15 — `KoreanPhraseListFeature.swift` (수정)
**파일**: `Projects/Presentation/Sources/KoreanPhraseList/KoreanPhraseListFeature.swift`
- State에 `customPhrases: [KoreanPhrase] = []` 추가, `@Presents var addPhraseState: AddKoreanPhraseFeature.State?` 추가(`phraseDetailState` 위에 선언 — `@Presents`끼리 묶음)
- Action 추가: `addButtonTapped` / `customPhraseDeleted(id: String)` / `customPhrasesResult([KoreanPhrase])` / `addPhrase(PresentationAction<AddKoreanPhraseFeature.Action>)`
- `onAppear` / `retryButtonTapped`: 원격 fetch 이펙트와 커스텀 fetch 이펙트를 `.merge`로 실행. 단 `retryButtonTapped`는 원격만 재시도(커스텀 조회는 별도 재시도 UI 없음)
- `addPhrase(.presented(.saveResult(.some(phrase))))`: `state.customPhrases.insert(phrase, at: 0)` 후 `state.addPhraseState = nil` (`PlanFeature`의 `addPlan(.presented(.saveResult(true)))` 패턴 참고)
- `customPhraseDeleted`: 낙관적 갱신 — 먼저 `state.customPhrases`에서 제거 후 삭제 이펙트 실행, 실패 시 `AppLogger.view` 로깅만 하고 목록은 되돌리지 않음(`ShoppingPlanListFeature.deleteItemsEffect`와 동일 정책)
- 부분 실패 정책: 커스텀(SwiftData) 조회 실패는 별도 화면 전환 없이 `AppLogger.view` 로깅 후 빈 배열로 폴백
- body 끝에 `.ifLet(\.$addPhraseState, action: \.addPhrase) { AddKoreanPhraseFeature() }` 추가(기존 `.ifLet(\.$phraseDetailState, ...)` 뒤에 위치)
- `CancelID`에 `fetchCustomPhrases` 케이스 추가

---

#### [x] Task 16 — `KoreanPhraseListView.swift` (수정)
**파일**: `Projects/Presentation/Sources/KoreanPhraseList/KoreanPhraseListView.swift`
- `ShoppingPlanListView`의 툴바 패턴을 참고해 `.toolbar { ToolbarItem(placement: .topBarTrailing) { Button { store.send(.addButtonTapped) } label: { Image(systemName: "plus") } .tint(Color.getTabiColor(.tabiPrimary)).accessibilityLabel(...) } }` 추가
- `.sheet(item: self.$store.scope(state: \.addPhraseState, action: \.addPhrase)) { AddKoreanPhraseView(store: $0) }` 연결
- `content()` 분기 재작성:
  - 로딩 중 → `ProgressView`
  - 원격 실패 **and** 커스텀 0건 → 기존 `TabiRetryableEmptyState`(전체 화면)
  - 원격 실패 **and** 커스텀 1건 이상 → 커스텀 Section은 정상 표시, Firebase Section 자리에만 `TabiRetryableEmptyState`를 카드로 렌더
  - 원격 0건 **and** 커스텀 0건 → 기존 `TabiEmptyState`
  - 그 외 → 2-Section `List`(커스텀 Section 최상단, Firebase Section 그 아래)
- 커스텀 Section의 각 행에만 `.swipeActions(edge: .trailing) { Button(role: .destructive) ... }` 부착 — Firebase Section에는 부착하지 않음(삭제 옵션 미노출)
- Section 헤더는 `customPhrases.isEmpty == false`일 때만 노출(커스텀 0건이면 두 헤더 모두 숨겨 기존 화면과 동일하게 보이도록). 헤더는 `TabiLabel(style: .captionMBold, color: .tabiTextSecondary)` + `.listRowInsets(EdgeInsets())` — `ShoppingPlanListView`의 헤더 inset 처리 참고
- `listRowSeparator(.hidden)` / `listRowBackground(Color.clear)` / `listRowInsets(top:6, leading:20, bottom:6, trailing:20)` 기존 값 유지
- `#Preview`에 `useCase.customPhrases` 데이터 세팅 추가

---

#### [x] Task 17 — Tuist 프로젝트 재생성 및 빌드
**명령**: `tuist install && tuist generate` 이후 `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- Phase 5에서 추가/삭제한 `.swift` 파일(`AddKoreanPhraseFeature`, `AddKoreanPhraseView` 신규, `AddKoreanPhraseTranslateTaskModifier` 삭제)을 프로젝트에 반영 후 빌드 확인

---

### Phase 6. 검증

#### [x] Task 18 — 빌드 확인
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` 성공 확인

---

#### [ ] Task 19 — 수동 시나리오 검증
- ToolBar 허브 → "간단한 한국어" → "+" → 입력 폼 진입 확인
- 일본어만 입력한 상태 → 저장 버튼 비활성 확인
- "번역" 버튼 탭 → 한국어 필드 자동 채움 확인 → **다시 한 번 더 탭해 재번역이 되는지 확인**(`TranslateSearchTaskModifier`의 `TranslationSession.Configuration.invalidate()` 검증 포인트)
- 저장 → 커스텀 Section 최상단에 즉시 노출되는지 확인
- 커스텀 행 스와이프 → 삭제됨 확인 / Firebase 행 스와이프 → 삭제 액션 미노출 확인
- 커스텀 행 탭 → 가로모드 상세 화면 진입, 롱프레스 복사 메뉴 동작 확인
- 앱 강제종료 후 재실행 → 커스텀 문구 유지 확인
- 기내모드 상태로 재실행(Firebase 실패 유도) → 커스텀 Section은 보이고 Firebase Section 자리에만 재시도 UI 노출 확인

---

## 체크리스트

### 품질 (DoD)
- [x] 빌드 성공
- [x] `Domain`이 `Data`를 import하지 않음 — `CustomKoreanPhraseRepository` 조립은 `App/Sources/Dependency/KoreanPhraseUseCaseDependencyKey.swift`에서만 발생
- [x] `testValue`(Domain) / `liveValue`(App) 계층 분리 유지, `Domain/Sources/Dependency/DependencyValues.swift`는 무변경
- [x] 신규/수정 파일이 `folder-structure.md`의 모듈별 경로 규칙을 벗어나지 않음
- [x] 모든 신규 문자열이 `Resource/Sources/Strings/Strings.swift`의 `Strings.KoreanPhrase`에 정의되고, 코드에 하드코딩된 문자열 없음
- [x] 신규 UI 컴포넌트를 만들지 않고 DesignSystem 기존 컴포넌트만 사용
- [x] 프로토콜 채택은 `extension` 분리, `private` 멤버는 하단 `extension`에 모음, 강제 언래핑 없음
- [x] `TranslateSearchTaskModifier.swift` 및 Map / PlanDetailAddSpot / AddCustomPlace 3개 화면 무변경 (`AddKoreanPhraseView`는 호출부만 추가)
- [ ] 후속 과제 기록: `DataResetUseCase.resetAll()`에 커스텀 문구 초기화 포함 여부 논의(이번 스펙 범위 외) — 논의만 필요, 미착수
- 테스트 타겟 미구성 상태이므로 자동화 테스트는 해당 없음(`.claude/CLAUDE.md` 참조)

### 기능 (AC)
- [ ] `KoreanPhraseListView`에 "+" 버튼이 보이고, 탭하면 문구 입력 폼으로 진입한다
- [ ] 한국어/일본어를 입력 후 저장하면 커스텀 문구가 목록에 즉시 나타난다
- [ ] 한국어 또는 일본어가 비어있으면 저장할 수 없다
- [ ] 일본어 필드 입력 후 "번역" 버튼을 탭하면 한국어 필드가 자동으로 채워진다
- [ ] 번역이 실패해도 에러가 안내될 뿐 앱이 멈추지 않고, 한국어 필드를 직접 입력해 저장할 수 있다
- [ ] 커스텀 문구를 스와이프해 삭제할 수 있다 (Firebase 문구는 삭제 옵션이 보이지 않는다)
- [ ] 커스텀 문구를 탭하면 기존 문구와 동일하게 상세(가로모드) 화면과 복사 메뉴가 동작한다
- [ ] 앱을 재실행해도 커스텀 문구가 유지된다
