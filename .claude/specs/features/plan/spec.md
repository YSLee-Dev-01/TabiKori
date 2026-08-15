# 여행 일정 플랜

## 무엇을 하는가
사용자가 자신의 여행 일정(이름, 도시, 여행 기간)을 등록하고, 탭바 3번째 탭에서 진행중 / 다가오는 / 지난 일정으로 구분해 한눈에 확인할 수 있게 한다.

## 참고 디자인
- 목록 화면: `일정`(NavigationBar 타이틀) + trailing `+ 신규작성` 버튼(아이콘+텍스트) → 카드 리스트
  - 카드 상단 컬러 배너: 좌측에 이모지(도시 대표 이모지 또는 커스텀 이모지), 우측에 기간 배지("N일간")
  - 카드 본문: 일정 이름(굵게) + 우측 chevron(`>`, 탭 가능 표시)
  - 위치/기간 행: 핀 아이콘 + "도시 · 시작일 〜 종료일"
  - 일자 칩 행: "1일차" "2일차" … (여행 기간만큼 자동 생성)
  - 하단 행: "합계 0스팟"(고정 텍스트, 좌측) + "탭하여 상세를 표시"(안내 문구, 우측)
- 추가 화면: 드래그 핸들 + X 닫기 버튼이 있는 **시트(모달)**. 일정명 텍스트필드, 도시 2×3 그리드(이모지+라벨), 출발/귀국 날짜 표시 필드 + 인라인 캘린더(월 단위, 요일 헤더, 범위 선택), 하단 "일정을 작성하다" 버튼(비활성 상태 스타일 포함)

## 동작 명세
- 트리거:
  - 탭바 3번째 탭(일정) 진입 시 등록된 일정 목록을 조회하여 표시
  - 상단 NavigationBar(타이틀: 일정, trailing: + 버튼)의 + 버튼 탭 시 일정 추가 화면을 **`.sheet` 모달**로 표시
  - 추가 화면에서 일정 이름 / 도시(KoreanRegion, "기타" 선택 시 지역명 직접 입력) / 이모지(도시 기본 이모지 자동 지정, 텍스트필드로 직접 타이핑해 오버라이드 가능) / 여행 기간(시작일~종료일, 인라인 캘린더로 범위 선택) 입력 후 하단 확인 버튼 탭 시 저장
- 결과:
  - 목록은 위에서부터 진행중 → 다가오는 → 지난 순서의 섹션으로 배치
  - 진행중: 오늘 날짜가 시작일~종료일 범위 안에 포함되는 일정
  - 다가오는: 시작일이 오늘보다 이후인 일정
  - 지난: 종료일이 오늘보다 이전인 일정
  - 각 섹션에 데이터가 없으면 해당 섹션(헤더 포함)은 표시하지 않음
  - 셀 구성: 이모지 + 기간 배지(상단 배너), 일정 이름 + chevron, 도시 | 날짜 기간, 일자 칩(1일차~N일차, 기간으로 자동 계산), "합계 0스팟"(고정 텍스트) + "탭하여 상세를 표시" 안내 문구 — 스팟 배정은 Detail 기능(이번 범위 제외) 소관이라 카운트는 항상 0으로 고정 표시
  - 저장 성공 시 시트를 닫고(dismiss) 목록에 즉시 반영
  - 셀 탭 시 일정 Detail로 진입 예정 — Detail 화면 자체는 이번 범위에서 제외하되, `TravelPlan.id`를 `StackPath`에 실어 넘기는 데이터 흐름은 지금 설계에 포함(추후 Detail 기능 추가 시 바로 사용)
- 사이드이펙트:
  - SwiftData에 일정 데이터 영속화
- 불변 조건:
  - 저장된 일정은 앱을 재시작해도 유지되어야 한다
  - 종료일은 시작일보다 빠를 수 없다

## 무엇이 잘못될 수 있는가
- 필수값(일정 이름 / 도시 / 기간) 미입력 상태에서 저장 시도 → 확인 버튼 비활성화로 방지
- "기타" 선택 후 지역명 미입력 → 확인 버튼 비활성화로 방지
- SwiftData 저장/조회 실패 → `AppLogger.core`로 로그, 사용자에게는 저장 실패 알림
- 종료일 < 시작일 선택 시도 → 인라인 캘린더 범위 선택 제약으로 사전 방지

## 데이터 모델 (SwiftData)

### KoreanRegion 확장
- `case etc` 추가(연관값 없음, `CaseIterable` 자동 합성 유지) — 연관값을 쓰면 `CaseIterable`이 깨지는 기술적 제약 확인됨
- 실제 커스텀 지역명은 enum이 아닌 `TravelPlan` 엔티티의 `customRegionText`에 별도 보관
- 기존 7개 지역(seoul/busan/jeju/gyeongju/yeosu/gangneung/jeonju) + `etc` 그대로 사용(디자인 예시의 인천/대전 등은 참고용 시안일 뿐, 실제 목록은 기존 enum 기준)
- 지역별 기본 이모지 매핑은 Domain 엔티티가 아닌 Presentation 확장(예: `KoreanRegion+.swift`의 `jaTitle`/`koTitle`과 같은 패턴)에 추가

### TravelPlan (Domain Entity)
이미지는 별도 업로드 대신 **도시 기본 이모지** 또는 **사용자가 직접 입력한 이모지**로 결정한다(PhotosPicker/이미지 파일 저장 없음).

`Domain/Sources/Entity/TravelPlan.swift`
```swift
public struct TravelPlan: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var region: KoreanRegion
    public var customRegionText: String?
    public var customEmoji: String?
    public var startDate: Date
    public var endDate: Date
}
```
- `customEmoji`가 `nil`이면 `region`의 기본 이모지 매핑값을 사용, 값이 있으면(사용자가 텍스트필드로 직접 타이핑) 그 값을 우선 사용
- `region == .etc`인 경우 기본 이모지 매핑이 없으므로 `customEmoji` 입력이 사실상 필요

### TravelPlanModel (SwiftData, 목록/개요용)
`Data/Sources/SwiftData/TravelPlanModel.swift` — `BookmarkModel` 패턴 참고
```swift
@Model
final class TravelPlanModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var regionRaw: String
    var customRegionText: String?
    var customEmoji: String?
    var startDate: Date
    var endDate: Date
}
```
- `TravelPlanModelContainer` — `BookmarkModelContainer`처럼 `static let shared` 싱글턴 + 초기화 실패 시 in-memory 폴백
- `TravelPlanRepository` — DTO 없이 Model ↔ Entity 직접 변환, 메서드마다 `ModelContext(modelContainer)` 생성, `FetchDescriptor`로 조회(정렬 기준: 시작일 오름차순)

### TravelPlanDetailModel (SwiftData, 상세 전용 — 스켈레톤만 생성)
목록(`TravelPlanModel`)과 상세는 **서로 다른 SwiftData 모델**을 사용하고, `id`로 연동한다. 상세 화면 자체는 이번 범위 밖이므로 구체적인 상세 필드는 정의하지 않고, 연동 키만 가진 빈 모델만 지금 생성한다.
```swift
@Model
final class TravelPlanDetailModel {
    @Attribute(.unique) var planId: UUID
    // 상세 전용 필드는 이후 Plan Detail 기능 작업 시 정의
}
```
- `planId`는 `TravelPlanModel.id`를 가리키는 연동 키(1:1)
- `TravelPlanModelContainer`의 Schema에 `TravelPlanModel`과 함께 `TravelPlanDetailModel`도 등록해 향후 마이그레이션 없이 확장 가능하게 함
- 이번 범위에서는 이 모델을 실제로 읽거나 쓰는 Repository/UseCase는 만들지 않음 (스켈레톤만 존재)

### 일정 → 일정 Detail 데이터 흐름
- List/Detail이 서로 다른 모델을 쓰므로, 셀 탭 시 엔티티 전체가 아니라 **`TravelPlan.id`(UUID)만** `StackPath`에 실어 push
- 향후 Detail 기능 추가 시, `PlanDetailFeature`는 넘겨받은 `id`로 `TravelPlanRepository`(개요 조회)와 `TravelPlanDetailRepository`(상세 조회, 추후 신설)를 각각 `id`/`planId` 기준으로 조회해 화면을 구성
- 이번 스펙에서는 `StackPath`에 케이스를 추가하고 셀 탭 액션이 `id`를 담아 넘기는 지점까지만 구현, Detail 화면(`PlanDetailFeature`) 자체는 미구현

## 무엇에 의존하는가
### 의존성
- `Domain/Sources/Entity/KoreanRegion.swift` — "기타" 케이스(연관값 없음) 추가 필요
- `Domain/Sources/Entity/TravelPlan.swift` — 신규 엔티티 (위 데이터 모델 참고)
- 신규 SwiftData 모델/컨테이너/레포지토리(`Data/Sources/SwiftData/`, `Data/Sources/Repository/Plan/`) — `BookmarkModel`/`BookmarkModelContainer`/`BookmarkRepository` 패턴 참고
- `TravelPlanDetailModel` — 상세 전용 스켈레톤 모델(`planId` 연동 키만 보유), Repository/UseCase는 미생성
- `Presentation/Sources/Tabbar/` — `AppTab.plan` 케이스는 이미 존재, `TabBarFeature.State`의 임시 `PlanState` 플레이스홀더를 실제 `PlanFeature.State`로 교체
- `Presentation/Sources/Navigation/StackPath.swift` — (일정 추가 화면용 케이스는 불필요, `.sheet` 모달로 대체) 향후 Plan Detail push용 케이스만 추가 대상
- `PlanFeature.State`에 `@Presents var addPlanState: AddTravelPlanFeature.State?` 추가, `.ifLet(\.$addPlanState, action: \.addPlan)`으로 하위 Reducer 연결(Alert 처리와 동일한 `.ifLet` 패턴), `PlanView`에서 `.sheet(item:)`으로 표시
- DesignSystem 재사용: `TabiNavigationBar`(상단바), `TabiButton`(하단 확인 버튼, `DetailBottomCTAView` 컨셉 참고), `TabiSpotRow`(셀 레이아웃 참고), `TabiCard`
- 신규 제작 필요: 이모지 직접 입력용 텍스트필드, 기간(범위) 선택용 인라인 캘린더 컴포넌트 — 네이티브 `DatePicker` 휠이 아닌 디자인 예시와 같은 월 그리드 커스텀 컴포넌트, 프로젝트 내 최초 도입

### 제약
- 셀 탭 → Detail *화면*(`PlanDetailFeature`) 구현은 이번 스펙 범위에서 제외 (단, `id`를 넘기는 데이터 흐름 설계와 `TravelPlanDetailModel` 스켈레톤 생성은 포함)
- 일자별 스팟 배정(Detail 기능)은 이번 범위 제외 — 리스트 카드의 "합계 N스팟"은 항상 "0스팟" 고정 텍스트로만 표시하고 실제 카운트 로직은 만들지 않음
- 인라인 캘린더 range 선택 UI는 기존 DesignSystem에 없어 신규 컴포넌트 제작이 선행되어야 함
- 이미지 업로드(PhotosPicker) 기능은 이번 스펙에서 사용하지 않음(도시 이모지 + 커스텀 이모지 텍스트필드로 대체)

## Acceptance Criteria
- [x] 탭바 3번째 탭 진입 시 일정 목록이 진행중 → 다가오는 → 지난 순서로 섹션 표시된다
- [x] 각 카드에 이모지(도시 기본값 또는 커스텀), 기간 배지, 일정 이름, "도시 · 시작일〜종료일", 일자 칩(1일차~N일차), "합계 0스팟" 고정 텍스트가 표시된다
- [x] 데이터가 없는 섹션은 화면에서 숨겨진다
- [x] NavigationBar의 + 버튼으로 일정 추가 화면이 `.sheet` 모달로 표시된다
- [x] 추가 화면에서 이름 / 도시(기타 직접입력 포함) / 이모지(도시 기본값 자동 지정 + 텍스트필드로 직접 타이핑 가능) / 기간(인라인 캘린더 범위 선택)을 입력하고 확인 버튼으로 저장할 수 있다
- [x] 필수값 미입력 시 확인 버튼이 비활성화된다
- [x] 저장된 일정은 SwiftData에 영속화되어 앱 재시작 후에도 유지된다
- [x] 셀 탭 시 `TravelPlan.id`(UUID)가 `StackPath`를 통해 전달되는 구조가 마련되어 있다 (Detail 화면 자체는 미구현)
- [x] `TravelPlanDetailModel` 스켈레톤(`planId` 연동 키만 보유)이 생성되어 있다
