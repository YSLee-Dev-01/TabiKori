# MapView 검색 패널 — 시스템 `.sheet` + 별도 오버레이 → 통합 커스텀 바텀시트 전환

## Context

`Projects/Presentation/Sources/Map/MapView.swift`에는 검색 관련 UI가 현재 **두 개의 서로 다른 메커니즘**으로 나뉘어 있음:

1. `mode == .result`(검색 결과) — 시스템 `.sheet(isPresented: .constant(store.mode == .result))` (90행)
2. `mode == .typing`(최근 검색) — `ZStack` 안 인라인 오버레이 `recentSearchPlaceholder()` (66-69행, 175-196행), 시트가 아니라 항상 topBar 아래부터 화면 하단까지 고정 높이로 뜨는 카드형 뷰. `panelStage`(`collapsed/half/full`) 개념이 적용되지 않고 드래그도 불가능함.

문제점:

1. **탭바가 가려짐** — 시스템 `.sheet`는 UIKit 레벨 모달로 window 전체 위에 떠서 `TabBarView`의 tabItem까지 덮음. `presentationDetents`/`presentationBackgroundInteraction` 같은 modifier로는 근본적으로 해결 불가 (프레젠테이션 계층 자체의 한계).
2. **dismiss 애니메이션 지연** — `isPresented: .constant(...)`로 `mode` 값에 따라 시트가 매번 파괴/재생성됨. `TabBarFeature`에서 검색결과 → Detail push 시 `mode = .map`으로 바뀌며 시트가 destroy되고, Detail에서 뒤로가기(`popFrom`) 시 `mapState.mode = .result`로 복원되며 시트가 다시 create됨 — 이 두 시스템 트랜잭션(네비게이션 pop 애니메이션 + 시트 재생성)이 경합해 재표시가 늦어짐.
3. **`interactiveDismissDisabled()`가 걸려있어 제스처로 못 내림** — 요구사항(제스처 드래그 dismiss)과 정반대 상태.
4. **최근검색과 결과 화면의 UI 메커니즘이 이원화** — 같은 "검색 패널"인데 하나는 시트, 하나는 고정 오버레이라 배경 처리·모서리·애니메이션 코드가 중복되고 동작도 불일치 (최근검색은 드래그/단계 조절이 아예 안 됨).

**해결 방향**: 두 케이스(`.typing`, `.result`) 모두 `MapView.body`에 직접 붙는 **하나의 커스텀 드래그 가능 바텀시트 컴포넌트**로 통합. `.overlay`/`ZStack`은 탭 콘텐츠 프레임 내부에 그려지므로 tabItem을 가리지 않고, 순수 SwiftUI 상태 기반 애니메이션이라 네비게이션 pop과 경합하지 않음. 기존 `MapPanelStage`(`.collapsed/.half/.full`)와 `panelDragEnded` 액션, 높이 계산 로직(`baseCollapsedHeight/baseHalfHeight/baseFullHeight`)은 그대로 재사용하고, 패널 내부에 표시되는 콘텐츠만 `mode`에 따라 최근검색 ↔ 검색결과로 스위칭 — TCA State/Action/Reducer 변경 없이 View 레이어 교체만으로 충분함.

## 재사용할 기존 요소

- `MapFeature.State.mode`(`.map/.typing/.result`), `.panelStage`(`.collapsed/.half/.full`) — 그대로 사용
- `Action.panelDragEnded(MapPanelStage)`, `.searchCancelTapped` — 그대로 사용 (Reducer 로직 변경 없음)
- `MapView`의 `baseCollapsedHeight`/`baseHalfHeight`/`baseFullHeight` 계산 프로퍼티 — 커스텀 패널의 타겟 높이로 재사용
- `searchResultContent()`, `recentSearchPlaceholder()` 내부의 `MapRecentSearchPlaceholderView`/`MapRecentSearchListView` — 패널 내부 콘텐츠로 그대로 재사용 (두 컴포넌트 자체는 변경 없음, chrome만 걷어냄)
- `DesignSystem` 토큰: `TabiColor.tabiSurface`(배경), `TabiColor.tabiBorder`(테두리, `TabiCard` 참고), `.tabiRadiusXl`(모서리), `.tabiSpring`/`.tabiStandard`(애니메이션) — 새 색상/애니메이션 추가하지 않음
- `resetSearchState` 등 Reducer 로직 불변

## 구현 단계

### 1. `MapView.swift` — 기존 두 메커니즘 제거

- `.sheet(isPresented: .constant(self.store.mode == .result)) { self.searchResultSheet() }` 삭제
- `panelStageBinding`(32-53행) 삭제 — `PresentationDetent` 매핑은 더 이상 필요 없음 (드래그 제스처가 직접 높이를 다룸)
- `searchResultSheet()`의 `presentationDetents/presentationDragIndicator/presentationBackgroundInteraction/presentationCornerRadius/interactiveDismissDisabled` modifier 삭제
- `body`의 `if self.store.mode == .typing { self.recentSearchPlaceholder() ... }` 블록(66-69행) 삭제 — 최근검색도 동일한 패널 컴포넌트로 흡수
- `recentSearchPlaceholder()`(175-196행)에서 chrome(`.background(Color.white)`, `.clipShape`, `.padding(.top, topBarHeight)`, `ignoresSafeArea`)은 제거하고, 내부의 `Group { if recentSearches.isEmpty { Placeholder } else { ListView } }` 분기만 새 콘텐츠 함수로 남김 — chrome은 2번의 공용 패널 컴포넌트가 전담

### 2. 새 파일 `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`

`.typing`/`.result` 공통으로 쓰는 **하나의** 드래그 가능 바텀시트 컨테이너 (이름에서 "Result"를 빼서 범용화):

- 상단 드래그 핸들(작은 `Capsule`) — 기존 시스템 `presentationDragIndicator(.visible)` 대체
- `UnevenRoundedRectangle(topLeadingRadius: .tabiRadiusXl, topTrailingRadius: .tabiRadiusXl)`로 위쪽만 라운드, 배경은 `TabiColor.tabiSurface` (기존 최근검색의 `Color.white`는 이 토큰으로 통일 — 두 화면이 같은 배경색을 쓰도록 정리)
- `@ViewBuilder content: () -> Content` — `MapView`가 `mode`에 따라 최근검색 콘텐츠 또는 검색결과 콘텐츠를 주입
- 드래그 제스처 처리:
  - `@GestureState private var dragTranslation: CGFloat`로 실시간 오프셋 추적
  - 높이 = 현재 `panelStage`에 대응하는 base 높이 − `dragTranslation`(아래로 끌면 감소), 0 이상으로 clamp
  - `.onEnded`: 최종 높이가 `baseCollapsedHeight / 2` 미만이면 **완전 dismiss로 간주** → cancel과 동일한 콜백 호출 (요구사항 1). `.typing`에서 dismiss되면 `searchCancelTapped`가 `mode = .map`으로 되돌리므로 최근검색 패널도 동일하게 닫힘 (Reducer 변경 불필요)
  - 그 외에는 `[collapsed, half, full]` 중 최종 높이와 가장 가까운 stage로 스냅 → `panelDragEnded(stage)`와 동일한 콜백 호출
- Store 직접 참조 대신 필요한 값(base 높이 3종, 현재 `panelStage`, content, `onDismiss`/`onStageChanged` 콜백)을 파라미터로 받아 `.typing`/`.result` 양쪽에서 재사용 (swift-style 접근 제어/역할 분리 원칙에 맞춤)

### 3. `MapView.swift` — 오버레이로 연결 (모드 스위칭 포함)

`MapView.body`에 `.overlay(alignment: .bottom)`로 `MapSearchPanelView`를 `mode == .typing || mode == .result`일 때 표시하고, 내부 콘텐츠만 모드에 따라 전환:

```swift
.overlay(alignment: .bottom) {
    if self.store.mode == .typing || self.store.mode == .result {
        self.searchPanel()
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
.animation(.tabiStandard, value: self.store.mode)
```

```swift
func searchPanel() -> some View {
    MapSearchPanelView(
        stage: self.store.panelStage,
        collapsedHeight: self.baseCollapsedHeight,
        halfHeight: self.baseHalfHeight,
        fullHeight: self.baseFullHeight,
        onStageChanged: { stage in self.store.send(.panelDragEnded(stage)) },
        onDismiss: { self.cancelSearch() }
    ) {
        if self.store.mode == .typing {
            self.recentSearchContent()   // 기존 recentSearchPlaceholder()의 분기 로직만
        } else {
            self.searchResultContent()   // 기존 그대로
        }
    }
}
```

- 취소 버튼(`searchCancelButton`)과 드래그-dismiss가 동일 동작을 타도록, 기존 `Button` 액션(`lastTappedSpotID = nil; store.send(.searchCancelTapped)`)을 `cancelSearch()`라는 private 메서드로 추출해 두 경로(버튼 탭, 드래그 dismiss)에서 공통 호출 (요구사항 1 충족, 중복 제거)
- `mode`가 `.map → .typing`, `.typing → .result`로 바뀌어도 패널 자체(컨테이너)는 사라지지 않고 내부 콘텐츠만 교체되므로, 검색어 입력 중 → 결과 표시 전환 시 패널이 한 번 닫혔다 다시 뜨는 깜빡임 없이 자연스럽게 이어짐 (기존엔 서로 다른 두 메커니즘이라 전환 시 한쪽이 사라지고 다른 쪽이 나타나는 방식이었음)
- 키보드 관련: `.typing` 모드에서는 검색 필드가 포커스되어 키보드가 뜨므로, 콘텐츠 내부(`MapRecentSearchPlaceholderView`는 이미 `keyboardHeight` 파라미터로 하단 패딩 처리 중 — 그대로 유지)에서 키보드를 고려. 패널 컨테이너 자체의 높이 계산(`baseFullHeight` 등)은 키보드와 무관하게 유지 (기존 동작 유지, 새로 손댈 필요 없음)

### 4. 배경 인터랙션 관련 (기존 `presentationBackgroundInteraction` 대체)

시스템 시트와 달리 커스텀 오버레이는 `.full` 단계에서 이미 패널이 화면 상단(topBar 아래)까지 꽉 채우므로, 별도 스크림/터치 차단 로직 없이도 자연스럽게 지도가 안 보이고 안 눌림. `.collapsed`/`.half` 단계에서는 패널이 하단 일부만 차지하므로 지도 상단 영역은 자동으로 인터랙티브함 — 시스템 시트의 `upThrough: .height(baseHalfHeight)` 동작과 동일한 결과를 별도 코드 없이 얻음. `.typing` 모드도 동일 규칙 적용.

### 5. TCA 변경사항 없음

`MapFeature.swift`의 `mode`/`panelStage` 전이 로직(`searchFieldTapped`, `searchCancelTapped`, `searchSubmitted`, `categorySelected`, `searchResultTapped`, `panelDragEnded`)과 `TabBarFeature`의 push/pop 복원 로직(`mapSearchDetailID` 추적 후 해당 id pop 시 `mapState.mode = .result` 복원)은 그대로 유지. `panelStage`는 Detail push 전 값이 유지된 채로 복원되는 기존 동작도 그대로.

### 6. `tuist generate`

새 파일(`MapSearchPanelView.swift`) 추가 후 `tuist generate` 필수 (CLAUDE.md 규칙).

## 검증 방법

테스트 타겟이 없는 프로젝트이므로 시뮬레이터 실행으로 시나리오별 육안 확인:

1. 검색창 탭(최근검색) / 검색 실행(결과) 상태 모두에서 **탭바가 계속 보이는지** 확인 (핵심 요구사항 3)
2. 패널을 손가락으로 collapsed ↔ half ↔ full 사이 드래그 → 최근검색·검색결과 양쪽 모두 자연스럽게 스냅되는지 확인 (요구사항 2)
3. 패널을 collapsed 아래로 완전히 끌어내림 → 최근검색/검색결과 어느 상태에서든 취소 버튼을 눌렀을 때와 동일하게 초기화되고 지도 모드로 돌아가는지 확인 (요구사항 1)
4. 검색창 탭 → 최근검색 패널 뜸 → 검색어 입력 → 결과 패널로 전환 시 깜빡임 없이 이어지는지 확인
5. 검색 결과 셀 탭 → Detail push → 뒤로가기 → 패널이 지연 없이 즉시 half 단계로 재표시되는지 확인 (기존 dismiss 지연 버그 해소 확인)
6. `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 17'`로 빌드 성공 확인 (시뮬레이터명은 `project_simulator_iphone17` 메모리 기준)
