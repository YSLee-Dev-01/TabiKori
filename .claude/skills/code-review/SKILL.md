---
name: code-review
description: Swift 변경사항을 swift-code-reviewer 서브에이전트에 위임해 리뷰한다. "코드 리뷰해줘", "review", "리뷰해줘" 등의 요청 시 사용한다.
argument-hint: "[파일/디렉토리 경로 | --last N]"
allowed-tools:
  - Bash(git status *)
  - Bash(git diff *)
  - Bash(git log *)
  - Agent
---

# code-review

$ARGUMENTS 범위의 Swift 변경사항을 `swift-code-reviewer` 서브에이전트에 위임해 리뷰한다.
리뷰 관점·심각도 기준·출력 포맷은 전부 `.claude/agent/swift-code-reviewer.md`에 정의되어 있으므로, 이 스킬은 대상 범위만 판단해서 위임하고 직접 분석하지 않는다.

---

## 실행 절차

1. `$ARGUMENTS`로 대상 범위 판단
   - 파일/디렉토리 경로가 주어지면 해당 경로 그대로 사용
   - `--last N` 형태면 그대로 사용 (에이전트가 `git log`/`git diff HEAD~N...HEAD`로 직접 처리)
   - 인자가 없으면 아래 순서로 변경된 Swift 파일이 있는지만 먼저 확인 (없는 조합은 건너뜀):
     1. `git diff --name-only origin/main...HEAD`
     2. `git diff --name-only --cached`
     3. `git diff --name-only HEAD`
   - 위 세 시도 모두 결과가 없으면 중단하고 아래 메시지 출력:
     ```
     ❌ 리뷰할 변경된 Swift 파일이 없습니다.
     ```
2. Agent 도구로 `swift-code-reviewer` 서브에이전트를 호출하며, 판단한 대상 범위(경로 또는 `--last N` 또는 "자동 탐지")를 프롬프트에 명시해 전달
3. 서브에이전트의 리뷰 결과를 그대로 사용자에게 출력 — 스킬이 내용을 재가공하거나 요약하지 않는다

---

## 인자 예시

- `/code-review` → 변경된 Swift 파일 자동 탐지
- `/code-review --last 3` → 최근 3개 커밋 기준
- `/code-review Projects/Presentation/Sources/Map/MapFeature.swift` → 특정 파일
- `/code-review Projects/Presentation/Sources/Map/` → 디렉토리 전체

---

## ✅ 검토 체크리스트

- [ ] 대상 범위(파일/디렉토리/커밋 범위)를 정확히 판단했는지
- [ ] 변경된 `.swift` 파일이 하나도 없는 경우 서브에이전트 호출 없이 중단했는지
- [ ] `swift-code-reviewer` 서브에이전트에 판단한 범위를 명확히 전달했는지
- [ ] 서브에이전트 출력을 임의로 축약·수정하지 않고 그대로 전달했는지
