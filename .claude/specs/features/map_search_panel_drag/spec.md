# MapSearchPanelView 드래그 제스처 로직 개선 (1차: 순수 SwiftUI)

## 무엇을 하는가

`Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift`의 커스텀 바텀시트는 핸들을 드래그해 `collapsed/half/full` 3단계로 오르내리거나 완전히 닫을 수 있어야 한다. 현재는 아래 세 가지 UX 결함이 있어, 로직 수정을 통해 "내릴 때는 신중하게, 올릴 때는 즉각적으로, 드래그 중에는 안정적으로" 반응하도록 만든다.

1. 내릴 때 과민 — 핸들을 아주 조금만 내려도 즉시 완전히 닫혀버림
2. 올릴 때 둔감 — 빠르게 위로 플릭해도 한 단계씩만 올라감
3. 핸들을 잡고 미세하게 오르내릴 때 시트가 떨림(jitter)

이번 스펙은 UIKit 전환 없이 **순수 SwiftUI 상태/로직 수정만으로** 해결을 시도하는 1차안이다. 이 방식으로 해결되지 않을 경우, `UIPanGestureRecognizer` 기반 하이브리드 전환은 별도 후속 spec으로 다룬다 (이번 범위 아님).

## 동작 명세

- 트리거: 사용자가 `MapSearchPanelView` 상단 드래그 핸들(`dragHandle()`)을 `DragGesture`로 드래그
- 결과:
  - 위로 드래그 종료 시: 이동 거리 또는 속도가 임계값을 넘으면 `displayedStage`가 `collapsed → half → full` 중 한 단계 상승, 아니면 원래 단계로 스냅백
  - 아래로 드래그 종료 시: 이동 거리 또는 속도가 임계값을 넘으면 `displayedStage`가 `full → half → collapsed` 중 한 단계 하강, `collapsed`에서 더 내려갈 곳이 없을 때만 `onDismiss()` 호출. 아니면 원래 단계로 스냅백
  - 위/아래 임계값은 비대칭 — 아래 방향(닫힘 쪽)의 최소 이동 거리·속도 임계값이 위 방향(열림 쪽)보다 더 크게 설정되어, "내릴 때 더 까다롭게 / 올릴 때 더 민감하게" 체감되어야 함
  - 제스처가 정상 종료(`onEnded`)든 시스템에 의해 취소되든, 종료 시점에 `dragOffset`은 항상 0으로 복귀하고 시트는 `displayedStage`에 대응하는 높이로 스프링 애니메이션과 함께 정착
  - 핸들을 잡고 미세하게(수 pt 단위) 오르내리는 동안에는 매 프레임 손가락 위치를 즉시(비-애니메이션) 추종하며, 떨림/튐 없이 부드럽게 이동
- 사이드이펙트: 없음 (네트워크/DB/이벤트 방출 없음, 순수 View 레이어 상태 변경). `onStageChanged`/`onDismiss` 콜백을 통해 `MapFeature`에 `panelDragEnded`/`searchCancelTapped` 액션 전달 — 기존 콜백 시그니처와 호출 조건(스냅된 최종 stage일 때만 호출, 스냅백 시에는 호출 안 함)은 변경하지 않음
- 불변 조건:
  - `displayedStage`는 항상 `MapPanelStage`(`.collapsed/.half/.full`) 중 하나이며, 드래그 도중에도 `nextHigherStage`/`nextLowerStage`가 정의한 인접 단계로만 전이 (단계를 건너뛰지 않음)
  - 드래그가 끝나 스냅이 완료된 상태에서 `dragOffset`(혹은 이를 대체하는 상태)은 0

## 무엇이 잘못될 수 있는가

- 아래 방향 빠른 플릭 시 현재 단계와 무관하게 즉시 `onDismiss()` 호출 → 의도치 않은 완전 닫힘 (현재 버그, 이번에 수정 대상)
- `minimumMeaningfulDrag`가 핸들 터치 패딩보다 작게 설정 → 미세한 우발적 터치도 "의미 있는 드래그"로 오판 (현재 버그, 이번에 수정 대상)
- 드래그 제스처가 `onEnded` 없이 취소(시스템 인터럽트, 상위 뷰 competing gesture 등)되는 경우 `dragOffset`이 리셋되지 않고 잔류 → 다음 드래그 시작 시 시트가 튀거나 떨리는 것처럼 보임 (현재 버그, 이번에 수정 대상)
- `displayedStage`가 실제로 바뀌지 않았는데도 애니메이션 트리거(`settleTrigger`)가 증가 → 불필요한 스프링 재생이 진행 중인 애니메이션과 겹쳐 떨림 유발 (현재 버그, 이번에 수정 대상)
- 임계값 조정이 과도해 정상적인 드래그 조작(예: half → full로 올리려는 의도된 느린 드래그)까지 막히면 → 조작 불가능/먹통으로 체감 (회귀 위험, 수동 테스트로 확인 필요)

## 무엇에 의존하는가

### 의존성

- `Projects/Presentation/Sources/Map/Sub/MapSearchPanelView.swift` — 수정 대상 파일
- `Projects/Presentation/Sources/Map/Entity/MapPanelStage.swift` — `.collapsed/.half/.full` enum, 변경 없음
- `Projects/Presentation/Sources/Map/MapView.swift` — `MapSearchPanelView` 호출부 (`stage`, `collapsedHeight/halfHeight/fullHeight`, `onStageChanged`, `onDismiss`, `onDragStarted`, `onDragEnded` 콜백 시그니처를 그대로 유지해야 함, 변경 시 이 파일도 함께 검토)
- `Projects/DesignSystem/Sources/Style/TabiAnimation.swift`의 `tabiSpring` — 기존 애니메이션 커브 재사용, 새 애니메이션 정의 추가하지 않음

### 제약

- TCA State/Action/Reducer(`MapFeature`) 변경 없음 — View 레이어(`MapSearchPanelView`) 내부 로직 수정으로 범위 한정
- `MapSearchPanelView`의 public 이니셜라이저 파라미터(콜백 시그니처, 높이 파라미터) 변경 금지 — `MapView.swift` 호출부 수정 불필요해야 함
- UIKit `UIPanGestureRecognizer`/`UIViewRepresentable` 등 UIKit 요소 도입 금지 (1차안은 순수 SwiftUI 범위)
- `swift-style.md`: `@GestureState` 등 상태 관리 변경 시에도 MARK 섹션 구조(Properties/Init/View/Method) 및 접근 제어 규칙(private extension 분리) 유지
- 구체적인 임계값(pt, pt/s) 수치는 이 스펙에서 확정하지 않고 구현 단계에서 UX 감각에 맞춰 조율 — 단, "아래 방향 임계값 > 위 방향 임계값" 관계는 반드시 성립해야 함

## Acceptance Criteria

- [ ] `full` 상태에서 핸들을 빠르게 아래로 플릭해도 `half`로만 이동하고, `collapsed`에서 다시 한번 아래로 유의미하게 드래그(또는 빠른 플릭)해야만 `onDismiss()`가 호출된다
- [ ] `collapsed` 상태에서 핸들을 매우 짧게(터치 패딩 수준 이하) 아래로 미끄러뜨렸을 때는 dismiss되지 않고 원래 자리로 스냅백한다
- [ ] 동일한 조건(비슷한 거리/속도)으로 위로 드래그했을 때는 아래로 드래그했을 때보다 더 쉽게(더 짧은 거리 또는 더 낮은 속도로) 다음 단계로 전이된다
- [ ] 핸들을 잡고 아주 천천히 수 pt씩 위/아래로 흔들었을 때, 시트가 떨리거나 튀지 않고 손가락을 부드럽게 추종한다
- [ ] 드래그 도중 제스처가 취소되는 상황(예: 다른 제스처가 우선권을 가져가는 경우)에서도 시트가 잔류 오프셋 없이 정상 위치로 복귀한다
- [ ] `displayedStage`가 바뀌지 않는 드래그(스냅백 케이스)에서는 불필요한 스프링 애니메이션 재생이 발생하지 않는다
- [ ] 기존 정상 시나리오(느린 드래그로 collapsed→half→full 순차 이동, half→collapsed로 내리기)는 회귀 없이 그대로 동작한다
