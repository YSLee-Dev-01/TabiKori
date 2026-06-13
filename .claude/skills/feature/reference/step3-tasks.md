# Step 3. tasks 생성

## Step 3-1. Tasks SubAgent 실행

Agent 도구를 model: "sonnet" 으로 아래 내용으로 실행한다:

```
역할: Tasks 작성 전문가
목표: spec.md 와 plan.md 를 분석하여 tasks.md 를 작성한다.

## 수행할 작업

1. `.claude/specs/features/$ARGUMENTS/spec.md` 를 읽는다
2. `.claude/specs/features/$ARGUMENTS/plan.md` 를 읽는다
3. `.claude/templates/tasks.template.md` 를 읽는다
4. 템플릿을 참고하여 tasks.md 를 작성한다
   - spec.md 와 plan.md 를 참고하여 Task별 파일 경로와 구현 내용을 구체적으로 채운다
   - 코드는 작성하지 않는다
5. `.claude/specs/features/$ARGUMENTS/tasks.md` 로 저장한다
6. 작성 완료 후 tasks.md 전체 내용을 반환한다
```

## Step 3-2. 인간 확인

SubAgent 완료 후:

```
✅ tasks.md 생성 완료
📁 위치: .claude/specs/features/$ARGUMENTS/tasks.md

tasks.md 를 검토해주세요.
계속하려면 '확인', 수정이 필요하면 내용을 알려주세요.
```

'확인' 입력 후 `step4-implement.md` 를 읽고 절차를 따른다.
