---
name: prompt
model: opus
description: 요구사항을 분석하고 질문 후 구현 프롬프트를 생성한다.
argument-hint: 요구사항
allowed-tools:
  - Read
  - Bash(find *)
  - Bash(ls *)
  - Bash(grep *)
  - AskUserQuestion
---

# prompt

$ARGUMENTS 요구사항을 분석하여 Claude에 붙여넣을 구현 프롬프트를 생성한다.
코드를 직접 수정하지 않는다.

---

## 실행 절차

### Step 1 — 요구사항 분석

$ARGUMENTS를 읽고 아래 항목을 파악한다.

1. **목표** — 무엇을 만들거나 변경해야 하는가
2. **범위** — 영향받는 모듈(App/Presentation/Domain/Data/DesignSystem/Resource/Core)·화면·기능
3. **기존 패턴 참조** — 유사한 기존 Feature/UseCase/Repository 경로 식별 및 핵심 구조 파악
4. **기술 선택지** — 구현 방법이 여러 개인 부분 식별 (예: 새 UseCase 추가 vs 기존 확장)
5. **미결 사항** — 명시되지 않은 세부 동작, 엣지 케이스, 설계 결정이 필요한 부분

분석 시 읽어야 할 컨텍스트:
- `.claude/CLAUDE.md` — 프로젝트 개요, 모듈 구성, TCA 의존성 등록 패턴
- `.claude/rules/swift-style.md` — 네이밍, TCA 패턴(State/Action/body), 접근 제어
- `.claude/rules/folder-structure.md` — 모듈별 디렉토리 구조, 파일 배치 규칙
- `.claude/rules/test-style.md` — TCA TestStore 작성 규칙 (테스트 필요 시)
- 관련 기존 Feature/UseCase/Repository 파일 (필요 시 Read)

### Step 2 — 질문

분석에서 도출된 **함께 결정해야 할 사항**을 AskUserQuestion으로 질문한다.

질문 대상:
- 구현 방향에 영향을 미치는 설계 선택지 (예: 새 파일 vs 기존 파일 확장, 새 UseCase vs 기존 UseCase 확장)
- 명시되지 않은 UI/UX 동작 (예: 로딩 중 표시 방식, 에러 처리, 빈 상태 처리)
- DesignSystem/Resource에 재사용 가능한 컴포넌트가 없어 새로 만들어야 하는 경우 확인
- 모호한 요구사항

질문하지 않는 것:
- 컨벤션이나 기존 패턴으로 명확히 결정되는 사항
- 사소한 구현 세부사항

각 질문은 반드시 2~4개의 선택지를 제시한다.

### Step 3 — 프롬프트 생성

Step 1 분석과 Step 2 답변을 바탕으로 아래 형식의 프롬프트를 출력한다.
프롬프트 블록만 출력한다. 앞뒤로 부연 설명을 덧붙이지 않는다.
프롬프트는 task 단위로 상세하게 작성한다.

---

출력 형식:

```
## 목표
(무엇을 구현하는지 1~2줄 요약)

## 컨텍스트
### 관련 파일
- (기존 Feature/UseCase/Repository 등 참조 파일 경로와 역할)

### 적용할 패턴
- (TCA State/Action/body 구조, TCA Dependency 등록 패턴(testValue/liveValue 분리), DesignSystem 컴포넌트 재사용 등 해당 패턴)

### 영향받는 모듈
- (App/Presentation/Domain/Data/DesignSystem/Resource/Core 중 해당 모듈과 이유)

## 요구사항
(확정된 요구사항을 번호 목록으로 구체적으로 서술. 질문 답변 반영)

## 구현 지침
(파일 생성/수정 순서, 주의사항, 제약 조건, tuist generate 필요 여부 등)

## 완료 기준
- [ ] (검증 가능한 기준 1)
- [ ] (검증 가능한 기준 2)
- [ ] ...

 task를 나누어서 의존성을 설정 후 작업해줘
```

해당 프롬프트는 바로 붙여넣을 수 있게 클립보드에 추가한다.
