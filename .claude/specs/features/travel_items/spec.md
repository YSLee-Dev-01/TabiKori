# travel_items (준비물)

## 무엇을 하는가
일본에서 한국으로 여행 올 때 필요한 준비물을 사용자가 잊지 않고 챙길 수 있도록, Tabbar의 신규 "툴박스" 탭에서 준비물 마스터 체크리스트를 보여주고, 이를 사용자가 진행 중인 여행 플랜에 저장해 플랜 상세 화면에서 실제로 체크하며 사용할 수 있게 한다. 툴박스의 준비물 화면은 "틀"(마스터 리스트 열람 + 저장 트리거)이고, 실제 사용자가 체크하며 쓰는 것은 PlanDetail에 저장된 사본이다.

## 동작 명세
- 트리거:
  - Tabbar에서 "툴박스" 탭 선택 → 준비물 화면 진입 (툴박스의 첫 번째이자 현재 유일한 기능)
  - 준비물 화면에서 "플랜에 저장" 버튼 탭 → 플랜 선택 화면 진입 → 플랜 선택 시 저장 확정
  - PlanDetail 화면의 일자 상단 헤더 영역에서 "준비물" 버튼 탭 → 해당 플랜에 저장된 준비물 체크리스트 화면 진입
  - 저장된 체크리스트 화면에서 각 항목 탭 → 완료 여부 토글
- 결과:
  - 준비물 화면: Firebase Realtime Database에서 받아온 마스터 체크리스트 목록 표시 (로딩/에러 상태 포함)
  - 플랜 선택 화면: 사용자가 보유한 TravelPlan 목록을 보여주고 하나를 선택
  - 저장 확정 시: 마스터 리스트 전체가 선택된 플랜에 복사되어 저장됨 (플랜 전체 기준 1개 리스트, 일자별 아님)
  - PlanDetail 일자 헤더의 "준비물" 버튼: 플랜당 1회만 노출 (fullOverviewList에서도 중복 노출되지 않음)
  - 저장된 체크리스트 화면: 항목별 체크박스로 완료 상태 표시/토글 가능, 상태는 즉시 영속화
  - 아직 준비물을 저장하지 않은 플랜에서 "준비물" 버튼 탭 시 빈 상태(empty state) UI 표시
- 사이드이펙트:
  - Firebase Realtime Database 네트워크 조회 (`TabiKori/travelItems` 등 신규 경로)
  - SwiftData에 플랜별 준비물 항목 및 체크 상태 영속화 (신규 모델 추가)
- 불변 조건:
  - 한 플랜에는 준비물 리스트가 최대 1개만 존재 (일자별 리스트 아님)
  - 준비물 항목 체크 상태는 앱 재시작 후에도 유지됨
  - Firebase 원본 마스터 리스트는 플랜에 저장된 사본과 독립적 (마스터 리스트가 이후 갱신되어도 이미 저장된 플랜의 사본에는 소급 반영되지 않음)

## 무엇이 잘못될 수 있는가
- Firebase Realtime Database 조회 실패(네트워크 오류 등) → 준비물 화면 에러 상태 표시, `AppLogger.network`로 로깅
- 저장 시점에 사용자가 보유한 TravelPlan이 하나도 없음 → 플랜 선택 화면에서 빈 상태 처리 필요
- 이미 준비물이 저장된 플랜에 다시 저장을 시도하는 경우 → 덮어쓰기 여부 확인 필요 (미결, Step 2에서 결정)
- SwiftData 저장/조회 실패 → `AppLogger.core` 또는 `AppLogger.view`로 로깅

## 무엇에 의존하는가
### 의존성
- Tabbar: `AppTab`, `TabBarFeature`, `TabBarView` (신규 탭 등록)
- Firebase Realtime Database: 기존 `ExchangeRateRepository` 패턴 재사용 (Firestore 아님)
- Domain: `TravelPlan`, `TravelPlanDetail` 엔티티 (준비물 저장 상태 확장 대상)
- Data: SwiftData `TravelPlanDetailModel` 계열, `TravelPlanDetailRepository` (ModelContext 기반 영속화)
- Presentation: `PlanDetailFeature`/`PlanDetailView`/`PlanDetailDayHeader` (버튼 삽입 위치), `PlanDetailAddSpotFeature`류의 `@Presents` + sheet 저장 플로우 패턴
- DesignSystem: `TabiCircleIconButton` 등 기존 컴포넌트 재사용

### 제약
- Firestore는 현재 레포에 연동되어 있지 않으므로 사용하지 않음 (신규 의존성 추가 지양) — Realtime Database로 구현
- Domain은 Data/Firebase를 직접 참조하지 않음, RepositoryProtocol로 추상화
- 새 `.swift` 파일 추가 후 `tuist generate` 필수

## Acceptance Criteria
- [x] 툴박스 탭이 Tabbar에 노출되고 진입 시 준비물 화면(마스터 리스트)으로 연결된다 (코드 구현 완료·빌드 성공, 시뮬레이터 수동 확인 필요)
- [ ] 준비물 화면에서 Firebase Realtime Database의 마스터 체크리스트가 로드된다 (로딩/에러 상태 포함) — Firebase 콘솔에 `TabiKori/travelItems` 데이터 미입력으로 실기기 검증 불가
- [x] "플랜에 저장" 버튼으로 플랜 선택 화면에서 플랜을 고르면, 해당 플랜에 준비물 리스트 전체가 저장되고 SwiftData에 영속화된다 (코드 구현 완료·빌드 성공, 시뮬레이터 수동 확인 필요)
- [x] PlanDetail 일자 헤더 영역에 "준비물" 버튼이 플랜당 1회만 노출된다 (코드 구현 완료·빌드 성공, 시뮬레이터 수동 확인 필요)
- [x] "준비물" 버튼 탭 시 저장된 체크리스트 화면으로 이동하며, 각 항목을 체크/해제할 수 있고 상태가 영속화된다 (코드 구현 완료·빌드 성공, 시뮬레이터 수동 확인 필요)
- [x] 준비물이 아직 저장되지 않은 플랜에서는 빈 상태 UI가 표시된다 (코드 구현 완료·빌드 성공, 시뮬레이터 수동 확인 필요)
