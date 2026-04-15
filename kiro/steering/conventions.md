# 개발 컨벤션

## 커밋 규칙 (#2 Checkpointing + #8 Conventional Commits)
- 하나의 논리적 변경 = 하나의 커밋
- 변경 전 반드시 현재 상태 커밋 (checkpoint)
- 커밋 형식: `<type>(<scope>): <description>`
  - feat, fix, test, refactor, docs, chore
- 커밋 메시지는 "무엇을 왜"를 담을 것 — vague한 "fix stuff" 금지

## 코드 품질
- 새 기능에는 반드시 테스트 작성
- 기존 테스트가 깨지면 즉시 수정
- 린트/포맷 통과 확인 후 커밋

## 세션 시작 시 (#1 git log 시딩)
- `git log --oneline -15`로 최근 작업 확인
- `git status`로 현재 상태 확인
- `.kiro/steering/learnings.md` 있으면 최근 학습 참조

## 기술 스택 (#11 Stack Declaration)
<!-- 프로젝트에 맞게 수정하세요 -->
- Language: (여기에 작성)
- Runtime: (여기에 작성)
- Framework: (여기에 작성)
- DB: (여기에 작성)
- Testing: (여기에 작성)
- Package Manager: (여기에 작성)
- Linter/Formatter: (여기에 작성)
