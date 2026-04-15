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

## 역할 분리

## CLI 대화형 명령어 처리 규칙
- 대화형 프롬프트가 발생할 수 있는 CLI 명령어는 항상 `echo "y" |`를 앞에 붙여 실행한다
- 예시: `echo "y" | npm create vite@latest frontend -- --template react-ts`
- 적용 대상: `npm create`, `npx create-*`, `git` 등 사용자 입력을 요구할 수 있는 모든 명령어
- 이유: 자동화 환경에서 대화형 프롬프트는 실행을 블로킹하므로 반드시 우회해야 한다

## AI Agent SDK
- Bedrock Agent는 사용하지 않음
- 대신 Strands-Agents SDK를 사용

## 기술 스택 (#11 Stack Declaration)
<!-- 프로젝트에 맞게 수정하세요 -->
- Language: (여기에 작성)
- Runtime: (여기에 작성)
- Framework: (여기에 작성)
- DB: (여기에 작성)
- Testing: (여기에 작성)
- Package Manager: (여기에 작성)
- Linter/Formatter: (여기에 작성)
