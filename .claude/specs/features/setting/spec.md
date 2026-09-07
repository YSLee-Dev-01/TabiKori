# setting

## 무엇을 하는가
사용자가 앱의 부가 정보(GPS 권한, 로컬 데이터, 데이터 출처 등)를 한 화면에서 확인하고 제어할 수 있도록, HomeView 우측 상단 아이콘을 통해 진입하는 전체 설정 화면을 제공한다.

## 동작 명세
- 트리거
  - HomeView 상단 `TabiNavigationBar`의 trailing 영역에 설정 아이콘(`TabiCircleIconButton`, 재사용) 추가
  - 아이콘 탭 → `HomeFeature.Action.settingButtonTapped` 방출 → `TabBarFeature`가 수신하여 `StackPath`에 `.setting(SettingFeature.State())` push (기존 `festivalMoreButtonTapped` → `.festival` push와 동일 패턴)
- 결과
  - Setting 화면에 아래 섹션을 리스트/카드 형태로 노출
    1. GPS 권한 설정 — 현재 권한 상태 표시 + 탭 시 `UIApplication.openSettingsURLString`으로 iOS 설정 앱 이동 (HomeFeature의 `openSettingsButtonTapped`와 동일 패턴 재사용)
    2. 데이터 초기화 — 확인 Alert 노출 후 승인 시 로컬 데이터 삭제 (온보딩 완료 플래그 제외 전체)
    3. 기타 — 하위 항목: 데이터 출처, 개인정보처리방침, 오픈소스 라이선스, 문의하기, 기타
- 사이드이펙트
  - 데이터 초기화 확정 시 북마크(SwiftData), 여행 일정(SwiftData), 최근 검색어(UserDefault `recentSearchHistory`) 삭제. `onboardingCompleted`는 유지
  - GPS 권한 설정은 앱 외부(iOS 설정 앱)로 이동, 네트워크 요청 없음
  - 기타 하위 항목은 순수 정보 노출 또는 외부 이동(문의하기 메일/링크 등, 방식은 확인 필요), 데이터 변경 없음
- 불변 조건
  - 데이터 초기화는 사용자 확인(Alert) 없이는 즉시 실행되지 않는다
  - Setting 화면 진입/이탈이 다른 탭(Home 등)의 상태에 영향을 주지 않는다

## 무엇이 잘못될 수 있는가
- GPS 설정 앱 이동용 URL 생성 실패 → 무시 (기존 `HomeFeature.openSettingsButtonTapped` 방식과 동일하게 guard let 실패 시 조용히 종료)
- 데이터 초기화 중 SwiftData delete 실패 → `TabiError` 로 매핑, `AppLogger.core` 로깅 후 사용자에게 실패 알림 노출
- 데이터 초기화 중 일부(북마크/여행일정/최근검색어)만 성공하고 일부 실패 → 부분 실패 처리 방식 확인 필요

## 무엇에 의존하는가
### 의존성
- DesignSystem: `TabiNavigationBar`(trailing), `TabiCircleIconButton`, `TabiCard`, `TabiLabel`, Alert 관련 기존 컴포넌트(있는지 확인 필요)
- Presentation/Navigation: `StackPath`에 `.setting(SettingFeature)` 케이스 추가, `TabBarFeature`에서 `home(.settingButtonTapped)` 처리
- Domain/Data: 데이터 초기화를 위해 `BookmarkModelContainer`, `TravelPlanModelContainer`(SwiftData), `TabiUserDefault`(`recentSearchHistory`) 접근 필요 — 초기화 UseCase 신규 정의 여부 확인 필요
- Resource: `Strings.Setting` 네임스페이스 신규 추가

### 제약
- 데이터 초기화 대상: 북마크(SwiftData), 여행 일정(SwiftData), 최근 검색어(UserDefault) — `onboardingCompleted`는 제외
- 기타 섹션 하위 항목: 데이터 출처, 개인정보처리방침, 오픈소스 라이선스, 문의하기, 기타 (5개)
- (확인 필요) 하위 항목 각각의 상세 동작 — 데이터 출처/개인정보처리방침/오픈소스 라이선스는 텍스트 노출인지 외부 링크인지, 문의하기는 메일 작성(mailto)인지 외부 링크인지, "기타" 항목이 구체적으로 무엇을 의미하는지
- Setting 화면은 신규 Feature(`Presentation/Setting/`)로 생성, 기존 폴더 구조 규칙(`folder-structure.md`) 준수

## Acceptance Criteria
- [ ] HomeView 우측 상단에 설정 아이콘이 노출되고, 탭 시 Setting 화면으로 진입한다
- [ ] Setting 화면에 GPS 권한 설정, 데이터 초기화, 기타(데이터 출처/개인정보처리방침/오픈소스 라이선스/문의하기/기타) 섹션이 노출된다
- [ ] GPS 권한 설정 탭 시 iOS 설정 앱으로 이동한다
- [ ] 데이터 초기화는 확인 Alert 이후에만 실행되며, 북마크·여행 일정·최근 검색어가 삭제되고 온보딩 완료 상태는 유지된다
- [ ] 데이터 초기화 완료 후 관련 화면(Home/Bookmark/Plan 등)에 즉시 반영된다
- [ ] Setting 화면의 모든 UI는 기존 DesignSystem 컴포넌트를 재사용하며 신규 컴포넌트를 임의로 만들지 않는다
