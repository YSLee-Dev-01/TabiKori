# plan_detail

## 무엇을 하는가
PlanView에서 일정 Cell을 탭하면 진입하는 일정 상세 화면. 상단에 일정 제목/지역/기간을 보여주는 NavigationBar와, 일정을 일자 단위로 나눈 선택 버튼(pill)을 제공해 사용자가 원하는 날짜를 고를 수 있게 한다.
※ 선택된 날짜의 실제 일정(스팟 목록/지도)을 보여주는 View는 작업 단위가 커 이번 범위에서 제외하고 추후 별도 기능으로 진행한다.

## 동작 명세
- 트리거: PlanView에서 일정 Cell 탭 → `TabBarFeature`가 `path.append(.planDetail(PlanDetailFeature.State(id:)))`로 push
- 결과:
  - NavigationBar에 해당 일정의 `title`, `"\(displayRegionTitle) · \(durationBadge(dayCount))"` 서브타이틀 표시
  - `dayCount`만큼 일자 탭 pill 버튼이 가로 스크롤로 표시 ("N日目" + "M月d日" 2줄)
  - 일자 탭 버튼 탭 시 `selectedDayIndex` 갱신 및 선택 스타일(강조 색상) 전환
  - 뒤로가기 버튼(네이티브 toolbar, `chevron.left`) 탭 시 PlanView로 복귀
- 사이드이펙트:
  - `onAppear` 시 `travelPlanUseCase.fetch()` 호출로 전체 일정 목록을 조회해 `id`와 일치하는 `TravelPlan`을 찾아 상태에 저장 (네트워크/DB 조회, 신규 UseCase 추가 없이 기존 `fetch()` 재사용)
  - `onAppear` 시 `travelPlanDetailUseCase.fetch(planId:)`도 함께 호출해 `TravelPlanDetail`을 상태에 저장 (이번 화면에서는 표시하지 않음 — 추후 "일정을 보여주는 View" 기능이 그대로 사용할 수 있도록 미리 연결만 해둠)
- 불변 조건: `plan`이 로딩되기 전(`nil`)에는 NavigationBar/일자 탭 버튼을 렌더링하지 않고 로딩 표시만 노출

## 무엇이 잘못될 수 있는가
- 존재하지 않는 id로 진입(목록에 없는 id) → `plan = nil` 유지, 크래시 없이 로딩 상태만 해제, 별도 에러 UI 없음
- `travelPlanUseCase.fetch()` 조회 실패 → `AppLogger.view.log(.error, ...)`로 로깅 후 `plan = nil` 처리 (재시도 UI 없음)
- `travelPlanDetailUseCase.fetch(planId:)` 결과가 없음(아직 생성된 적 없는 일정) → `travelPlanDetail = nil` 유지, 화면 동작에는 영향 없음 (UI에서 사용하지 않으므로)
- `travelPlanDetailUseCase.fetch(planId:)` 조회 실패 → `AppLogger.view.log(.error, ...)`로 로깅만 하고 화면 진행에는 영향 없음 (NavigationBar/일자탭은 `plan` 로딩 여부만으로 결정)

## 무엇에 의존하는가
### 의존성
- `TravelPlanUseCaseProtocol.fetch()` (Domain, 기존 그대로 재사용 — 신규 메서드 추가 없음)
- `TravelPlanDetailUseCaseProtocol.fetch(planId:)` (Domain, 신규) — `TravelPlan`과 동일한 계층 패턴(Entity/RepositoryProtocol/UseCase/testValue·liveValue)으로 신규 구성. 기존 `TravelPlanDetailModel`(SwiftData, `planId: UUID`만 보유)을 Domain/Data에 연결
- `TravelPlan+.swift` (Presentation/Plan/Model) — `dayCount`, `displayRegionTitle`, `dayChipTitle` 등 기존 계산 프로퍼티, `dayDates: [Date]` 신규 추가
- `Date+.swift` (Presentation/Extension) — 요일 없는 `M月d日` 포맷 프로퍼티 신규 추가
- `TabiNavigationBar` (DesignSystem) — title/subtitle 그대로 재사용 (leading/back 미지원, 확장하지 않음)
- `TabBarFeature`/`StackPath` 네비게이션 연결 (기존 그대로, 변경 없음)

### 제약
- `TravelPlanUseCaseProtocol`/Repository는 변경하지 않는다 (fetchByID 등 신규 메서드 추가 없이 `fetch()` + client-side 필터로 처리)
- `TravelPlanDetailRepositoryProtocol`은 `TravelPlanUseCaseProtocol`과 동일하게 `fetch(planId:)` / `add(_:)`로만 구성 (upsert/`fetchOrCreate` 없음). 레코드 생성 책임은 호출부(추후 기능)에 남겨둔다
- `TravelPlanDetail` 조회/저장 로직은 이번 범위에서 신규 생성(`add`)하지 않는다 — `AddTravelPlanFeature`(일정 생성 플로우)는 무관한 코드이므로 수정하지 않음. `PlanDetailFeature`는 `fetch(planId:)`만 호출
- `TravelPlanDetail`은 이번 화면 UI에는 전혀 표시하지 않는다 (State에 저장만, 렌더링 없음)
- 뒤로가기는 `TabiNavigationBar` 확장 대신 `DetailView`와 동일한 네이티브 `.toolbar` + `navigationBarBackButtonHidden(true)` 패턴을 따른다
- 일자 탭 버튼 아래 날짜 헤더 텍스트, 지도, 빈 스팟 안내 카드 등 "일정을 보여주는 View"는 이번 범위에서 완전히 제외 (Spacer로 여백만 확보)
- 새 `.swift` 파일(`PlanDetailDayButton.swift` 등) 추가 시 `tuist generate` 필수

## Acceptance Criteria
> 코드 구현·빌드·정적 리뷰까지 완료. 시뮬레이터 인터랙티브 탭 테스트(접근성 권한/idb 미설치로 자동화 불가)는 미수행 — 아래 항목 중 실제 탭/네비게이션 동작 확인이 필요한 항목은 사용자 수동 확인 필요
- [ ] PlanView에서 일정 Cell 탭 → PlanDetail 진입 시 해당 일정의 title/region/기간이 NavigationBar에 정상 표시된다 (구현 완료, 수동 확인 필요)
- [ ] 뒤로가기 버튼 탭 시 PlanView로 정상 복귀한다 (구현 완료, 수동 확인 필요)
- [ ] `dayCount`만큼 일자 탭 버튼이 가로 스크롤로 표시되고 각 버튼에 "N日目"+날짜가 2줄로 표시된다 (구현 완료, 수동 확인 필요)
- [ ] 일자 탭 버튼 탭 시 `selectedDayIndex`가 갱신되고 선택 스타일(강조 색상)이 전환된다 (구현 완료, 수동 확인 필요)
- [ ] 존재하지 않는 id로 진입해도 크래시 없이 로딩 상태가 해제된다 (에러는 AppLogger로 로깅) (구현 완료, 수동 확인 필요)
- [ ] `travelPlanDetailUseCase.fetch(planId:)`가 `onAppear`에서 호출되고, 결과 유무/에러와 무관하게 화면이 정상 표시된다 (UI 미노출) (구현 완료, 수동 확인 필요)
- [x] `tuist generate` 후 빌드 성공 — `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17'` BUILD SUCCEEDED 확인
