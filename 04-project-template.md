# 04. 프로젝트 템플릿

> 실제 프로젝트에 바로 적용할 수 있는 파일 세트.
> 각 파일이 어떤 패턴에서 왔는지, 어떤 부분을 프로젝트에 맞게 수정해야 하는지 표시.

---

## 디렉토리 구조

```
project/
├── CLAUDE.md (or AGENTS.md)           ← 루트 규칙 파일
├── .claude/skills/                     ← 또는 .cursor/rules/, docs/agent-guides/
│   └── self-review/SKILL.md           ← 완료 전 체크리스트
└── (git 운용 — 파일이 아닌 워크플로우)
```

최소 파일은 **2개** — 루트 규칙 파일 + self-review 스킬.
나머지는 프로젝트 복잡도에 따라 추가.

---

## 파일 1: 루트 규칙 파일

파일명: `CLAUDE.md` 또는 `AGENTS.md`
분량: 60~100줄 (#5)

아래는 **수정이 필요한 부분을 `[  ]`로 표시**한 템플릿이다.
`[  ]` 부분만 프로젝트에 맞게 채우면 된다.

```markdown
# [프로젝트명]

[프로젝트 한 줄 설명]

## Tech Stack
- [언어 + 버전]: [예: Python 3.12]
- [프레임워크 + 버전]: [예: FastAPI 0.115]
- [패키지 관리]: [예: uv]
- [데이터베이스]: [예: PostgreSQL 16 + SQLAlchemy 2.0]

## Commands
```bash
# 테스트 (파일 단위 — 빠름)
[예: pytest tests/test_auth.py -x --tb=short]

# 테스트 (전체 — 느림, PR 전에만)
[예: pytest --tb=short]

# 린트
[예: ruff check src/]

# 포맷
[예: ruff format src/]

# 빌드
[예: docker build -t myapp .]
```

## Session Start
매 세션 시작 시:
1. `git log --oneline -15` 로 최근 작업 확인
2. `git status` 로 현재 브랜치와 상태 확인
3. 이전 작업 이어가기면 관련 파일 변경 이력 확인

## Commit Rules
- 하나의 논리적 변경 = 하나의 커밋
- 새 방향 작업 전에 현재 상태 커밋 (checkpoint)
- 형식: `<type>(<scope>): <description>`
  - type: feat, fix, refactor, test, docs, chore
  - scope: [이 프로젝트의 모듈명들]

## Boundaries
- ✅ Always: 테스트 통과 후 커밋, 타입 힌트 포함, [프로젝트 고유]
- ⚠️ Ask first: 새 의존성 추가, 스키마 변경, [프로젝트 고유]
- 🚫 Never: .env 커밋, [프로덕션 리소스 직접 접근], [프로젝트 고유 금지]

## Security
- [이 프로젝트의 입력 검증 방법]
- [시크릿 관리 방법]
- [SQL 파라미터화 등 해당하는 것만]

## Performance
- [이 프로젝트에서 발생 가능한 성능 이슈 — 해당하는 것만]

## 완료 전
- .claude/skills/self-review/SKILL.md 의 체크리스트 실행

## 문서 동기화
코드 변경 시 관련 문서도 같은 커밋/PR에서 업데이트.
코드만 바뀌고 문서가 안 바뀌면 완료가 아님.
```

### 패턴 매핑

| 섹션 | 패턴 출처 | 실제 레포 레퍼런스 |
|------|-----------|-------------------|
| Tech Stack, Commands | #11 (GitHub Blog 2,500개 분석) | obviousworks `agent_template.md`, Exceptionless `AGENTS.md` |
| Session Start | #1 (Simon Willison) | Anthropic `coding_prompt.md` Step 1 |
| Commit Rules | #2 (Claude Code), #8 (Groff.dev) | Anthropic `coding_prompt.md` Step 8, obviousworks `agent_template.md` Git Workflow |
| Boundaries | #4 (GitHub Blog, Groff.dev) | Exceptionless `AGENTS.md` Constraints, obviousworks `agent_example.md` DO NOT Use |
| Security, Performance | #12 (Agent READMEs 논문) | obviousworks `agent_template.md` Security 섹션, Foundatio `AGENTS.md` Performance |
| 완료 전 | #6 (Groff.dev) | Foundatio `AGENTS.md` Validation, Anthropic `coding_prompt.md` Step 3+6 |
| 문서 동기화 | #9 (Blake Niemyjski) | Exceptionless `AGENTS.md` Continuous Improvement |
| 전체 분량 제한 | #5 (Groff.dev, Agent READMEs) | HumanLayer `CLAUDE.md` (60줄 미만 실물) |

실제 코드 전문은 `08-real-code-references.md` 참조.

---

## 파일 2: Self-Review 스킬

파일: `.claude/skills/self-review/SKILL.md` (Claude Code)
또는: `.cursor/rules/self-review.md` (Cursor)
또는: `docs/agent-guides/self-review.md` (범용)

```markdown
---
name: self-review
description: 작업 완료 전 실행하는 품질 체크리스트. 커밋 또는 PR 전에 반드시 실행.
---

# Self-Review Checklist

작업 완료 선언 전에 아래 항목을 전부 확인한다.

## 기능
- [ ] 변경한 코드가 의도대로 동작하는가?
- [ ] 엣지 케이스를 처리했는가?
- [ ] 에러 상황에서 적절한 메시지/처리가 되는가?

## 테스트
- [ ] 새 코드에 대한 테스트를 작성했는가?
- [ ] 기존 테스트가 모두 통과하는가?
- [ ] (해당 시) 통합 테스트도 확인했는가?

## 보안
- [ ] 사용자 입력을 검증하는가?
- [ ] 시크릿이 코드에 포함되지 않았는가?
- [ ] [프로젝트 고유 보안 항목]

## 성능
- [ ] [프로젝트 고유 성능 항목 — 예: N+1 쿼리, 불필요한 전체 로딩]

## 문서
- [ ] 관련 문서를 업데이트했는가?
- [ ] API 변경 → API 문서, 설정 변경 → README 등

## 규칙 준수
- [ ] Boundaries의 🚫 항목을 위반하지 않았는가?
- [ ] 커밋 메시지가 Conventional Commits 형식인가?

## 모든 항목 통과 시
커밋 → PR 진행.

## 미통과 항목 있을 시
해당 항목 수정 후 다시 체크리스트 실행.
```

### 패턴 매핑

| 섹션 | 패턴 출처 |
|------|-----------|
| 체크리스트 구조 | #6 (Groff.dev — 5개 필수 스킬) |
| 보안/성능 항목 | #12 (Agent READMEs 논문 — 관통 패턴) |
| 문서 항목 | #9 (Blake Niemyjski — Foundatio) |
| 규칙 준수 항목 | #4 (GitHub Blog — Boundaries) |

---

## 워크플로우 (파일이 아닌 운용 규칙)

아래는 파일로 만드는 게 아니라, 개발 과정에서 따르는 워크플로우다.

### 문제 발생 시 — Git Bisect (#7)

```
에이전트에게:
"테스트 [이름]이 실패하고 있어. 언제부터 실패했는지 git bisect로 찾아줘."

전제: Phase 2에서 잘게 커밋했어야 효과적.
```

### 사후 개선 — 실수→규칙 (#3→#4)

```
실수 발생 시:
1. 어떤 실수인지 식별 ("또 N+1 쿼리 만듦", "또 환경변수 하드코딩")
2. 루트 규칙 파일의 🚫 Never 섹션에 추가
3. 해당 항목을 self-review 체크리스트에도 추가

예시:
  🚫 Never 추가: "LLM 호출 함수에서 None 반환 금지 — 실패 시 항상 예외 raise"
  체크리스트 추가: "- [ ] API/LLM 호출의 에러 핸들링이 None 대신 예외를 발생시키는가?"
```

### 월 1회 — 규칙 리뷰 (#3)

```
월간 리뷰:
1. 규칙이 아직 유효한가? → 기술 변경으로 해당 없어진 건 삭제
2. 단순화할 수 있는가? → 비슷한 규칙 합치기
3. 파일 크기가 60~100줄을 넘지 않는가? → 넘으면 스킬로 분리
4. 체크리스트 항목이 너무 많지 않은가? → 핵심만 유지
```

### PR 전 — 히스토리 정리 (#10)

```
에이전트에게:
"이 브랜치의 커밋들을 논리적 단위로 정리해줘."

정리 대상:
- 실험적 커밋들 → squash
- 잘못된 커밋 메시지 → reword
- "fix typo" 연쇄 → 합치기
```

---

## CHANGELOG.md에 대한 참고

이 템플릿에 CHANGELOG.md는 포함하지 않았다.

이유: 12개 검증된 패턴 중 CHANGELOG 자체를 직접 다루는 패턴은 없다.
가장 가까운 것은 #9(Blake — releasenotes 스킬)과 Keep a Changelog 업계 표준인데,
이들은 "변경 기록을 남겨라"는 일반 원칙이지 에이전틱 개발 특화 패턴이 아니다.

프로젝트에서 CHANGELOG를 쓰고 싶다면:
- Keep a Changelog 표준 (https://keepachangelog.com/) 형식 사용
- #9의 문서 동기화 규칙에 CHANGELOG도 포함
- 루트 규칙 파일의 "문서 동기화" 섹션에 "CHANGELOG 업데이트" 추가

이것은 검증된 패턴의 자연스러운 확장이지만,
"CHANGELOG + 교훈 기록"이라는 특정 형식은 소스에서 검증된 것이 아님을 인지해야 한다.
