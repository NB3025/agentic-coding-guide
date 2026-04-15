# Project Rules

## Stack
<!-- 프로젝트에 맞게 수정하세요 -->
- Language: TypeScript 5.x (strict mode)
- Runtime: Node.js 22
- Framework: (여기에 작성)
- DB: (여기에 작성)
- Testing: Vitest
- Package Manager: pnpm
- Linter/Formatter: Biome

## Conventions
- 하나의 논리적 변경 = 하나의 커밋
- 변경 전 반드시 현재 상태 커밋 (checkpoint)
- 커밋 형식: `<type>(<scope>): <description>`
  - type: feat, fix, test, refactor, docs, chore
- 커밋 메시지는 "무엇을 왜"를 담을 것
- 새 기능에는 반드시 테스트 작성
- 기존 테스트가 깨지면 즉시 수정
- 린트/포맷 통과 확인 후 커밋

## Boundaries

### ✅ Always
- 테스트 작성 후 커밋
- 입력 검증 (사용자 입력, API 응답)
- 환경변수로 시크릿 관리
- 에러 핸들링 포함

### ⚠️ Ask first
- 기존 아키텍처 변경
- 새 외부 의존성 추가
- DB 스키마 변경
- 기존 API 인터페이스 변경

### 🚫 Never
- 시크릿을 코드에 하드코딩
- 프로덕션 DB에 직접 접근
- 테스트 없이 커밋
- 기존 테스트 삭제 (수정은 OK)
- `any` 타입 남용
- console.log 디버깅 코드 커밋
- N+1 쿼리
- 루프 내 API 호출

## Self-Review Checklist
태스크 완료 전 반드시 실행:

### 기능
- [ ] 변경한 코드가 의도대로 동작하는가?
- [ ] 엣지 케이스를 처리했는가?
- [ ] 에러 핸들링이 포함되어 있는가?

### 테스트
- [ ] 새 코드에 대한 테스트를 작성했는가?
- [ ] 기존 테스트가 모두 통과하는가?
- [ ] 테스트가 실제 동작을 검증하는가 (구현 디테일이 아닌)?

### 보안
- [ ] 사용자 입력을 검증하는가?
- [ ] 시크릿이 코드에 포함되지 않았는가?
- [ ] 적절한 인증/인가가 적용되었는가?

### 성능
- [ ] N+1 쿼리가 없는가?
- [ ] 불필요한 데이터 로딩이 없는가?

### 문서
- [ ] API 변경 시 관련 문서도 업데이트했는가?
- [ ] 복잡한 로직에 주석을 달았는가?

### 규칙 준수
- [ ] Boundaries의 🚫 Never 항목을 위반하지 않았는가?
- [ ] Conventions의 커밋 규칙을 따랐는가?

## Session Start
세션 시작 시:
1. `git log --oneline -15` 실행하여 최근 작업 확인
2. `git status` 실행하여 현재 상태 확인
3. `.claude/learnings.md` 최근 항목 참조

## Learning
- 태스크 완료 시 배운 것이 있으면 `.claude/learnings.md`에 기록
- 3회 이상 반복된 패턴은 이 파일의 Boundaries에 영구 추가

## Debugging
- 문제 발생 시 `git bisect`로 원인 커밋을 이진 탐색
- 자동화: `git bisect run <test-command>`

## History Hygiene
- 기능 브랜치 merge 전 `git rebase -i`로 히스토리 정리
- checkpoint 커밋은 squash, 의미 없는 연쇄 커밋 정리
- main 브랜치에서 rebase 금지
