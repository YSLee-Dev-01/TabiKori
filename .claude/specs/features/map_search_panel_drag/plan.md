# Plan: map_search_panel_drag (MapSearchPanelView 드래그 제스처 로직 개선 - 1차 순수 SwiftUI)

## 참조 Spec
- @.claude/specs/features/map_search_panel_drag/spec.md

## 참조 Skill
- 신규 화면 생성이 아니므로 `create-feature` 스킬 해당 없음 (해당 스킬은 이 레포에 존재하지 않음)
- 기존 파일 1개(`MapSearchPanelView.swift`) 내부 로직 수정 작업 — `.claude/rules/swift-style.md`의 MARK 구조 / 접근 제어 / `self` 사용 규칙만 준수하면 됨

---

## 현재 상태 파악

### 신규
- **없음.** 신규 `.swift` 파일 추가 없음 → `tuist generate` 불필요 (기존 파일 내용만 변경)
- 신규 애니메이션/문자열/DesignSystem 컴포넌트 추가 없음 (`.tabiSpring` 재사용)

### 재사용
- **DesignSystem**: `Animation.tabiSpring`(`Animation.spring(response: 0.35, dampingFraction: 0.7)`) — spec 제약대로 신규 애니메이션 정의 없이 그대로 사용
- **DesignSystem**: `TabiColor.tabiBorder`(핸들), `TabiColor.tabiSurface`(배경), `.tabiRadiusXl` — 변경 없음
- **Presentation/Entity**: `MapPanelStage`(`.full/.half/.collapsed`) — 변경 없음
- **Presentation**: `MapView.searchPanel()`의 호출부 8개 파라미터(`stage`, `collapsedHeight`, `halfHeight`, `fullHeight`, `onStageChanged`, `onDismiss`, `onDragStarted`, `onDragEnded`) — **시그니처 그대로 유지, MapView.swift 무수정**
- **Presentation**: `MapFeature.panelDragEnded(MapPanelStage)` / `.searchCancelTapped` — 변경 없음

### 수정
- `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift` — **유일한 수정 대상 파일**
  - `private enum MapSearchPanelLayout` — 단일 임계값 상수 2개(`fastFlickVelocityThreshold: 800`, `minimumMeaningfulDrag: 12`)를 **방향별 비대칭 4개 상수**로 재구성
  - `@State private var dragOffset: CGFloat` → `@GestureState`로 전환 (제스처 취소 시 자동 리셋)
  - `@State private var isDragging: Bool` → `@GestureState`로 전환 + `.onChange`로 `onDragStarted`/`onDragEnded` 호출 시점 이관
  - `@State private var settleTrigger: Int` — **삭제 대상** (아래 "삭제" 항목에 존재 이유 명시)
  - `dragGesture()` — `.updating(_:body:)` 추가, `.onChanged`의 역할 축소
  - `handleDragEnded / handleUpwardDragEnded / handleDownwardDragEnded` — 판정 구조 전면 재작성
  - `body`의 `.animation(.tabiSpring, value: self.settleTrigger)` 제거, `.onChange(of: self.stage)`에 가드 추가

### 삭제
- **`settleTrigger` (@State + `.animation(.tabiSpring, value: settleTrigger)`) 삭제**
  - **왜 존재했는가**: `dragOffset`은 `.animation(_:value:)`의 키로 등록되어 있지 않아, 드래그 종료 시 `dragOffset = 0` 대입이 애니메이션 없이 즉시 반영된다. 그래서 "스냅 애니메이션을 강제로 한 번 재생시키기 위한 더미 트리거"로 정수 카운터를 두고 매 종료마다 증가시키는 방식이 쓰였다.
  - **왜 삭제 가능한가**: `@GestureState`의 `resetTransaction`이 제스처 종료(정상/취소 모두) 시점의 리셋을 지정한 트랜잭션으로 애니메이션해 주므로, 더미 트리거 없이 동일한 스냅 애니메이션을 얻을 수 있다.
  - **삭제해야만 하는 이유**: 현재는 stage가 실제로 바뀌는 드래그에서 `value: displayedStage`와 `value: settleTrigger` **두 개의 `.animation` 모디파이어가 같은 프레임에 동시 발화**해 동일 지오메트리(`hiddenOffset`)에 스프링을 이중으로 걸고, 이것이 spec 3번(떨림/jitter)의 직접 원인이다. 또한 스냅백(stage 미변경) 케이스에서도 무조건 증가하므로 AC "불필요한 스프링 재생 없음"과 정면 충돌한다.
- 위 외 기존 코드 삭제 없음 (`nextHigherStage`/`nextLowerStage`는 그대로 유지)

---

## 기술적 결정사항

### 상태 관리

- **`dragOffset`을 `@State` → `@GestureState`로 전환**: spec "무엇이 잘못될 수 있는가" 3번(제스처 취소 시 `dragOffset` 잔류)의 근본 원인은 `onEnded`가 호출되지 않는 경로가 실재한다는 점이다. `@GestureState`는 제스처가 어떤 이유로 끝나든 SwiftUI 런타임이 초기값으로 되돌려주므로 "리셋 누락"이 구조적으로 불가능해진다. (대안: `onEnded` 외에 타이머/`onDisappear` 등으로 방어 → 우회책이며 CLAUDE.md "근본 원인 수정" 원칙 위배)
- **`@GestureState`에 `resetTransaction: Transaction(animation: .tabiSpring)` 지정**: 지정하지 않으면 리셋이 애니메이션 없이 즉시 일어나 손가락을 뗀 순간 시트가 "툭" 튄다(현재 `settleTrigger`가 담당하던 역할의 대체). 이 한 줄로 스냅백 애니메이션과 `settleTrigger` 제거가 동시에 성립한다.
- **`isDragging`도 `@GestureState`로 전환하고, 콜백 호출은 `.onChange(of:)`의 엣지에서 수행**: 현재 `onDragEnded()`는 `onEnded`에서만 호출되므로, 제스처가 취소되면 `MapView.isPanelDragging`이 `true`로 영구 고착된다. 이 플래그는 `MapView`에서 키보드 높이 갱신(`keyboardWillChangeFrame`/`keyboardWillHide`)을 막는 가드로 쓰이므로, 고착되면 이후 키보드 레이아웃이 영원히 갱신되지 않는 2차 버그가 된다. `@GestureState` + `onChange(false→true / true→false)` 구조로 두 엣지 모두 취소 상황에서도 보장한다.
- **`displayedStage`는 `@State` 유지**: 드래그 종료 후에도 유지되어야 하는 값이라 `@GestureState` 대상이 아니다.

### 임계값 설계

- **방향별 비대칭 임계값 4개로 분리**: spec 제약 "아래 방향 임계값 > 위 방향 임계값"을 상수 구조 자체로 강제한다. 하나의 값(`minimumMeaningfulDrag`, `fastFlickVelocityThreshold`)을 양방향이 공유하는 현재 구조로는 비대칭 표현이 불가능하다.
  - `upwardMinimumDrag` / `upwardFlickVelocity` — 낮게 (올릴 때 민감)
  - `downwardMinimumDrag` / `downwardFlickVelocity` — 높게 (내릴 때 까다롭게)
- **`downwardMinimumDrag`는 `dragHandleTouchPadding`(20)보다 반드시 크게**: spec "무엇이 잘못될 수 있는가" 2번. 현재 `minimumMeaningfulDrag = 12`는 핸들 터치 패딩(상하 각 20pt, 총 히트영역 44pt) 안에서 손가락이 자연스럽게 미끄러지는 거리보다 작아, "탭하려다 살짝 미끄러진 것"까지 유효 드래그로 오판한다. `upwardMinimumDrag`도 최소 패딩 이상으로 두되 `downwardMinimumDrag`보다는 작게 잡는다.
- **시작 제안값(구현 단계에서 실기기 감각으로 조율, spec에서 수치 미확정 명시)**
  - `upwardMinimumDrag = 24`, `upwardFlickVelocity = 350`
  - `downwardMinimumDrag = 44`, `downwardFlickVelocity = 900`
  - 관계식 `upwardMinimumDrag < downwardMinimumDrag`, `upwardFlickVelocity < downwardFlickVelocity`, `downwardMinimumDrag > dragHandleTouchPadding`는 조율 후에도 반드시 유지

### 판정 로직

- **"거리 OR 속도" 단일 술어 + 단일 전이 경로로 재구성**: 현재는 `guard velocity ... else { 전이 }` → `guard translation ... else { 스냅백 }` → `guard let nextStage else { ... }` 3중 guard가 각자 다른 결말(전이/스냅백/dismiss)을 갖고 있어, **속도 가지가 stage 경계 검사를 건너뛴다.** 이것이 spec 1번 버그(full에서 빠르게 내리면 즉시 완전 닫힘)의 직접 원인이다:
  ```
  guard velocity < 800 else { onDismiss(); return }   // ← nextLowerStage를 아예 보지 않음
  ```
  재구성 방향: `shouldAdvance = (거리 임계 초과) || (속도 임계 초과)`를 먼저 계산 → `false`면 스냅백 후 종료 → `true`일 때만 `nextLowerStage`/`nextHigherStage`를 조회 → 다음 단계가 있으면 전이, 없을 때만(하강 한정) `onDismiss()`.
- **`onDismiss()`는 "`.collapsed`에서 하강 임계를 넘겼을 때"라는 단 하나의 경로에서만 호출**: 속도 가지에도 dismiss 경로가 중복 존재하는 현재 구조를 제거해, AC 1번("collapsed에서 다시 한번 아래로 유의미하게 드래그해야만 dismiss")을 코드 구조로 보장한다.
- **`onStageChanged`는 `displayedStage`가 실제로 바뀔 때만 호출**: 현재 상향 속도 가지는 `nextHigherStage(...) ?? self.displayedStage`로 폴백하기 때문에 이미 `.full`인 상태에서 위로 플릭해도 `onStageChanged(.full)`이 호출된다(값은 동일하지만 불필요한 store 왕복). spec의 "스냅백 시에는 호출 안 함" 조건에 맞춰 전이 성사 시에만 호출한다.
- **"올릴 때 둔감"은 다단계 점프가 아니라 임계값 인하로 해결**: spec의 불변 조건이 "단계를 건너뛰지 않음"을 명시하므로, 빠른 상향 플릭에서 `collapsed → full` 2단계 점프를 구현하지 않는다. 체감 개선은 `upwardFlickVelocity`(800 → 350)와 상대적으로 낮은 `upwardMinimumDrag`로 확보한다.
- **`nextHigherStage`/`nextLowerStage` 헬퍼는 그대로 유지**: 인접 단계 전이라는 불변 조건을 표현하는 유일한 지점이며, 판정 로직이 바뀌어도 이 매핑 자체는 변하지 않는다.

### 애니메이션 / 떨림 제거

- **`.animation` 모디파이어를 `value: displayedStage` 하나로 축소**: 위 "삭제" 항목 참조. 같은 지오메트리에 걸리는 애니메이션 소스를 1개로 줄이는 것이 jitter 제거의 핵심이다.
- **드래그 중 손가락 추종은 비-애니메이션 유지**: `dragOffset`은 `.animation(_:value:)` 키에 포함시키지 않는다. 포함하면 매 프레임 스프링이 재시작되어 spec 3번(미세 오르내림 시 떨림)이 오히려 악화된다. 스프링은 "종료 시 정착"에만 관여한다(= `resetTransaction` + `displayedStage` 변경).
- **`.onChange(of: self.stage)`에 드래그 중 가드 추가**: 드래그 도중 상위 `MapFeature`가 `panelStage`를 바꾸면(예: `.mapDragged` → `.collapsed`) `displayedStage`가 손가락과 무관하게 튄다. 드래그 중에는 외부 stage 반영을 보류하고, 값이 실제로 다를 때만 대입한다(동일 값 재대입으로 인한 불필요한 무효화 방지).
- **오버드래그 클램프(`max(0, ...)`)는 이번 범위에서 유지**: `.full`에서 더 위로 끌면 시트가 멈추는 "데드존"이 있으나 떨림의 원인은 아니고, 러버밴딩 도입은 spec 범위 밖이다. 리스크 항목에만 기록한다.

### 범위 통제

- **`MapFeature`(TCA State/Action/Reducer) 무수정**: spec 제약. 이번 변경은 전부 View 로컬 상태 문제이며, stage 결정 로직이 이미 View → `panelDragEnded` → State 단방향으로 흐르고 있어 Reducer를 건드릴 이유가 없다.
- **`MapSearchPanelView`의 `init` 파라미터 무수정**: spec 제약. 상수 재구성과 상태 타입 변경은 모두 `private`/파일 내부 범위라 외부 API에 노출되지 않는다.
- **UIKit 미도입**: spec 제약(1차안). `UIPanGestureRecognizer` 하이브리드는 이 플랜으로 AC를 만족하지 못할 경우의 후속 spec 대상이다.

---

## 구현 순서

### Phase 1. 임계값 상수 재구성

1. `MapSearchPanelView.swift` 상단 `private enum MapSearchPanelLayout` 수정
   - `dragHandleSize`, `dragHandleTouchPadding` 유지
   - `fastFlickVelocityThreshold`, `minimumMeaningfulDrag` 제거 → 방향별 4개 상수로 대체
     - `upwardMinimumDrag`, `upwardFlickVelocity`, `downwardMinimumDrag`, `downwardFlickVelocity`
   - 각 상수 위에 "위/아래 비대칭 이유"와 "`downwardMinimumDrag > dragHandleTouchPadding` 관계가 깨지면 안 됨"을 한 줄 주석으로 남긴다
   - 정렬용 다중 공백 금지 (`swift-style.md` 2번)

### Phase 2. 상태 선언 전환

1. `@State private var dragOffset: CGFloat = 0` → `@GestureState`로 변경
   - 초기값 `0`, `resetTransaction`에 `.tabiSpring` 애니메이션을 갖는 `Transaction` 지정
2. `@State private var isDragging: Bool = false` → `@GestureState`로 변경 (초기값 `false`)
   - 이름은 역할이 드러나도록 조정 가능(예: `isDragActive`), Bool 프리픽스 규칙(`is`) 유지
3. `@State private var settleTrigger: Int = 0` 삭제
4. `displayedStage`는 `@State` 그대로 유지
5. 파생 프로퍼티(`baseHeight`, `currentHeight`, `hiddenOffset`)는 로직 변경 없음 — `dragOffset` 참조 방식만 그대로 동작하는지 확인

### Phase 3. 제스처 구성 변경

1. `dragGesture()` 재작성
   - `.updating($dragOffset)`에서 `value.translation.height`를 반영 (손가락 추종)
   - `.updating($isDragActive)`에서 `true` 반영 (제스처 활성 플래그)
   - `.updating` 클로저 안에서는 **외부 상태 변경/콜백 호출을 하지 않는다** (뷰 업데이트 중 상태 변경 경고 회피)
   - `.onEnded`에서는 `handleDragEnded(translation:velocity:)`만 호출 — `dragOffset = 0` 수동 대입 제거(`@GestureState`가 담당), `isDragging` 수동 대입 제거
2. `body`에 `.onChange(of: isDragActive)` 추가
   - `false → true`: `onDragStarted()` 호출
   - `true → false`: `onDragEnded()` 호출
   - 이 경로가 제스처 취소 시에도 `MapView.isPanelDragging`을 반드시 해제한다
3. `dragHandle()`의 `.contentShape(Rectangle())` / 패딩 / `.gesture(...)` 부착 구조는 유지

### Phase 4. 드래그 종료 판정 로직 재작성

1. `handleDragEnded(translation:velocity:)`
   - `dragOffset = 0` 대입 제거
   - `translation > 0` → 하강, 그 외 → 상승 분기 유지
2. `handleUpwardDragEnded(translation:velocity:)` 재작성
   - `shouldAdvance = (translation <= -upwardMinimumDrag) || (velocity <= -upwardFlickVelocity)`
   - `shouldAdvance == false` → 아무것도 하지 않고 종료 (스냅백은 `resetTransaction`이 처리, `onStageChanged` 미호출)
   - `nextHigherStage(from: displayedStage)`가 `nil`(이미 `.full`) → 아무것도 하지 않고 종료
   - 그 외 → `displayedStage = nextStage`, `onStageChanged(nextStage)`
3. `handleDownwardDragEnded(translation:velocity:)` 재작성
   - `shouldAdvance = (translation >= downwardMinimumDrag) || (velocity >= downwardFlickVelocity)`
   - `shouldAdvance == false` → 아무것도 하지 않고 종료 (스냅백)
   - `nextLowerStage(from: displayedStage)`가 `nil`(이미 `.collapsed`) → **여기서만** `onDismiss()` 호출
   - 그 외 → `displayedStage = nextStage`, `onStageChanged(nextStage)`
   - **속도 가지에서 stage 경계를 건너뛰고 dismiss하던 기존 `guard`를 완전히 제거했는지 반드시 확인** (spec 1번 버그의 직접 원인)
4. `nextHigherStage` / `nextLowerStage`는 무수정
5. 세 메서드 모두 기존대로 `// MARK: - Method` + `private extension MapSearchPanelView` 안에 유지 (`swift-style.md` 3번/7번)

### Phase 5. body 애니메이션 정리

1. `.animation(.tabiSpring, value: self.settleTrigger)` 제거
2. `.animation(.tabiSpring, value: self.displayedStage)` 유지 (단일 소스)
3. `.onChange(of: self.stage)` 수정
   - 드래그 활성 중이면 반영 보류
   - `newValue != displayedStage`일 때만 대입
4. `.offset(y: self.hiddenOffset)` 등 나머지 레이아웃 구성은 무수정

### Phase 6. 호출부 정합성 확인 (읽기 전용)

1. `Projects/Presentation/Sources/Map/MapView.swift`의 `searchPanel()` 호출부가 **수정 없이 그대로 컴파일되는지** 확인 — `init` 시그니처를 건드리지 않았다면 무수정이어야 함 (spec 제약)
2. `onDragStarted`가 `isSearchFieldFocused = false`를 수행하는 타이밍이 `.onChange` 경유로 한 프레임 늦어질 수 있음 — 키보드 내려감 타이밍이 드래그 시작과 어긋나 보이지 않는지 실기기 확인
3. `MapFeature`는 무수정임을 diff로 재확인

### Phase 7. 빌드 및 수동 검증

1. 신규 파일이 없으므로 `tuist generate` 불필요 — 다만 이전 작업으로 미반영 신규 파일이 남아 있으면(현재 워킹트리에 `TravelPlanDetail` 관련 미추적 파일 존재) 빌드 실패 원인이 될 수 있으므로, 빌드 에러 발생 시 이 변경과 무관한지 먼저 판별
2. `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`
   - 메모리상 iPhone 16 Pro 시뮬레이터 미설치 → destination은 설치된 기기명으로 확인 후 사용
3. 시뮬레이터/실기기 수동 시나리오 (AC 대응, 전부 육안 검증 항목)
   - `full`에서 빠른 하향 플릭 → `half`까지만 (dismiss 안 됨)
   - `half`에서 하향 → `collapsed`, `collapsed`에서 다시 하향 유의미 드래그 → dismiss
   - `collapsed`에서 아주 짧은(20pt 미만) 하향 슬립 → 스냅백, dismiss 안 됨
   - 동일 거리/속도의 상향 드래그가 하향보다 쉽게 전이되는지 비교
   - 핸들을 잡고 수 pt 단위로 천천히 흔들기 → 떨림/튐 없이 추종
   - 드래그 도중 홈 인디케이터 스와이프/알림 배너 등으로 제스처 인터럽트 → 잔류 오프셋 없이 정착, 이후 키보드 동작 정상
   - 느린 드래그로 `collapsed → half → full` 순차 이동 회귀 확인
4. 임계값이 과하다고 느껴지면 Phase 1 상수만 조정 후 재검증 (관계식 유지)

---

## 리스크 / 확인 필요

- **`@GestureState`의 `resetTransaction`이 실제로 스프링 스냅을 만들어내는지 실기 확인 필요**: 리셋 시점과 `displayedStage` 변경 시점이 같은 프레임이 아니면 오히려 2단 모션으로 보일 수 있다. 어긋난다면 `onEnded` 안에서 `withTransaction`/`withAnimation`으로 `displayedStage` 변경을 감싸 타이밍을 맞추는 조정이 필요하다.
- **`.updating` 클로저에서 콜백을 호출하지 않는 제약**: `onDragStarted`/`onDragEnded` 호출을 `.onChange(of:)`로 옮기면 호출 시점이 한 업데이트 사이클 늦어진다. `MapView`가 `onDragStarted`에서 키보드를 내리므로(`isSearchFieldFocused = false`) 체감 지연이 있는지 확인 — 문제가 되면 `onDragStarted`만 `.onChanged` 최초 1회 호출로 되돌리고 `onDragEnded`만 `.onChange` 엣지로 두는 절충안을 쓴다(취소 안전성은 `onDragEnded` 쪽이 핵심이므로 이 절충으로도 목적 달성).
- **키보드 내려감이 제스처 취소의 실제 유발원일 가능성**: 드래그 시작 → 포커스 해제 → 키보드 dismiss로 레이아웃이 크게 흔들리며 제스처가 끊길 수 있다. 이 경로가 spec 3번 버그의 재현 시나리오일 수 있으므로, 검증 시 "키보드가 올라온 typing 모드에서 드래그 시작"을 반드시 포함한다.
- **임계값 상향의 회귀 위험**: `downwardMinimumDrag`를 44까지 올리면 `collapsedHeight`(최대 140pt)가 작은 기기에서 "내릴 여유 거리"가 부족해 조작이 먹통처럼 느껴질 수 있다. spec "무엇이 잘못될 수 있는가" 5번에 해당 — 작은 화면 기기에서 반드시 확인하고, 필요 시 `downwardMinimumDrag`를 32 수준까지 낮춘다(단 `> 20` 유지).
- **`velocity` 부호 규약 재확인**: `DragGesture.Value.velocity.height`는 아래로 이동 시 양수, 위로 이동 시 음수다. 상향 판정에서는 `velocity <= -upwardFlickVelocity`, 하향 판정에서는 `velocity >= downwardFlickVelocity` 형태여야 한다. 기존 코드가 `guard`의 else 가지에 조건을 뒤집어 넣는 구조라 옮겨 적을 때 부호 실수가 나기 쉬운 지점.
- **오버드래그 데드존**: `hiddenOffset`이 `max(0, ...)`로 클램프되어 `.full`에서 더 위로 끌면 시트가 멈춘다. 러버밴딩은 이번 범위 밖이지만, "떨림"으로 오인 보고될 수 있으니 검증 시 구분해서 판단한다.
- **`displayedStage` 로컬 갱신과 store 라운드트립의 경합**: View가 `displayedStage`를 먼저 바꾸고 `onStageChanged` → `panelDragEnded` → `state.panelStage` → `stage` prop → `.onChange` 순으로 되돌아온다. Phase 5의 "값이 다를 때만 대입" 가드가 빠지면 같은 값 재대입으로 불필요한 무효화가 발생한다.
- **1차안으로 해결되지 않을 가능성**: 순수 SwiftUI `DragGesture`는 상위 `ScrollView`/`NavigationStack` 인터랙티브 팝 제스처와의 경합 제어권이 제한적이다. Phase 7 검증에서 떨림이나 취소가 남는다면, 이 플랜의 결과와 재현 조건을 기록한 뒤 `UIPanGestureRecognizer` 하이브리드 후속 spec으로 넘긴다 (spec 명시, 이번 범위에서 UIKit 도입 금지).
- **테스트 타겟 부재**: 이 레포에는 테스트 타겟이 없고(`CLAUDE.md`), 변경 대상도 View 로컬 상태라 TCA `TestStore`로 검증할 수 없다. 검증은 전적으로 수동 시나리오에 의존한다는 점을 인지하고 Phase 7을 생략하지 않는다.

---

## 완료 조건
- [ ] Spec Acceptance Criteria 7개 항목 충족
- [ ] `full`에서 빠른 하향 플릭 시 `half`로만 이동하고 `onDismiss()`가 호출되지 않는다
- [ ] `onDismiss()` 호출 경로가 코드상 "`.collapsed`에서 하향 임계 초과" 단 한 곳뿐이다
- [ ] `downwardMinimumDrag > dragHandleTouchPadding`, `upwardMinimumDrag < downwardMinimumDrag`, `upwardFlickVelocity < downwardFlickVelocity` 관계가 상수 정의에서 성립한다
- [ ] `dragOffset` / 드래그 활성 플래그가 `@GestureState`로 관리되어 제스처 취소 시 자동 복귀한다
- [ ] 제스처 취소 후에도 `MapView.isPanelDragging`이 `false`로 해제되어 키보드 높이 갱신이 정상 동작한다
- [ ] `settleTrigger`와 `.animation(.tabiSpring, value: settleTrigger)`가 제거되고, 패널 지오메트리에 걸리는 `.animation` 소스가 `displayedStage` 하나로 단일화되었다
- [ ] 스냅백(stage 미변경) 케이스에서 `onStageChanged`가 호출되지 않는다
- [ ] `MapSearchPanelView`의 `init` 파라미터와 콜백 시그니처가 변경되지 않아 `MapView.swift`가 무수정이다
- [ ] `MapFeature.swift`(State/Action/Reducer)가 무수정이다
- [ ] UIKit 타입(`UIPanGestureRecognizer`/`UIViewRepresentable`)이 `MapSearchPanelView.swift`에 도입되지 않았다
- [ ] 신규 애니메이션 정의 없이 `.tabiSpring`만 사용한다
- [ ] AppDebug 스킴 빌드 성공
