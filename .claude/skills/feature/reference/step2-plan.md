# Step 2. plan 생성

## Step 2-1. Plan SubAgent 실행

Agent 도구를 model: "opus" 로 아래 내용으로 실행한다:

```
역할: Plan 작성 전문가
목표: spec.md를 분석하여 plan.md를 작성한다.

## 수행할 작업

1. `.claude/specs/features/$ARGUMENTS/spec.md` 를 읽는다
2. spec.md 의 `## 무엇에 의존하는가` 에 명시된 파일을 읽고 현재 상태를 파악한다
   - 명시되지 않은 경우 spec.md 내용 기반으로 영향 범위를 직접 판단한다
3. `.claude/templates/plan.template.md` 를 읽는다
4. 템플릿을 참고하여 plan.md 를 작성한다
   - 코드는 작성하지 않는다
5. `.claude/specs/features/$ARGUMENTS/plan.md` 로 저장한다
6. 작성 완료 후 plan.md 전체 내용을 반환한다
```

## Step 2-2. 인간 확인

SubAgent 완료 후:

```
✅ plan.md 생성 완료
📁 위치: .claude/specs/features/$ARGUMENTS/plan.md

plan.md 를 검토해주세요.
계속하려면 '확인', 수정이 필요하면 내용을 알려주세요.
```

'확인' 입력 후 `step3-tasks.md` 를 읽고 절차를 따른다.
