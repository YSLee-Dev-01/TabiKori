# widget

## 무엇을 하는가
홈 화면에 두 개의 위젯(플랜 위젯, 한국어 사전 위젯)을 추가해 앱을 열지 않고도 가장 가까운 여행 일정과 여행 문구를 바로 확인할 수 있게 한다.

## 동작 명세
- 트리거: 사용자가 홈 화면에 위젯 추가(WidgetKit 표준 흐름), 이후 시스템이 타임라인 갱신 주기에 따라 위젯을 리프레시
- 결과:
  - 플랜 위젯: 오늘 날짜가 startDate~endDate 사이인 진행 중 일정이 있으면 그 일정(제목/지역/디데이 등)을 표시, 없으면 startDate 기준 가장 가까운 미래 일정을 표시, 일정이 아예 없으면 빈 상태 문구 표시
  - 한국어 사전 위젯: 카테고리별 문구(한국어/일본어/발음)를 일정 주기로 로테이션하여 표시, 텍스트 검색/입력 UI는 제공하지 않음(WidgetKit 제약)
  - 두 위젯 모두 탭 시 앱의 관련 화면(Plan 상세 / 한국어 문구 목록)으로 딥링크 이동
- 사이드이펙트:
  - 앱이 TravelPlan/KoreanPhrase 데이터를 조회/변경할 때마다 위젯용 요약 스냅샷을 App Group 공유 저장소(UserDefaults suite: group.com.yslee.tabikori)에 기록
  - 스냅샷 갱신 시 WidgetKit 타임라인 리로드 트리거(`WidgetCenter.shared.reloadTimelines`)
- 불변 조건:
  - 위젯 익스텐션 프로세스는 네트워크(Firebase)나 SwiftData 스토어에 직접 접근하지 않고, App Group 스냅샷만 읽음(오프라인 우선)
  - 스냅샷이 없거나 파싱 실패해도 위젯이 크래시하지 않고 빈 상태를 표시

## 무엇이 잘못될 수 있는가
- App Group entitlement가 App/위젯 타겟에 실제로 연결되지 않은 경우 → 스냅샷 read/write 실패, 위젯은 항상 빈 상태 표시 (개발 중 최우선 검증 대상)
- 앱을 오래 실행하지 않아 스냅샷이 오래된 경우 → 위젯이 최신 상태를 반영하지 못함 (오프라인 우선 방식의 알려진 한계, 별도 에러 아님)
- 스냅샷 JSON 디코딩 실패 → AppLogger.core 로깅 후 빈 상태 표시
- 일정/문구 데이터가 전혀 없는 경우 → 각각 "예정된 일정 없음" / 빈 문구 자리표시 UI 표시

## 무엇에 의존하는가
### 의존성
- Domain: 위젯 스냅샷 전용 경량 모델 신설 (예: `PlanWidgetSnapshot`, `PhraseWidgetSnapshot`) — 기존 `TravelPlan`/`KoreanPhrase`와 별개로 위젯 표시에 필요한 필드만 포함
- Data: `TabiUserDefault`(App Group suite `group.com.yslee.tabikori`)를 통한 스냅샷 read/write 유틸 추가
- Presentation(또는 App 조립 지점): TravelPlan/KoreanPhrase 데이터 조회·변경 시점에 스냅샷 갱신 + `WidgetCenter.reloadTimelines` 호출 연결
- 신규 Widget Extension 타겟(Tuist) — `TimelineProvider`, `Entry`, `WidgetBundle`, 위젯 뷰(Plan/Dictionary 각각)
- Tuist: `Target.swift`/`DependencyInformation.swift`에 위젯 타겟 및 의존 방향 추가, App 타겟 + 위젯 타겟에 App Group entitlement 연결

### 제약
- WidgetKit은 텍스트 입력을 지원하지 않으므로 한국어 사전 위젯은 "검색"이 아닌 "로테이션 노출"로 범위 한정
- 위젯 익스텐션은 자체 메모리/시간 제약이 있어 Firebase SDK/SwiftData 스토어를 직접 열지 않고 App Group 스냅샷만 사용
- 현재 `group.com.yslee.tabikori` suite는 entitlements 파일이 프로젝트에 존재하지 않아 실제로 App Group capability가 활성화돼 있는지 미검증 상태 — plan 단계에서 우선 확인/설정 필요
- 지원 범위는 홈 화면 Small/Medium으로 한정 (잠금화면 위젯 제외)

## Acceptance Criteria
- [ ] 홈 화면에 플랜 위젯을 추가하면 진행 중인 일정이 있을 때 해당 일정이 표시된다
- [ ] 진행 중인 일정이 없으면 가장 가까운 미래 일정이 표시된다
- [ ] 일정이 전혀 없으면 빈 상태 문구가 표시된다
- [ ] 플랜 위젯을 탭하면 앱의 해당 일정 상세 화면으로 이동한다
- [ ] 홈 화면에 한국어 사전 위젯을 추가하면 카테고리별 문구가 주기적으로 로테이션되어 표시된다
- [ ] 한국어 사전 위젯을 탭하면 앱의 한국어 문구 목록 화면으로 이동한다
- [ ] 앱을 실행하지 않은 상태에서도(기기 재부팅 등) 마지막으로 저장된 스냅샷 기준으로 위젯이 정상 표시된다
- [ ] App Group 스냅샷이 없거나 손상된 경우에도 위젯이 크래시하지 않고 빈 상태를 표시한다
