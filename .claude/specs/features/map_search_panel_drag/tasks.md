# Tasks: map_search_panel_drag

## 참조
- spec: `.claude/specs/features/map_search_panel_drag/spec.md`
- plan: `.claude/specs/features/map_search_panel_drag/plan.md`

## Task 목록

### Phase 1. 임계값 상수 재구성

#### [x] Task 1 — `MapSearchPanelView.swift` (`MapSearchPanelLayout`)
**파일**: `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`
- `private enum MapSearchPanelLayout`에서 `dragHandleSize`, `dragHandleTouchPadding`은 그대로 유지
- `fastFlickVelocityThreshold`, `minimumMeaningfulDrag` 2개 상수 제거
- 방향별 비대칭 4개 상수로 대체 (시작 제안값, 실기기 감각으로 조율 가능)
  - `upwardMinimumDrag: CGFloat = 24`
  - `upwardFlickVelocity: CGFloat = 350`
  - `downwardMinimumDrag: CGFloat = 44`
  - `downwardFlickVelocity: CGFloat = 900`
- 각 상수 위에 한 줄 주석으로 "위/아래 비대칭 이유" 명시
- `downwardMinimumDrag` 위에 `dragHandleTouchPadding(20)`보다 반드시 커야 한다는 관계 주석 추가
- 정렬용 다중 공백 금지, 단일 공백만 사용 (`swift-style.md` 2번)
- 관계식 검증: `upwardMinimumDrag < downwardMinimumDrag`, `upwardFlickVelocity < downwardFlickVelocity`, `downwardMinimumDrag > dragHandleTouchPadding`

---

### Phase 2. 상태 선언 전환

#### [x] Task 2 — `MapSearchPanelView.swift` (Properties: `@GestureState` 전환)
**파일**: `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`
- `@State private var dragOffset: CGFloat = 0` → `@GestureState private var dragOffset: CGFloat = 0`으로 전환
  - 리셋 시 `.tabiSpring` 애니메이션이 적용되도록 `resetTransaction: Transaction(animation: .tabiSpring)` 지정 지점을 `.updating` 호출부에 준비 (실제 지정은 Task 4에서 `.updating(_:body:)` 시그니처에 포함)
- `@State private var isDragging: Bool = false` → `@GestureState`로 전환
  - Bool 프리픽스 규칙(`is`) 유지, 필요 시 역할이 드러나는 이름(예: `isDragActive`)으로 조정
- `@State private var settleTrigger: Int = 0` 완전 삭제
- `@State private var displayedStage: MapPanelStage`는 변경 없이 유지
- `baseHeight` / `currentHeight` / `hiddenOffset` 계산 프로퍼티는 로직 변경 없이, `dragOffset` 타입이 `GestureState<CGFloat>.Value`(= `CGFloat`)로도 기존 참조 코드가 그대로 컴파일되는지 확인

---

### Phase 3. 제스처 구성 변경

#### [x] Task 3 — `MapSearchPanelView.swift` (`dragGesture()` 재작성)
**파일**: `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`
- `dragGesture()`를 `.updating($dragOffset) { value, state, transaction in ... }` 방식으로 재작성
  - `state = value.translation.height` 반영 (손가락 추종)
  - `transaction.animation`을 통해 리셋 시 `.tabiSpring`이 적용되도록 트랜잭션 구성 (Phase 2에서 설계한 리셋 애니메이션 반영)
  - `.updating` 클로저 내부에서는 외부 상태 변경/콜백 호출을 하지 않음 (뷰 업데이트 중 상태 변경 경고 회피)
- `.updating($isDragActive) { _, state, _ in state = true }` 추가 (제스처 활성 플래그, `.onChanged`가 아니라 `.updating`에서 처리)
- `.onChanged`는 더 이상 `isDragging`/`onDragStarted` 호출을 직접 수행하지 않도록 역할 축소 (필요 시 완전히 제거하고 `.updating`만으로 대체)
- `.onEnded`에서는 `handleDragEnded(translation:velocity:)`만 호출
  - `dragOffset = 0` 수동 대입 제거 (`@GestureState`가 자동 리셋 담당)
  - `isDragging = false` / `onDragEnded()` 수동 호출 제거 (`.onChange(of:)` 경유로 이관, Task 4 참고)
- `dragHandle()`의 `.contentShape(Rectangle())` / 패딩 / `.gesture(...)` 부착 구조는 무수정

#### [x] Task 4 — `MapSearchPanelView.swift` (`body`에 `.onChange(of: isDragActive)` 추가)
**파일**: `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`
- `body`에 `.onChange(of: self.isDragActive)` (또는 전환된 프로퍼티명) 모디파이어 추가
  - `false → true`: `self.onDragStarted()` 호출
  - `true → false`: `self.onDragEnded()` 호출
- 이 경로가 제스처 취소 시에도 반드시 발화하여 `MapView.isPanelDragging`이 `false`로 해제되는지 확인 (키보드 높이 갱신 가드와 연결된 지점, Phase 6에서 재검증)

---

### Phase 4. 드래그 종료 판정 로직 재작성

#### [x] Task 5 — `MapSearchPanelView.swift` (`handleDragEnded`)
**파일**: `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`
- `dragOffset = 0` 대입 라인 제거 (`@GestureState`가 담당하므로 불필요)
- `translation > 0` → `handleDownwardDragEnded` 호출, 그 외 → `handleUpwardDragEnded` 호출 하는 기존 분기 구조는 유지

#### [x] Task 6 — `MapSearchPanelView.swift` (`handleUpwardDragEnded` 재작성)
**파일**: `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`
- 기존 3중 `guard` (속도 가지 / 거리 가지 / nextStage 가지) 구조를 제거하고 아래 순서로 재작성
  1. `let shouldAdvance = translation <= -MapSearchPanelLayout.upwardMinimumDrag || velocity <= -MapSearchPanelLayout.upwardFlickVelocity` 계산
  2. `shouldAdvance == false` → 아무것도 하지 않고 `return` (스냅백은 `dragOffset`의 `resetTransaction`이 처리, `onStageChanged` 미호출, `settleTrigger` 증가 코드 완전 제거)
  3. `guard let nextStage = self.nextHigherStage(from: self.displayedStage) else { return }` (이미 `.full`이면 아무것도 하지 않음)
  4. `self.displayedStage = nextStage`, `self.onStageChanged(nextStage)` 호출
- `velocity` 부호 규약 확인: 위로 이동 시 음수이므로 `velocity <= -upwardFlickVelocity` 형태가 맞는지 재확인

#### [x] Task 7 — `MapSearchPanelView.swift` (`handleDownwardDragEnded` 재작성)
**파일**: `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`
- 기존 구조에서 "속도 가지가 `nextLowerStage`를 보지 않고 바로 `onDismiss()`를 호출"하던 버그의 근본 원인인 `guard velocity < fastFlickVelocityThreshold else { onDismiss(); return }` 분기를 완전히 제거
- 아래 순서로 재작성
  1. `let shouldAdvance = translation >= MapSearchPanelLayout.downwardMinimumDrag || velocity >= MapSearchPanelLayout.downwardFlickVelocity` 계산
  2. `shouldAdvance == false` → 아무것도 하지 않고 `return` (스냅백, `settleTrigger` 증가 코드 완전 제거)
  3. `guard let nextStage = self.nextLowerStage(from: self.displayedStage) else { self.onDismiss(); return }` — **`.collapsed`에서 하강 임계를 넘겼을 때, 이 지점 단 한 곳에서만** `onDismiss()` 호출
  4. `self.displayedStage = nextStage`, `self.onStageChanged(nextStage)` 호출
- 완료 조건: `onDismiss()` 호출 지점이 파일 전체에서 이 한 곳뿐인지 `grep -n "onDismiss()"`로 확인

---

### Phase 5. body 애니메이션 정리

#### [x] Task 8 — `MapSearchPanelView.swift` (`body` 애니메이션/`.onChange(of: stage)` 정리)
**파일**: `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`
- `.animation(.tabiSpring, value: self.settleTrigger)` 모디파이어 완전 제거
- `.animation(.tabiSpring, value: self.displayedStage)`는 유지 (패널 지오메트리에 걸리는 유일한 애니메이션 소스)
- `.onChange(of: self.stage) { _, newValue in self.displayedStage = newValue }`에 가드 추가
  - 드래그 활성 상태(`isDragActive` 등)일 때는 외부 `stage` 반영을 보류
  - `newValue != self.displayedStage`일 때만 대입 (동일 값 재대입으로 인한 불필요한 무효화 방지)
- `.offset(y: self.hiddenOffset)` 등 나머지 레이아웃 구성은 무수정

---

### Phase 6. 호출부 정합성 확인 (읽기 전용, 코드 수정 없음)

#### [x] Task 9 — `MapView.swift` / `MapFeature.swift` 무수정 확인
**파일**: `Projects/Presentation/Sources/Map/MapView.swift`, `Projects/Presentation/Sources/Map/MapFeature.swift`
- `MapView.swift`의 `searchPanel()` 호출부(`stage`, `collapsedHeight`, `halfHeight`, `fullHeight`, `onStageChanged`, `onDismiss`, `onDragStarted`, `onDragEnded` 8개 파라미터)가 `MapSearchPanelView`의 `init` 시그니처 무변경 하에 수정 없이 그대로 컴파일되는지 확인
- `onDragStarted`에서 수행하는 `isSearchFieldFocused = false` 타이밍이 `.onChange` 경유로 한 프레임 늦어지는지 실기기/시뮬레이터로 체감 확인 (지연이 체감되면 리스크 항목 참고해 `onDragStarted`만 `.onChanged` 최초 1회 호출로 되돌리는 절충안 검토)
- `git diff`로 `MapFeature.swift`(State/Action/Reducer)가 이번 작업에서 무수정임을 재확인
- 이 Task는 코드 수정이 아닌 확인/검증 작업

---

### Phase 7. 빌드 및 수동 검증

#### [x] Task 10 — 빌드 확인
**파일**: 없음 (빌드 명령 실행)
- 신규 `.swift` 파일 추가 없으므로 `tuist generate` 불필요
- 현재 워킹트리에 이번 작업과 무관한 미추적 파일(`TravelPlanDetail` 관련)이 남아 있어 빌드 실패 시 이 변경과 무관한 원인인지 먼저 판별
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'` 실행 (iPhone 16 Pro 미설치 환경 기준, 설치된 시뮬레이터명으로 조정)
- 빌드 성공 확인

#### [ ] Task 11 — 수동 시나리오 검증 (전부 육안 검증, AC 대응)
**파일**: 없음 (시뮬레이터/실기기 수동 조작)
- `full`에서 빠른 하향 플릭 → `half`까지만 이동, `onDismiss()` 호출 안 됨 확인
- `half`에서 하향 드래그 → `collapsed`, `collapsed`에서 다시 하향 유의미 드래그 → `onDismiss()` 호출 확인
- `collapsed`에서 아주 짧은(20pt 미만) 하향 슬립 → 스냅백, dismiss 안 됨 확인
- 동일 거리/속도의 상향 드래그가 하향보다 쉽게(더 짧은 거리·더 낮은 속도로) 다음 단계로 전이되는지 비교 확인
- 핸들을 잡고 수 pt 단위로 천천히 흔들기 → 떨림/튐 없이 손가락 추종 확인
- 드래그 도중 홈 인디케이터 스와이프/알림 배너 등으로 제스처 인터럽트 → 잔류 오프셋 없이 정착, 이후 키보드 동작(`keyboardWillChangeFrame`/`keyboardWillHide`) 정상 확인
- 느린 드래그로 `collapsed → half → full` 순차 이동, `half → collapsed` 내리기 등 기존 정상 시나리오 회귀 없음 확인
- 키보드가 올라온 typing 모드에서 드래그를 시작하는 케이스를 반드시 포함해 제스처 취소 재현 여부 확인
- 임계값이 과하다고 느껴지면 Task 1의 상수만 조정 후 재검증 (관계식 유지)

---

## 체크리스트

### 품질 (DoD)
- [x] AppDebug 스킴 빌드 성공
- [x] `settleTrigger`(`@State` + `.animation(.tabiSpring, value: settleTrigger)`)가 완전히 제거되고, 패널 지오메트리에 걸리는 `.animation` 소스가 `displayedStage` 하나로 단일화됨
- [x] `dragOffset` / 드래그 활성 플래그가 `@GestureState`로 관리되어 제스처 취소 시 자동으로 리셋됨
- [x] `onDismiss()` 호출 경로가 코드상 "`.collapsed`에서 하향 임계 초과" 단 한 곳뿐임 (`grep -n "onDismiss()"`로 확인)
- [x] `downwardMinimumDrag > dragHandleTouchPadding`, `upwardMinimumDrag < downwardMinimumDrag`, `upwardFlickVelocity < downwardFlickVelocity` 관계가 상수 정의에서 성립함
- [x] `MapSearchPanelView`의 `init` 파라미터/콜백 시그니처 무변경, `MapView.swift` 무수정
- [x] `MapFeature.swift`(State/Action/Reducer) 무수정
- [x] UIKit 타입(`UIPanGestureRecognizer`/`UIViewRepresentable`)이 도입되지 않음
- [x] 신규 애니메이션 정의 없이 `.tabiSpring`만 사용
- [x] `swift-style.md` MARK 섹션 구조(Properties/Init/View/Method) 및 `private extension` 접근 제어 규칙 유지
- [ ] 테스트 타겟 미구성 레포이므로 자동 테스트 없음 — Phase 7 수동 검증으로 대체 확인 (Task 11 미완료, 사용자 실기기/시뮬레이터 확인 필요)

### 기능 (AC)
- [ ] `full` 상태에서 빠른 하향 플릭 시 `half`로만 이동하고, `collapsed`에서 다시 한번 유의미하게 아래로 드래그(또는 빠른 플릭)해야만 `onDismiss()`가 호출된다
- [ ] `collapsed` 상태에서 매우 짧은(터치 패딩 수준 이하) 하향 슬립 시 dismiss되지 않고 원래 자리로 스냅백한다
- [ ] 동일 조건(비슷한 거리/속도)에서 위로 드래그가 아래로 드래그보다 더 쉽게 다음 단계로 전이된다
- [ ] 핸들을 잡고 아주 천천히 수 pt씩 흔들 때 시트가 떨리거나 튀지 않고 손가락을 부드럽게 추종한다
- [ ] 드래그 도중 제스처가 취소되는 상황에서도 시트가 잔류 오프셋 없이 정상 위치로 복귀한다
- [ ] `displayedStage`가 바뀌지 않는 드래그(스냅백)에서는 불필요한 스프링 애니메이션 재생이 발생하지 않는다
- [ ] 기존 정상 시나리오(느린 드래그로 collapsed→half→full 순차 이동, half→collapsed 내리기)가 회귀 없이 동작한다
