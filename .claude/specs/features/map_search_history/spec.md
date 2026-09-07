# map_search_history

## 무엇을 하는가
MapView의 검색 시트가 타이핑 모드로 전환될 때, 사용자가 과거에 입력했던 검색어 목록을 최신순으로 보여줘서 재검색을 빠르게 할 수 있도록 한다.

## 동작 명세
- 트리거: MapView 검색 시트가 `typing` 모드로 전환됨 (검색 필드 포커스)
- 결과:
  - 저장된 최근 검색어가 있으면 최신순으로 리스트 노출
  - 저장된 최근 검색어가 없으면 빈 상태(플레이스홀더) 노출
  - 검색어가 실행(확정)되면 해당 검색어를 최근 검색 기록에 추가
- 사이드이펙트:
  - 검색 실행 시 `TabiUserDefault`에 검색어(String) + 검색일(Date)을 JSON 인코딩하여 저장
  - 이미 동일한 검색어가 존재하면 기존 항목을 제거 후 최신 위치(맨 앞)로 재삽입
  - 저장 개수가 20개를 초과하면 가장 오래된 항목부터 제거
- 불변 조건:
  - 저장된 검색 기록은 항상 20개 이하
  - 저장된 검색 기록은 항상 최신 검색이 맨 앞에 위치 (내림차순)

## Cell UI 명세
- 참조 대상: `MapView.swift`의 검색 결과 Cell (`searchResultRow(_:)`, MapView.swift:277-317)와 레이아웃 톤을 맞추되 아래 차이를 둔다
  - 썸네일 이미지(KFImage 64x64) 없음
  - `VStack`으로 제목/날짜를 세로 배치하지 않고 한 줄(`HStack`)로 표시 (제목 좌측, 날짜 우측 또는 제목 뒤 인라인 — 구현 단계에서 확정)
- 타이틀(검색어)
  - 검색 결과 Cell의 타이틀(`.bodyMBold`, 16pt bold)보다 한 단계 크고 강하게 — `.bodyLBold`(18pt, bold) 사용, 색상 `.tabiTextPrimary`
- 날짜
  - 타이틀 대비 약하게 — `.captionM` 또는 `.captionS`, 색상 `.tabiTextTertiary` (검색 결과 Cell의 거리 라벨과 동일한 톤)
- 날짜 포맷
  - 기본: `mm.dd (hh:mm)` (예: `07.27 (14:30)`)
  - 검색일이 올해가 아닌 경우: `yyyy.mm.dd (hh:mm)` (예: `2025.12.03 (09:15)`)
  - 연도 비교 기준은 저장된 검색일의 `year`와 현재 시각(`Date()`)의 `year`
  - 기존 `Date+.swift`(Presentation/Sources/Extension)의 computed var 패턴을 따라 신규 포맷터 추가

## 무엇이 잘못될 수 있는가
- 저장된 Data 디코딩 실패 → 빈 배열로 폴백 (앱 크래시 없이 무시)
- 빈 문자열 검색어 → 저장하지 않음
- 동일 검색어 재검색 → 중복 저장 대신 기존 항목 제거 후 최신 위치로 이동

## 무엇에 의존하는가
### 의존성
- `Projects/Data/Sources/UserDefault/TabiUserDefault.swift` — 기존 `set<T>/get<T>` 제네릭 API
- `Projects/Data/Sources/UserDefault/TabiUserDefaultKey.swift` — 신규 key 추가 필요
- `Projects/Presentation/Sources/Map/MapFeature.swift` — `typing` 모드 상태 및 검색 실행 액션
- `Projects/Presentation/Sources/Map/MapView.swift` — 타이핑 모드 UI, 검색 결과 Cell(`searchResultRow`) 레이아웃 참조
- `Projects/Presentation/Sources/Extension/Date+.swift` — 날짜 포맷 computed var 추가 위치
- `Projects/DesignSystem/Sources/Label/TypographyStyle.swift`, `TabiLabel` — 타이틀/날짜 폰트 스타일
- `Projects/Resource/Sources/Color/TabiColor.swift` — 타이틀/날짜 색상 토큰

### 제약
- CoreData 미사용 (건 수가 적고 관계/쿼리 요구가 없어 UserDefaults로 충분하다고 판단됨)
- 저장 항목은 검색어(String), 검색일(Date) 두 필드만 포함
- 최대 20개까지만 저장, 초과 시 오래된 항목부터 삭제

## Acceptance Criteria
- [x] typing 모드 진입 시 저장된 최근 검색어가 최신순으로 노출된다
- [x] 검색어를 검색 실행하면 해당 검색어가 최근 검색어 목록 맨 앞에 저장된다
- [x] 이미 존재하는 검색어를 다시 검색하면 중복 없이 맨 앞으로 이동한다
- [x] 저장된 검색어가 20개를 초과하면 가장 오래된 항목이 삭제된다
- [x] 앱을 재실행해도 저장된 검색 기록이 유지된다
- [x] 최근 검색어 Cell은 썸네일 없이 한 줄로 표시된다
- [x] 최근 검색어 Cell의 타이틀은 검색 결과 Cell 타이틀보다 크고 강한 스타일로, 날짜는 약한 스타일로 표시된다
- [x] 검색일이 올해면 `mm.dd (hh:mm)`, 올해가 아니면 `yyyy.mm.dd (hh:mm)` 형식으로 날짜가 표시된다
