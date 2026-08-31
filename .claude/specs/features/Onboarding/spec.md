# Onboarding

## 무엇을 하는가
기존 체험형 온보딩은 홈·지도·일정·일정상세 화면을 더미 데이터 목업으로 보여주되, TabView로 스와이프하거나 "다음" 버튼을 눌러 수동적으로 넘겨보는 방식이었다. 이를 사용자가 각 화면의 실제 버튼(카테고리 칩, 검색 결과, 일정 카드, Day 칩 등)을 스포트라이트로 안내받아 **직접 탭해야만** 다음 단계로 진행되는 코치마크형 온보딩으로 교체한다. 목적은 신규 사용자가 화면을 수동적으로 구경만 하는 것이 아니라, 앱의 핵심 인터랙션(카테고리 선택, 장소 탐색, 일정 확인)을 손으로 직접 경험하게 하여 온보딩 직후 실사용으로의 전환을 높이는 것이다.

## 동작 명세
- 트리거: 앱 최초 실행 시 `onboardingUsecase.isCompleted() == false`인 경우 (`RootFeature`의 `onboardingChecking` 액션) — 기존과 동일
- 결과:
  - `OnboardingView`는 더 이상 `TabView` 페이징(스와이프)을 사용하지 않는다. 한 번에 한 스텝의 목업 화면만 표시하고, 스텝 전환 시 페이드/트랜지션 애니메이션으로 자연스럽게 바뀐다
  - 각 스텝 화면 위에 반투명 딤(dim) 오버레이가 씌워지고, 사용자가 눌러야 할 대상 요소(버튼/카드/칩)만 스포트라이트 홀로 뚫려 보이며, 그 근처에 "○○를 눌러보세요" 형태의 유도 툴팁이 표시된다
  - 오버레이가 표시된 상태에서는 하이라이트된 대상 외의 영역은 탭이 막힌다(오탐 진행 방지)
  - 하단 "다음" 버튼과 스와이프 넘김은 제거한다. 진행 상황 표시는 기존 `TabiPageIndicator`(5개 도트)만 유지한다
  - 스텝별 하이라이트 대상 및 진행 트리거:
    | 스텝 | 하이라이트 대상 | 탭 시 동작 |
    |------|----------------|-----------|
    | 홈 | 카테고리 칩(첫 번째) | 카테고리 선택 상태 반영 + 다음 스텝(지도)으로 전환 |
    | 지도 | 검색 결과 카드(첫 번째) | 다음 스텝(일정)으로 전환 |
    | 일정 | 일정 카드(첫 번째) | 다음 스텝(일정상세)으로 전환 |
    | 일정상세 | Day 칩(2번째) | 선택 Day 전환 + 다음 스텝(약관동의)으로 전환 |
    | 약관동의 | ① "개인정보처리방침 보기" 버튼 → ② 체크박스 → ③ "시작하기" 버튼 (순서대로 하이라이트 이동) | 기존 실동작(웹뷰 열람 → 체크박스 활성화 → 시작하기)을 그대로 코치마크로 안내, 마지막 탭 시 온보딩 완료 |
  - 각 스텝 진입 시 하이라이트 대상의 화면 좌표를 측정한 뒤에만 오버레이/툴팁을 표시한다(좌표 측정 전에는 오버레이 숨김)
  - 스텝 간 뒤로가기는 제공하지 않는다(기존과 동일하게 앞으로만 진행)
- 사이드이펙트:
  - `onboardingUsecase.markAsCompleted()` 호출 → `TabiUserDefault`의 `.onboardingCompleted` 키에 `true` 저장 (기존과 동일, 호출 시점도 "시작하기" 탭으로 동일)
  - 체험 화면(홈/지도/일정/일정상세)에서는 네트워크·위치·DB 호출 없음(전부 정적 더미 데이터) — 기존과 동일
  - 웹뷰는 실제 개인정보처리방침 URL을 로드 — 기존과 동일
- 불변 조건:
  - 각 스텝은 하이라이트된 대상을 실제로 탭해야만 다음 스텝으로 진행되며, 오버레이 바깥을 탭하거나 스와이프해서는 진행할 수 없다
  - 웹뷰를 한 번도 열지 않은 상태에서는 체크박스가 항상 비활성 상태를 유지한다
  - 체크박스가 체크되지 않은 상태에서는 "시작하기" 버튼으로 온보딩을 완료할 수 없다
  - `onboardingUsecase.isCompleted() == true`가 된 이후에는 앱 재실행 시 온보딩이 다시 표시되지 않는다
  - 체험 화면에서의 모든 인터랙션은 실제 `HomeFeature`/`MapFeature`/`PlanFeature`/`PlanDetailFeature`의 상태·의존성에 영향을 주지 않는다

## 무엇이 잘못될 수 있는가
- 개인정보처리방침 웹뷰 로드 실패(네트워크 오류, URL 접근 불가) → 웹뷰 내 에러 상태 표시, 체크박스는 여전히 "열람 후 닫힘" 기준으로만 활성화되므로 로드 실패 여부와 무관하게 웹뷰 화면을 닫으면 활성화됨(`AppLogger.log()`로 `Network` 태그 로깅) — 기존과 동일
- 하이라이트 대상 View의 화면 좌표를 레이아웃 계산 전에 읽으려는 경우 → 오버레이가 잘못된 위치에 표시되거나 깜빡일 위험. SwiftUI Anchor/PreferenceKey로 좌표가 확정된 뒤에만 오버레이를 표시해 방지
- 온보딩 도중 앱 종료/백그라운드 전환 → 재실행 시 온보딩 처음(홈 스텝)부터 다시 시작 — 기존과 동일(진행 상태 저장 안 함)
- `onboardingUsecase.markAsCompleted()` 저장 실패 → `AppLogger.log()`로 `Core` 태그 로깅, TabBar 진입은 그대로 진행 — 기존과 동일

## 무엇에 의존하는가
### 의존성
- `Domain/Sources/UseCase/Onboarding/OnboardingUseCase.swift` — `isCompleted()`, `markAsCompleted()` (기존 그대로 재사용)
- 신규 컴포넌트: 스포트라이트 오버레이 + 유도 툴팁 뷰 — 온보딩 전용 단일 사용처이므로 `DesignSystem`이 아닌 `Presentation/Onboarding/Sub/`에 위치 (기존 체크박스/웹뷰 컴포넌트와 동일 원칙)
- 하이라이트 대상 View의 화면 좌표 측정을 위한 SwiftUI `Anchor`/`PreferenceKey` 활용 (신규 도입, 프로젝트 내 최초 사용 여부 구현 전 확인 필요)
- 기존 `OnboardingFeature`/`OnboardingStep`/`OnboardingMock`/각 Step View(`OnboardingHomeStepView` 등) 전면 수정 — TabView·페이지 인덱스 기반 흐름을 스텝 완료 기반 흐름으로 변경
- `Presentation/Sources/PlanDetail/PlanDetailMock.swift`, `Detail/DetailMock.swift` — 기존 Mock 패턴 참고(변경 없음)
- Resource 모듈 — 개인정보처리방침 URL 공용 상수(기존) + 스텝별 유도 툴팁 문구 신규 Strings 추가 필요

### 제약
- 홈/지도/일정/일정상세 체험 화면은 실제 `HomeFeature`/`MapFeature`/`PlanFeature`/`PlanDetailFeature`와 실제 `HomeView`/`MapView`/`PlanView`/`PlanDetailView`를 그대로 재사용한다(후속 변경, `Onboarding/plan.md`의 "실제 Feature 재사용 전환" 섹션 참고). 각 Feature의 UseCase 의존성을 Domain의 Test 더블 + `OnboardingMock` 데이터로 `withDependencies` 오버라이드해 실제 네트워크·DB·위치 호출 없이 렌더링한다. 단, 지도 스텝의 `TabiMapView`(NMapsMap SDK) 배경만 정적 목업(`OnboardingMapBackgroundMockView`)으로 대체한다(`MapView`에 지도 배경 주입 지점 `mapBackgroundOverride` 추가, 기본값은 기존과 동일한 실제 지도)
- 코치마크 진행 신호는 각 실제 Feature의 State/Action을 변형하지 않고, 얇은 래퍼 Reducer(`OnboardingHomeProgressReducer` 등, 각 Host View 파일 내부)가 대상 액션(`categoryTapped`/`searchResultTapped`/`planTapped`/`dayButtonTapped`)만 관찰해 `OnboardingFeature`로 전달한다
- 지도/일정 스텝의 검색 결과 카드·일정 카드는 실제 프로덕션 뷰(`MapView`/`PlanView`) 내부의 첫 번째 요소에 `.onboardingHighlight(_:)`를 부착해 코치마크 진행 트리거로 연결
- 새 `.swift` 파일 추가/삭제 후 `tuist generate` 필요

## Acceptance Criteria
- [ ] 온보딩 미완료 상태로 앱 실행 시 홈 스텝이 표시되고, 카테고리 칩 외 영역을 탭해도 스텝이 넘어가지 않는다
- [ ] 홈 스텝에서 하이라이트된 카테고리 칩을 탭하면 지도 스텝으로 전환된다
- [ ] 지도 스텝에서 하이라이트된 검색 결과 카드를 탭하면 일정 스텝으로 전환된다
- [ ] 일정 스텝에서 하이라이트된 일정 카드를 탭하면 일정상세 스텝으로 전환된다
- [ ] 일정상세 스텝에서 하이라이트된 Day 칩을 탭하면 약관동의 스텝으로 전환된다
- [ ] 약관동의 스텝에서 "정책 보기" → 웹뷰 열람·닫기 → 체크박스 → "시작하기" 순서로 하이라이트가 이동하며, 각 단계는 실제 탭 없이는 넘어가지 않는다
- [ ] "시작하기" 탭 시 온보딩 완료 처리(`markAsCompleted`) 후 TabBar로 진입한다
- [ ] 앱을 재실행하면 온보딩이 다시 표시되지 않는다
- [x] 각 체험 화면에서 실제 네트워크/DB/위치 호출 없이 더미 데이터만 표시된다 (OnboardingMock 정적 데이터만 사용, 코드 검토로 확인)
- [x] `tuist generate` 및 빌드가 성공한다
