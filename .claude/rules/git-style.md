---
name: git-style
description: Git 커밋 컨벤션을 정의한 문서. 커밋 메시지 작성 시 항상 이 규칙을 따른다.
---

## 커밋 메시지 형식

```
<type>(변경된 부분 > 상세): 제목 (A)
```

---

## Type

| type | 사용 상황 |
|------|---------|
| `Feat` | 새로운 기능 추가 |
| `Fix` | 버그 수정 |
| `Style` | 기능 수정 없이 코드 스타일만 변경 |
| `Design` | 디자인만 수정 시 |
| `Test` | 테스트 코드 추가/수정 |
| `Build` | 빌드와 관련된 작업 수정 시 |
| `Refactor` | 동일한 기능을 더 나은 코드로 바꿨을 때 |
| `Chore` | 폴더 작업 시 |

---

## 변경된 부분

| 변경된 부분 | 사용 상황 |
|------------|---------|
| `Main` | 메인 탭 상위 화면 |
| `Home` | 홈 화면 |
| `Detail` | 상세 화면 |
| `Tabbar` | 탭바 |
| `Root` | 앱 루트 화면 |
| `Domain` | Domain 모듈 (UseCase/Entity 등) |
| `Data` | Data 모듈 (Repository 등) |
| `DataLoad` | 네트워킹/데이터 로딩 |
| `Network` | 네트워크 레이어 |
| `DesignSystem` | DesignSystem 모듈 |
| `Presentation` | Presentation 모듈 전반 |
| `Resource` | 리소스 |
| `Core` | Core 모듈 |
| `DIContainer` | 의존성 주입 설정 |
| `Util` | 유틸 |
| `App` | 빌드 및 앱 전반 |

---

## 제목 작성 규칙

- 한국어로 작성
- 명사형 또는 동사형으로 마무리 (예: "예외처리 추가", "색상 값 수정")
- 50자 이내
- 마침표 없음
- 가장 마지막에는 `(CC)` 키워드 추가
- Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>과 같은 정보는 적지 않음
