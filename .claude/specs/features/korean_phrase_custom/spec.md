# korean_phrase_custom

## 무엇을 하는가
현재 한국어(일본어 포함) 문구 목록(`KoreanPhraseListView`)은 Firebase Realtime Database(`TabiKori/koreanPhrases`)에 등록된 문구만 보여준다 — 새 문구를 추가하려면 Firebase 콘솔에서 직접 데이터를 넣어야 한다. 사용자가 앱 안에서 직접 자신만의 문구(예: 여행 중 필요했던 표현)를 추가해 목록에서 함께 볼 수 있게 한다.

## 동작 명세
- 트리거: `KoreanPhraseListView` 네비게이션 바에 "+" 버튼 추가 → 탭 시 문구 입력 폼(일본어/한국어/발음, 발음은 선택) 표시
- 트리거: 입력 폼에 "번역" 버튼 추가 → 일본어 필드 입력 후 탭하면 Apple Translation 프레임워크(온디바이스)로 일본어→한국어 번역 실행, 결과를 한국어 필드에 자동 채움(사용자가 이후 직접 수정 가능)
- 결과:
  - 입력 폼에서 저장 시 커스텀 문구가 SwiftData에 로컬 저장되고, 목록에 즉시 반영됨
  - `KoreanPhraseListView`는 Firebase 문구 + 로컬 커스텀 문구를 하나의 목록으로 합쳐서 표시 (정렬/구분 방식은 plan 단계에서 결정)
  - 커스텀 문구는 스와이프 삭제 가능 (Firebase 문구는 기존과 동일하게 삭제 불가)
  - 커스텀 문구도 기존 문구와 동일하게 셀 탭 시 `KoreanPhraseDetailView`(가로모드 몰입 화면)로 진입, 복사 메뉴 동작
- 사이드이펙트: SwiftData write(신규 로컬 모델), 기존 Firebase `fetchPhrases()` 네트워크 호출은 그대로 유지
- 불변 조건: 커스텀 문구의 `id`는 Firebase 문구의 `id`와 절대 충돌하지 않음(로컬 전용 prefix 또는 UUID 사용), 앱 재실행 후에도 커스텀 문구는 유지됨

## 무엇이 잘못될 수 있는가
- 한국어 또는 일본어 필드를 비운 채 저장 시도 → 저장 버튼 비활성 또는 유효성 에러 (구체적 UX는 plan 단계에서 결정)
- SwiftData 저장 실패 → `AppLogger.core` 로깅, 에러 안내 후 폼 유지(입력값 보존)
- Firebase 문구 목록 로딩 실패 시(`hasLoadFailed`) 커스텀 문구만이라도 보여줄지, 기존처럼 전체 실패 처리할지 → plan 단계에서 결정
- 일본어 필드가 비어있는 상태로 "번역" 버튼 탭 → 번역 실행 안 함
- Translation 프레임워크 번역 실패(온디바이스 언어 모델 미다운로드, 세션 에러 등) → `AppLogger.view` 로깅, 에러 안내(한국어 필드는 비워둔 채 사용자가 직접 입력 가능)

## 무엇에 의존하는가

### 의존성
- Domain: `KoreanPhrase`에 `isCustom: Bool` 필드 추가 (기존 필드는 유지, `ToolBarPlanItem`/`TouristSpot`의 `isCustom` 패턴 참고)
- Domain: `KoreanPhraseRepositoryProtocol`에 로컬 CRUD 메서드 추가 (`addPhrase`, `deletePhrase` 등) 또는 별도 로컬 전용 Repository 신설 — plan 단계에서 구조 결정
- Domain: `KoreanPhraseUseCaseProtocol`/`KoreanPhraseUseCase`에 위 CRUD 메서드 반영, `TestKoreanPhraseUseCase`도 갱신
- Data: 신규 SwiftData 모델(`CustomKoreanPhraseModel` 등) + `{Name}ModelContainer` 등록, 매핑 Extension 추가 (`ToolBarPlanItemModel`/`ToolBarPlanItemModel+.swift` 패턴 참고)
- Presentation: `KoreanPhraseListFeature`/`KoreanPhraseListView`에 "+" 버튼, 입력 폼 진입/저장, 스와이프 삭제(커스텀 문구만) 로직 추가
- Presentation: 신규 입력 폼 Feature/View — DesignSystem 기존 `TabiTextField` 등 우선 재사용, "번역" 버튼 포함
- Presentation: 일본어→한국어 번역 실행은 기존 `TranslateSearchTaskModifier`(`translateSearchTask(pendingQuery:onResult:onFailure:)`)가 이미 동일 방향(`source: .japanese, target: .korean`)의 공용 Modifier로 존재하므로 그대로 재사용한다(Map/PlanDetailAddSpot/AddCustomPlace와 동일). 신규 Modifier를 만들지 않는다

### 제약
- `KoreanPhraseRepository`는 현재 `fetchPhrases()`만 정의되어 있고 Firebase 전용으로 설계됨 — 로컬 CRUD를 같은 Repository에 넣을지, `Domain`이 `Data`를 참조하지 않는 원칙 아래 별도 Repository로 분리할지 plan 단계에서 결정 필요
- Firebase 문구는 `FirebaseListCache`로 캐싱되는데, 로컬 커스텀 문구 추가/삭제 시 이 캐시와 별개로 목록을 갱신하는 흐름을 설계해야 함
- 커스텀 문구는 `order` 필드 의미가 Firebase 문구(관리자가 지정한 노출 순서)와 다름 — 병합 시 정렬 기준(예: 커스텀 문구는 항상 최상단/최하단에 별도 섹션) plan 단계에서 결정
- 편집(수정) 기능 포함 여부는 이번 스펙에서는 범위 외로 간주(추가/삭제만) — 필요 시 별도 논의
- Translation 프레임워크는 온디바이스 언어팩이 필요해 최초 사용 시 시스템이 다운로드를 요구할 수 있음(네트워크/시간 소요) — `TranslateSearchTaskModifier`를 그대로 재사용하므로 별도 처리 없이 시스템 기본 동작을 따름

## Acceptance Criteria
- [ ] `KoreanPhraseListView`에 "+" 버튼이 보이고, 탭하면 문구 입력 폼으로 진입한다
- [ ] 한국어/일본어를 입력 후 저장하면 커스텀 문구가 목록에 즉시 나타난다
- [ ] 한국어 또는 일본어가 비어있으면 저장할 수 없다
- [ ] 일본어 필드 입력 후 "번역" 버튼을 탭하면 한국어 필드가 자동으로 채워진다
- [ ] 번역이 실패해도 에러가 안내될 뿐 앱이 멈추지 않고, 한국어 필드를 직접 입력해 저장할 수 있다
- [ ] 커스텀 문구를 스와이프해 삭제할 수 있다 (Firebase 문구는 삭제 옵션이 보이지 않는다)
- [ ] 커스텀 문구를 탭하면 기존 문구와 동일하게 상세(가로모드) 화면과 복사 메뉴가 동작한다
- [ ] 앱을 재실행해도 커스텀 문구가 유지된다
