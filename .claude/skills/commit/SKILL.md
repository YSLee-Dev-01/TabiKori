---
name: commit
description: 변경사항을 분석해 스테이징부터 커밋 메시지 작성까지 직접 수행한다. "커밋 메시지 작성", "커밋 해줘" 등의 요청 시 사용한다.
allowed-tools:
  - Bash(git status *)
  - Bash(git diff *)
  - Bash(git add *)
  - Bash(git commit *)
---

# 커밋

변경사항을 분석하여 커밋 대상 파일을 직접 스테이징하고, 커밋 메시지 초안을 생성한다.
컨벤션은 `git-style` Rule을 따른다.

---

## 실행 절차

1. `git status`로 staged / unstaged / untracked 변경사항 전체 확인
   - 아무 변경사항도 없으면 중단하고 아래 메시지 출력:
     ```
     ❌ 변경된 파일이 없습니다.
     ```
2. `git diff`(unstaged) + 이미 staged된 diff + untracked 파일 내용을 읽어 변경 내용을 분석
3. 논리적으로 하나의 커밋에 포함될 파일을 판단해 스테이징 대상 목록 결정
   - `git add -A`, `git add .` 금지 — 대상 파일을 경로로 명시해서 `git add`
   - 서로 무관한 변경이 섞여 있으면(예: 기능 변경 + 무관한 오타 수정) 커밋을 분리할지 **AskUserQuestion으로 반드시 물어본다** (텍스트로 묻지 않는다)
   - `.gitignore` 대상이거나 시크릿/자격증명으로 보이는 파일은 자동 제외하고 경고 출력
4. 결정한 파일들을 별도 확인 없이 바로 `git add`로 스테이징
5. 스테이징된 파일 목록을 사용자에게 보여줌
6. 변경사항을 분석하여 적절한 type 선택, 제목 작성
7. 커밋 메시지 초안을 출력하고 사용자 확인을 받은 후에만 `git commit` 실행

> **IMPORTANT**: 스테이징 대상은 항상 명시적 경로로 지정한다 (`-A`/`.` 금지)
> **IMPORTANT**: 커밋 분리 여부 등 사용자 판단이 필요한 질문은 텍스트가 아닌 AskUserQuestion 도구로 묻는다
> **IMPORTANT**: `git add`는 사용자 확인 없이 바로 실행한다 (커밋 직전 확인 절차만 유지)
> **IMPORTANT**: 시크릿/자격증명으로 의심되는 파일은 절대 add하지 않는다
> **IMPORTANT**: 커밋 메시지에 `Co-Authored-By` 트레일러를 절대 추가하지 않는다

---

## 출력 형식

```
<type>(변경된 부분 > 상세): 제목 (CC)
```

---

## 출력 예시

```
Design(Main > CongestionModal): Padding 값 조정 (CC)
```

---

## ✅ 검토 체크리스트

- [ ] 스테이징된 파일이 이번 논리적 변경과 관련 있는지 확인
- [ ] 무관한 변경이 섞여 있었다면 AskUserQuestion으로 분리 여부를 확인했는지 점검
- [ ] 시크릿/의심 파일이 스테이징에 포함되지 않았는지 확인
- [ ] type이 변경사항의 성격과 일치하는지 확인
- [ ] 제목이 변경 내용을 정확하게 요약하는지 확인
