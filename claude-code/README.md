# Claude Code 구현 가이드

12가지 에이전틱 개발 패턴을 Claude Code에서 구현하는 방법.

## 1. CLAUDE.md 설치

```bash
# 프로젝트 루트에 복사
cp CLAUDE.md ./CLAUDE.md
# 프로젝트에 맞게 수정
```

Claude Code는 세션 시작 시 `CLAUDE.md`를 자동으로 로드한다. Kiro의 steering 여러 파일과 달리 **하나의 파일에 모든 규칙을 담는** 구조.

## 2. 파일 구성

```
project/
├── CLAUDE.md              # 메인 규칙 (자동 로드)
└── .claude/
    ├── learnings.md       # 학습 기록 (Pattern #3)
    └── hooks/             # 자동화 훅
```

### CLAUDE.md 구조

```markdown
# Project Rules

## Stack (#11)
- Language: TypeScript 5.x (strict mode)
- Runtime: Node.js 22
- ...

## Conventions (#5, #8)
- 커밋 형식: <type>(<scope>): <description>
- 하나의 논리적 변경 = 하나의 커밋
- ...

## Boundaries (#4, #12)

### ✅ Always
- ...

### ⚠️ Ask first
- ...

### 🚫 Never
- ...

## Self-Review Checklist (#6, #9, #12)
태스크 완료 전 반드시 실행:
- [ ] 테스트 통과?
- [ ] 보안 이슈 없음?
- [ ] 문서 업데이트?
- ...

## Session Start (#1)
세션 시작 시:
1. `git log --oneline -15`
2. `git status`
3. `.claude/learnings.md` 최근 항목 확인
```

## 3. Hooks 설정

Claude Code의 Hook 시스템으로 자동화할 수 있다.

### Post-Task Hook: 학습 + 커밋

`.claude/hooks/post-task.md`:
```
태스크 완료 후:
1. Self-Review 체크리스트 실행
2. 학습할 것이 있으면 .claude/learnings.md에 append
3. 변경 파일만 개별 git add → 커밋
```

### 학습 → 규칙 승격

`/review` 명령어로 수동 트리거:
```
.claude/learnings.md에서:
- 3회+ 반복 패턴 → CLAUDE.md Boundaries에 영구 추가
- 60일+ 경과 + 미참조 → 삭제
```

## 4. Kiro와 차이점

| 항목 | Kiro | Claude Code |
|------|------|------------|
| 규칙 파일 | steering/ 여러 파일 | CLAUDE.md 단일 파일 |
| Hook 트리거 | UI에서 설정 | .claude/hooks/ 디렉토리 |
| 자동 생성 | product.md, tech.md 등 | 없음 (수동) |
| Spec 시스템 | requirements → design → tasks | 없음 (자유) |
| 학습 저장 | steering/learnings.md | .claude/learnings.md |

## 5. 전체 흐름

```
프로젝트 셋업 (1회)
├── CLAUDE.md 복사 + 프로젝트에 맞게 수정
├── .claude/learnings.md 생성
└── Hook 설정 (선택)

개발 세션
├── 세션 시작 → CLAUDE.md 자동 로드 + git log
├── 태스크 실행
│   ├── 코드 구현
│   └── 셀프 리뷰 + 학습 정리 + 커밋
└── /review → 규칙 리뷰 + 패턴 승격
```
