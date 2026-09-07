---
name: test-style
description: 테스트 컨벤션을 정의한 문서
globs:
  - "Projects/*/Tests/**/*.swift"
---

> 현재 레포에는 테스트 타겟이 아직 구성되어 있지 않음 (`.claude/CLAUDE.md` 참조). 아래는 추가 시 따를 규칙이며, 워크스페이스/스킴/타겟명은 실제 구성 시점에 맞춰 확인할 것

## 테스트 명령어

```bash
# 전체 테스트
xcodebuild test -workspace Tabikori.xcworkspace -scheme AppDebug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# 단일 클래스
xcodebuild test ... -only-testing:{Module}Tests/{Name}FeatureTests

# 단일 메서드
xcodebuild test ... -only-testing:{Module}Tests/{Name}FeatureTests/testSomething
```

---

## 1. 네이밍

- 클래스명: `{Name}FeatureTests`
- 메서드명: `func test{시나리오}`

```swift
func testDetailInit()
func testTouristSpotFetchError()   // 에러 케이스는 Error 접미사
```

---

## 2. TCA Feature 테스트 구조

```swift
class XxxFeatureTests: XCTestCase {

    // MARK: - Properties
    
    var mockManager: TestXxxManager!

    // MARK: - LifeCycle
    
    override func setUp() {
        self.mockManager = TestXxxManager()
        self.mockManager.someData = dummyData       // 테스트 데이터 주입
    }

    // MARK: - Tests
    
    func testSomething() async throws {
        // GIVEN
        let testStore = await self.createStore()

        // WHEN
        await testStore.send(.someAction) { state in
            // THEN
            state.someProperty = expectedValue
        }

        // THEN (파생 effect 검증)
        await testStore.receive(.derivedAction) { state in
            state.anotherProperty = anotherValue
        }
    }
}

// MARK: - Methods

private extension XxxFeatureTests {
    func createStore() async -> TestStoreOf<XxxFeature> {
        let store = await TestStore(
            initialState: XxxFeature.State(),
            reducer: { XxxFeature() },
            withDependencies: { dependency in
                dependency.xxxManager = self.mockManager
            }
        )
        store.exhaustivity = .off(showSkippedAssertions: false)
        return store
    }
}
```

**규칙:**
- `createStore()`는 `private extension`에 분리
- `exhaustivity = .off(showSkippedAssertions: false)` 기본 설정
- `send()` 클로저에서 state 변화 검증, `receive()`로 파생 액션 검증
- `#if DEBUG` 헬퍼 프로퍼티 접근 시 `$0.testXXX` 형태 사용

---

## 3. 테스트 더블 작성

```swift
// Test{Name} — TCA 의존성(testValue)용, 프로토콜 채택 + 데이터 주입용 var 프로퍼티 공개
public final class TestTouristSpotUseCase: TouristSpotUseCaseProtocol, @unchecked Sendable {
    public var nearbySpots: [TouristSpot] = []

    public func fetchNearbySpots(
        contentType: CategoryType,
        coordinate: Coordinate,
        radiusMeters: Int
    ) async throws -> [TouristSpot] {
        return self.nearbySpots
    }
}
```

**규칙:**
- TCA 의존성 더블: `Test{Name}` 접두사, 프로토콜 채택, 데이터 주입용 `var` 프로퍼티 공개
- 위치: `Domain/Sources/UseCase/{FeatureName}/Test{Name}UseCase.swift` — `TestDependencyKey.testValue`가 참조하므로 테스트 타겟이 아닌 `Domain` 모듈 본체에 위치 (`.claude/rules/folder-structure.md` 참조)
- 순수 XCTest 전용 더블(위 패턴에 해당하지 않는 것)은 테스트 타겟 구성 시 `{Module}Tests/Mock/`에 위치

---

## 4. GIVEN / WHEN / THEN 주석

모든 테스트에 GIVEN / WHEN / THEN 주석 필수. 여러 단계가 있으면 반복 사용:

```swift
// GIVEN
let testStore = await self.createStore()

// WHEN
await testStore.send(.buttonTapped)

// THEN
await testStore.receive(.dataLoaded) { state in
    state.items = expectedItems
}

// WHEN (2번째 인터랙션)
await testStore.send(.refreshTapped)

// THEN
await testStore.receive(.dataLoaded)
```
