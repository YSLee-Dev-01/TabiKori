# Tasks: Photo Viewer (사진 확대 뷰)

## 참조
- spec: `.claude/specs/features/photo-viewer/spec.md`
- plan: `.claude/specs/features/photo-viewer/plan.md`

## Task 목록

### Phase 1. Presentation - PhotoViewerFeature (Reducer)

#### [x] Task 1 — `PhotoViewerFeature.swift` (신규)
**파일**: `Projects/Presentation/Sources/PhotoViewer/PhotoViewerFeature.swift`
- `@Reducer public struct PhotoViewerFeature` 신규 작성 (특정 Feature에 종속되지 않는 독립 화면)
- `@ObservableState public struct State: Equatable`
  - 공개 프로퍼티: `images: [TouristSpotImage]`, `title: String`, `currentIndex: Int`
  - `public init(images: [TouristSpotImage], startIndex: Int, title: String)`에서 `startIndex`를 `images.indices` 범위로 clamp하여 `currentIndex`에 대입 (빈 배열이면 0)
- `public enum Action: Equatable, BindableAction`
  - `case binding(BindingAction<State>)` (선언 순서 1번: 바인딩)
  - 생명주기/사용자 인터랙션 액션은 최소화 (Back 처리는 뷰의 `@Environment(\.dismiss)`로 수행하므로 별도 pop 액션 불필요)
- `public var body: some Reducer<State, Action>`
  - `BindingReducer()`를 첫 번째로 배치
  - `Reduce { state, action in ... }`는 `.binding`만 처리하고 `.none` 반환하는 골격 (부가 로직 없음)
- 사이드이펙트 없음, `@Dependency` UseCase 주입 없음 (spec 제약: 호출 화면이 전달한 데이터만 사용)

---

### Phase 2. Presentation - Navigation 연결

#### [x] Task 2 — `StackPath.swift`
**파일**: `Projects/Presentation/Sources/Navigation/StackPath.swift`
- `@Reducer public enum StackPath`에 `case photoViewer(PhotoViewerFeature)` 추가 (기존 `case detail(DetailFeature)` 다음)
- `extension StackPath.State: Equatable {}` / `extension StackPath.Action: Equatable {}`는 기존 그대로 유지 (자동 적용)

---

#### [x] Task 3 — `DetailFeature.swift`
**파일**: `Projects/Presentation/Sources/Detail/DetailFeature.swift`
- `Action` enum에 `case photoCellTapped(index: Int)` 추가 (사용자 인터랙션 카테고리, 기존 `case tabSelected(DetailTab)` 등과 같은 위치)
- `body`의 `Reduce` switch에 `case .photoCellTapped: return .none` 케이스 추가 — `DetailFeature` 자신의 `State`는 변경하지 않고 부모(`TabBarFeature`)가 가로채도록 액션만 방출

---

#### [x] Task 4 — `TabBarFeature.swift`
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarFeature.swift`
- 기존 `case .home(.nearbySpotTapped(let spot)): state.path.append(.detail(...))` 패턴과 동일하게, `Reduce`의 `case .path:` catch-all 위에 다음 케이스 추가:
  - `case .path(.element(id: let id, action: .detail(.photoCellTapped(let index)))):`
    - `guard case .detail(let detailState) = state.path[id: id] else { return .none }`로 해당 스택 요소의 `DetailFeature.State` 언랩
    - `state.path.append(.photoViewer(PhotoViewerFeature.State(images: detailState.images, startIndex: index, title: detailState.detail.japaneseTitle)))`
    - `return .none`
  - 기존 `case .path: return .none` catch-all은 그대로 유지 (새 case가 먼저 매치되도록 위에 위치)
- `TouristSpotDetail`에 `japaneseTitle` 프로퍼티가 실제로 존재하는지 `Domain/Sources/Entity/TouristSpotDetail.swift`에서 먼저 확인 후 사용 (없으면 사용 가능한 타이틀 프로퍼티로 대체하고 임의로 새 프로퍼티를 만들지 않음)

---

#### [x] Task 5 — `TabBarView.swift`
**파일**: `Projects/Presentation/Sources/Tabbar/TabBarView.swift`
- `destination` 클로저의 `switch store.case`에 `case .photoViewer(let store): PhotoViewerView(store: store)` 추가 (기존 `case .detail(let store): DetailView(store: store, namespace: self.heroNamespace)` 다음)

---

### Phase 3. Presentation - PhotoViewerView & ZoomableImageView (UI)

#### [x] Task 6 — `ZoomableImageView.swift` (신규)
**파일**: `Projects/Presentation/Sources/PhotoViewer/Sub/ZoomableImageView.swift`
- `struct ZoomableImageView: View` (Sub/ 폴더, 해당 화면 전용)
- 프로퍼티: 표시할 `TouristSpotImage`(또는 `imageURL: URL?`), 배율 리셋 트리거용 값(예: 페이지 `index`를 받아 뷰 상단에서 `.id(index)`로 재생성하는 방식 채택 — plan의 "바인딩 or `.id` 재생성 중 택1" 중 `.id` 재생성으로 확정하면 이 파일은 내부 `@State private var scale: CGFloat = 1.0`, `@State private var lastScale: CGFloat = 1.0`만 관리)
- `KFImage(imageURL)` + `DetailHeroView`와 동일한 placeholder 패턴(`Color.getTabiColor(.tabiBorder).opacity(0.3)` + `Image(systemName: "photo")`, `TabiColor.tabiTextTertiary`)
- `MagnificationGesture()`로 `scale` 갱신, `.onEnded`에서 `lastScale`에 반영
- 배율 상/하한 clamp (하한 1.0, 상한 4.0 — plan에 명시된 예시값, 값 확정 시 하드코딩 상수로 파일 상단 `private static let` 선언)
- `.scaleEffect(self.scale)` 적용

> **구현 중 변경**: 코드 리뷰에서 `.id(index)` 재생성 방식이 스와이프할 때마다 현재 페이지뿐 아니라 모든 페이지를 강제로 재마운트시켜 불필요한 이미지 재디코딩과 인접 페이지 줌 상태 손실을 유발한다는 지적(efficiency/simplification/reuse 등 다수 관점에서 중복 확인)이 있어, `isActive: Bool` 프로퍼티 + `.onChange(of: isActive)`로 자기 자신이 비활성화될 때만 배율을 리셋하는 방식으로 변경. `MagnificationGesture` 라이브 트래킹에 걸려있던 `.animation(.tabiFast, value: scale)`도 핀치 중 지연(rubber-banding)을 유발한다는 지적에 따라 제거하고, 리셋 시점(`onChange`)에만 `withAnimation(.tabiFast)`로 감싸도록 수정.

---

#### [x] Task 7 — `PhotoViewerView.swift` (신규)
**파일**: `Projects/Presentation/Sources/PhotoViewer/PhotoViewerView.swift`
- `struct PhotoViewerView: View`
  - `@Bindable private var store: StoreOf<PhotoViewerFeature>`
  - `@Environment(\.dismiss) private var dismiss`
- `body`:
  - `TabView(selection: self.$store.currentIndex)` + `.tabViewStyle(.page(indexDisplayMode: .never))` — `DetailHeroView.imagePager` 패턴 참고
  - `ForEach(Array(self.store.images.enumerated()), id: \.element.imageURLString)`로 각 페이지에 `ZoomableImageView(...)` 배치, `.tag(index)`, `.id(index)`(배율 리셋용)
  - 상단 오버레이(`.overlay(alignment: .top)` 또는 `.toolbar`): `TabiGlassIconButton(systemName: "chevron.left") { self.dismiss() }` + `TabiLabel(title: self.store.title, style: ..., color: .tabiTextPrimary 등 기존 팔레트에서 선택, alignment: .leading)` — 기존 `TypographyStyle`/`TabiColor` 값 중 헤더에 쓰이는 것을 `DetailView`/`TabiLabel` 사용처에서 확인 후 재사용
  - 전체 배경: 풀스크린 검정/다크 배경, `.ignoresSafeArea()`
  - `.navigationBarBackButtonHidden(true)` (기존 `DetailView`처럼 시스템 back 숨김 필요 여부 확인 후 적용)
  - body 50줄 초과 시 상단 바를 `private extension`의 서브 메서드로 분리 (swift-style.md 6번 규칙)

---

#### [x] Task 8 — `PhotoViewerMock.swift` (신규, 선택)
**파일**: `Projects/Presentation/Sources/PhotoViewer/PhotoViewerMock.swift`
- `#Preview`용 `TouristSpotImage` 목 데이터 배열 정의
- `PhotoViewerView`에 `#Preview { PhotoViewerView(store: Store(initialState: PhotoViewerFeature.State(images: ..., startIndex: 0, title: "..."), reducer: { PhotoViewerFeature() })) }` 추가

---

### Phase 4. Detail 호출부 연결

#### [x] Task 9 — `DetailPhotosTabView.swift`
**파일**: `Projects/Presentation/Sources/Detail/Sub/DetailPhotosTabView.swift`
- `let onImageTapped: (Int) -> Void` 프로퍼티 추가
- `ForEach(self.images, id: \.imageURLString)` → `ForEach(Array(self.images.enumerated()), id: \.element.imageURLString)`로 변경하여 인덱스 확보
- `self.photoCell(image)` 호출부에 인덱스 전달, `photoCell(_:)` 내부(또는 호출 지점)에 이미 존재하는 `.contentShape(Rectangle())` 뒤에 `.onTapGesture { self.onImageTapped(index) }` 추가

---

#### [x] Task 10 — `DetailView.swift`
**파일**: `Projects/Presentation/Sources/Detail/DetailView.swift`
- `tabContentSection()` 내 `DetailPhotosTabView(images: self.store.images)` 호출을 `DetailPhotosTabView(images: self.store.images, onImageTapped: { self.store.send(.photoCellTapped(index: $0)) })`로 변경

---

### Phase 5. 프로젝트 재생성 & 검증

#### [x] Task 11 — Tuist 재생성
**파일**: 없음 (명령 실행)
- 신규 `.swift` 파일 추가로 인해 `tuist install && tuist generate` 실행 (stale 프로젝트 방지, CLAUDE.md 필수 규칙)

---

#### [x] Task 12 — 빌드 및 수동 검증
**파일**: 없음 (명령 실행 + 시뮬레이터 확인)
- `xcodebuild build -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`로 빌드 성공 확인
- 시뮬레이터에서 Detail Photo 탭 셀 탭 → 탭한 인덱스부터 시작하는 풀스크린 전환 확인
- 좌우 스와이프로 다른 사진 이동 확인
- 핀치 제스처로 확대/축소 확인, 상/하한 clamp 확인
- 페이지 전환 시 배율 1.0 초기화 확인
- Back 버튼 탭 시 Detail 화면으로 pop, `DetailFeature` 상태 불변 확인
- 시작 인덱스가 범위를 벗어나는 케이스(방어 로직) 크래시 없음 확인

---

## 체크리스트

### 품질 (DoD)
- [x] 빌드 성공 (`tuist generate` 후 `xcodebuild build`)
- [x] 테스트 통과 (테스트 타겟 미구성 상태 — 해당 없음, `.claude/CLAUDE.md` 참조)

### 기능 (AC)
- [x] 사진 목록을 보여주는 화면에서 사진 셀을 탭하면 탭한 사진부터 시작하는 풀스크린 화면으로 전환된다
- [x] 상단에 Back 버튼과 호출 화면이 전달한 타이틀이 표시된다
- [x] Back 버튼을 탭하면 호출한 화면으로 되돌아간다
- [x] 좌우 스와이프로 다른 사진으로 이동할 수 있다
- [x] 핀치 제스처로 확대/축소할 수 있고, 다른 사진으로 넘어가면 배율이 초기화된다
- [x] 확대/축소 배율에 상/하한이 적용되어 과도하게 늘어나거나 줄어들지 않는다
- [x] Detail 외 다른 화면에서도 동일한 방식(이미지 목록 + 인덱스 + 타이틀 전달)으로 호출할 수 있다
</content>
