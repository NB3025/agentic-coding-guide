# Kiro 구현 가이드

12가지 에이전틱 개발 패턴을 Kiro에서 구현하는 방법.

## 1. Steering 파일 설치

```bash
# 프로젝트 루트에서
mkdir -p .kiro/steering
cp steering/* .kiro/steering/
```

### 파일 구성

| 파일 | 역할 | 관련 패턴 |
|------|------|----------|
| `conventions.md` | 커밋 규칙, 코드 품질, 세션 시작 | #1, #2, #5, #8, #11 |
| `boundaries.md` | Always / Ask first / Never | #3, #4, #7, #12 |
| `self-review.md` | 완료 전 체크리스트 | #6, #9, #12 |
| `learnings.md` | 학습 기록 (자동 축적) | #3 |

> `product.md`, `tech.md`, `structure.md`는 Kiro가 자동 생성하므로 별도 제공하지 않음.
> `learnings.md`는 steering 폴더에 있으므로 Kiro가 자동으로 컨텍스트에 로드한다.

**Session Seeding (#1)은 별도 Hook 없이 steering으로 해결한다.** conventions.md에 "세션 시작 시 git log + git status" 규칙이 있고, Kiro가 steering을 매 세션 자동 로드하므로 에이전트가 첫 태스크에서 자연스럽게 컨텍스트를 확인한다. Manual Trigger Hook은 별도 세션에서 실행되어 작업 세션에 컨텍스트가 주입되지 않으므로 steering 방식이 더 효과적이다.

## 2. Hook 설정

### 방법 A: 파일 복사 (권장)

```bash
# Hook 파일을 프로젝트에 복사
cp hooks/*.kiro.hook .kiro/hooks/
```

| 파일 | 이벤트 | 역할 |
|------|--------|------|
| `post-task-review.kiro.hook` | Post Task Execution | 체크리스트 + 학습 정리 + 커밋 |
| `periodic-review.kiro.hook` | Manual Trigger (`/review`) | 규칙 리뷰 + 패턴 승격 + 히스토리 정리 |

### 방법 B: Kiro UI에서 수동 생성

Kiro UI에서 아래 2개 Hook을 생성한다.

### Hook 1: Post Task Execution — 태스크 완료 후

| 필드 | 값 |
|------|-----|
| Title | Post Task Review & Commit |
| Description | 태스크 완료 후 체크리스트 + 학습 정리 + 커밋 |
| Event | Post Task Execution |
| Action | Ask Kiro |

**Instructions:**
```
이번 태스크 완료 후 다음 3가지를 순서대로 수행하라:

## 1. 체크리스트 실행
.kiro/steering/self-review.md를 읽고 체크리스트를 실행하라.
통과하지 못한 항목이 있으면 즉시 수정하라.

## 2. 학습 정리
이번 태스크에서 배운 것을 .kiro/steering/learnings.md에 append하라.
단, 배운 것이 없으면 기록하지 마라. 억지로 채우지 말 것.

기록할 것이 있을 때만 아래 형식으로:

## {오늘 날짜} — {태스크 이름/번호}

### 실패한 접근법 (있는 경우만)
- {시도한 것}
  - Why: {왜 실패했는지}
  - How to apply: {다음에 어떻게 할지}

### 발견한 패턴 (있는 경우만)
- {패턴 이름}
  - Why: {왜 효과적인지}
  - How to apply: {어떤 상황에서 적용할지}

규칙:
- 이미 learnings.md에 있는 내용과 중복이면 생략
- 3회 이상 반복 등장한 패턴은 boundaries.md에 영구 추가를 권고
- 50건 초과 시 오래된 항목부터 삭제

## 3. 커밋
이번 태스크의 변경사항을 커밋하라.
- `git add .` 금지 — 변경한 파일만 개별 `git add`
- node_modules, .env, dist, build 등 빌드 산출물/의존성은 절대 추가하지 말 것
- .gitignore가 있으면 반드시 준수
- 커밋 전 `git diff --cached`로 추가된 파일 목록을 확인하고, 의도하지 않은 파일이 포함되어 있으면 제거
- 커밋 메시지 형식: <type>(<scope>): <description>
  - type: feat, fix, test, refactor, docs, chore
- 커밋 전 모든 테스트가 통과하는지 확인
```

### Hook 2: `/review` — 사후 리뷰 (Manual Trigger)

| 필드 | 값 |
|------|-----|
| Title | Periodic Review |
| Description | 규칙 리뷰 + 히스토리 정리 + 패턴 승격 |
| Event | Manual Trigger |
| Action | Ask Kiro |

**Instructions:**
```
사후 리뷰를 실행하라:

## 1. 규칙 리뷰 (#3 반복 실수 → 규칙 추가)
.kiro/steering/boundaries.md를 읽고:
- 아직 유효한 규칙인가?
- 단순화할 수 있는 규칙은?
- 중복은?
- 최근 반복된 실수 중 추가해야 할 것은?
수정이 필요하면 직접 수정하라.

## 2. 학습 정리 (learnings → boundaries 승격)
.kiro/steering/learnings.md에서:
- 3회 이상 반복된 패턴 → boundaries.md에 영구 추가
- 승격된 항목은 learnings.md에서 제거
- 60일 이상 경과 + 최근 참조 없는 항목 → 삭제

## 3. Git 히스토리 정리 (#10)
현재 브랜치의 커밋을 확인하고:
- 의미 없는 연쇄 커밋이 있으면 squash 제안
- 잘못된 커밋 메시지가 있으면 수정 제안
실제 rebase는 제안만 하고 실행하지 말 것 — 사용자가 판단.

리뷰 결과를 요약하여 보고하라.
```

## 3. 전체 흐름

```
프로젝트 셋업 (1회)
├── Kiro: Generate steering docs (product.md, tech.md, structure.md)
├── steering 파일 4개 복사
└── Hook 1~2 생성

개발 세션
├── 첫 태스크 시작 → steering 자동 로드 → git log + 컨텍스트 확인
├── Spec 생성 (requirements → design → tasks)
├── 태스크 실행:
│   ├── 코드 구현
│   └── [Post Task Hook] 체크리스트 + 학습 정리 + 커밋
└── /review → 규칙 리뷰 + 패턴 승격 + 히스토리 정리
```

## 4. 패턴 커버리지

| Phase | 패턴 | 커버 방법 |
|-------|------|----------|
| Phase 0 셋업 | #5 짧은 규칙, #11 스택, #4 금지, #12 보안 | steering 4파일 |
| Phase 1 세션 시작 | #1 git log | conventions.md (steering 자동 로드) |
| Phase 2 작업 중 | #2 체크포인팅, #8 커밋 | conventions.md + Post Task 커밋 |
| Phase 3 완료 시 | #6 셀프리뷰, #9 문서, #12 재검증 | Post Task hook |
| Phase 4 문제 시 | #7 bisect | boundaries.md (수동 참조) |
| Phase 5 사후 | #3 실수→규칙, #10 히스토리 | `/review` manual trigger |
| 학습 시스템 | 피드백 루프 패턴 | Post Task + learnings.md |
