# Onboarding

## 무엇을 하는가
현재 온보딩은 `RootFeature`의 `#if DEBUG` 임시 버튼 하나로만 구성되어 실질적인 기능이 없다. 이를 홈·지도·일정·일정상세 화면을 더미 데이터로 미리 체험해보는 체험형 온보딩으로 교체하고, 체험이 끝나면 개인정보처리방침을 앱 내 웹뷰로 확인한 뒤에만 진행할 수 있는 약관동의 절차를 거치도록 한다. 신규 사용자가 실제 데이터 없이도 앱의 핵심 기능(홈/지도/일정/일정상세)을 미리 둘러보고, 개인정보처리방침을 실제로 읽었다는 확인을 받은 뒤 앱을 시작하게 하는 것이 목적이다.

## 동작 명세
- 트리거: 앱 최초 실행 시 `onboardingUsecase.isCompleted() == false`인 경우 (`RootFeature`의 `onboardingChecking` 액션)
- 결과:
  - 기존 `#if DEBUG` 텍스트 버튼 대신 `OnboardingView`가 TabView 기반 페이징으로 표시됨
  - 스텝 순서: 홈 체험 → 지도 체험 → 일정 체험 → 일정상세 체험 → 약관동의 (총 5단계, 순서대로만 진행 가능)
  - 각 체험 화면 하단 "다음" 버튼으로 다음 스텝 이동
  - 약관동의 화면: 개인정보처리방침 체크박스(기본 비활성) + "개인정보처리방침 보기" 버튼 + "시작하기" 버튼
  - "개인정보처리방침 보기" 탭 → 앱 내 `WKWebView`로 정책 페이지 표시(시트/풀스크린) → 닫으면(한 번이라도 열람 후 닫으면) 체크박스 활성화(터치 가능)로 전환
  - 체크박스 체크 시에만 "시작하기" 버튼 활성화
  - "시작하기" 탭 → 온보딩 완료 처리 → TabBar 화면 진입
- 사이드이펙트:
  - `onboardingUsecase.markAsCompleted()` 호출 → `TabiUserDefault`의 `.onboardingCompleted` 키에 `true` 저장
  - 체험 화면(홈/지도/일정/일정상세)에서는 네트워크·위치·DB 호출 없음 (전부 정적 더미 데이터)
  - 웹뷰는 실제 개인정보처리방침 URL(Resource 모듈로 이동된 공용 상수, 기존 `SettingEtcItem.privacyPolicyURLString`과 동일 값)을 로드
- 불변 조건:
  - 웹뷰를 한 번도 열지 않은 상태에서는 체크박스가 항상 비활성 상태를 유지한다
  - 체크박스가 체크되지 않은 상태에서는 "시작하기" 버튼으로 온보딩을 완료할 수 없다
  - `onboardingUsecase.isCompleted() == true`가 된 이후에는 앱 재실행 시 온보딩이 다시 표시되지 않는다
  - 체험 화면에서의 모든 인터랙션은 실제 `HomeFeature`/`MapFeature`/`PlanFeature`/`PlanDetailFeature`의 상태·의존성에 영향을 주지 않는다

## 무엇이 잘못될 수 있는가
- 개인정보처리방침 웹뷰 로드 실패(네트워크 오류, URL 접근 불가) → 웹뷰 내 에러 상태 표시, 체크박스는 여전히 "열람 후 닫힘" 기준으로만 활성화되므로 로드 실패 여부와 무관하게 웹뷰 화면을 닫으면 활성화됨(별도 에러 타입 없음, `AppLogger.log()`로 `Network` 태그 로깅)
- 온보딩 도중 앱 종료/백그라운드 전환 → 재실행 시 온보딩 처음(홈 체험)부터 다시 시작 (스텝 진행 상태는 저장하지 않음)
- `onboardingUsecase.markAsCompleted()` 저장 실패 → `AppLogger.log()`로 `Core` 태그 로깅, 사용자에게는 별도 에러 UI 없이 TabBar 진입은 그대로 진행(로컬 UserDefault 저장이므로 실패 가능성 낮음)

## 무엇에 의존하는가
### 의존성
- `Domain/Sources/UseCase/Onboarding/OnboardingUseCase.swift` — `isCompleted()`, `markAsCompleted()` (기존 그대로 재사용, 신규 UseCase 추가 없음)
- `Presentation/Sources/Root/RootFeature.swift`, `RootView.swift` — `#if DEBUG` 임시 버튼 및 `testBtnTapped` 액션 제거 후 `OnboardingView` 연결
- `Presentation/Sources/PlanDetail/PlanDetailMock.swift`, `Detail/DetailMock.swift` — 더미 데이터 작성 시 참고할 기존 Mock 패턴
- Resource 모듈 — 개인정보처리방침 URL 공용 상수(이동 예정) + 온보딩 화면용 Strings
- `WKWebView` (WebKit) — 프로젝트 내 최초 도입, 앱 내 정책 페이지 표시용

### 제약
- 홈/지도/일정/일정상세 체험 화면은 실제 `HomeFeature`/`MapFeature`/`PlanFeature`/`PlanDetailFeature` 및 그 하위 UseCase를 재사용하지 않고 신규 목업 뷰로 제작 (레이아웃만 참고)
- 체크박스·웹뷰 컴포넌트는 온보딩 전용 단일 사용처이므로 `DesignSystem`이 아닌 `Presentation/Onboarding/Sub/`에 위치 (기존 DesignSystem 컴포넌트는 재사용)
- 개인정보처리방침 URL의 Resource 내 정확한 파일 위치는 `folder-structure.md`에 명시된 기존 카테고리(Color/Image/Strings/Data)에 들어맞지 않으므로 구현 전 확인 필요
- 새 `.swift` 파일 추가 후 `tuist generate` 필요

## Acceptance Criteria
- [x] 온보딩 미완료 상태로 앱 실행 시 디버그 버튼 대신 홈→지도→일정→일정상세→약관동의 순서의 온보딩이 표시된다 (시뮬레이터 신규 설치 후 첫 화면 스크린샷으로 확인, 나머지 스텝은 코드 검토로 확인)
- [ ] 각 체험 화면에서 실제 네트워크/DB/위치 호출 없이 더미 데이터만 표시된다 (홈 스텝만 시각 확인, 지도/일정/일정상세는 사용자 확인 필요)
- [ ] 약관동의 화면에서 웹뷰를 열람하기 전에는 체크박스가 비활성 상태다 (사용자 확인 필요)
- [ ] 웹뷰를 한 번 열었다가 닫으면 체크박스가 활성화된다 (사용자 확인 필요)
- [ ] 체크박스 체크 전에는 "시작하기" 버튼이 비활성 상태이고, 체크 후 버튼 탭 시 온보딩 완료 처리(`markAsCompleted`) 후 TabBar로 진입한다 (사용자 확인 필요)
- [ ] 앱을 재실행하면 온보딩이 다시 표시되지 않는다 (사용자 확인 필요)
- [x] 개인정보처리방침 URL이 Resource 모듈에서 Setting/Onboarding 양쪽에 공용으로 참조된다 (grep으로 중복 정의 없음 확인)
- [x] `tuist generate` 및 빌드가 성공한다
