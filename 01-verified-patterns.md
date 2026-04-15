# 01. 검증된 12개 패턴

> 각 패턴은 출처의 원문을 직접 인용하고, 해당 패턴의 핵심과 적용 방법을 기술한다.
> 내 해석이나 조합 없이 소스에서 확인된 내용만 포함한다.

---

## 패턴 #1: 세션 시작 시 git log로 컨텍스트 주입

### 출처
Simon Willison — "Using Git with coding agents" (Agentic Engineering Patterns)
https://simonwillison.net/guides/agentic-engineering-patterns/using-git-with-coding-agents/

### 원문 인용

> "Telling the agent to look at recent changes causes it to run git log, which can
> instantly load its context with details of what you have been working on recently
> — both the modified code and the commit messages that describe it."

> "Seeding the session in this way means you can start talking about that code —
> suggest additional fixes, ask questions about how it works, or propose the next
> change that builds on what came before."

### 핵심

에이전트는 매 세션 stateless다. 새 세션에서 "최근 변경사항 보여줘"라고 하면
에이전트가 `git log`를 실행하고, 그 결과(코드 변경분 + 커밋 메시지)가
자연스럽게 컨텍스트에 로딩된다. 이전 작업의 연속성이 즉시 확보된다.

### 적용 방법

에이전트에게 주는 첫 지시 또는 규칙 파일에 고정.

**실제 구현 — Anthropic `coding_prompt.md` Step 1:**
```bash
pwd
ls -la
cat app_spec.txt
cat feature_list.json | head -50
cat claude-progress.txt
git log --oneline -20
cat feature_list.json | grep '"passes": false' | wc -l
```
출처: https://github.com/anthropics/claude-quickstarts/blob/main/autonomous-coding/prompts/coding_prompt.md

---

## 패턴 #2: Git Checkpointing — 자동 커밋으로 되돌리기

### 출처
Claude Code 공식 기능
shanraisshan/claude-code-best-practice 레포에 기록 (32K★)
https://github.com/shanraisshan/claude-code-best-practice

### 원문 인용

> "Checkpointing — automatic (git-based): Automatic tracking of file edits with
> rewind (Esc Esc or /rewind) and targeted summarization"

### 핵심

에이전트가 파일을 편집할 때마다 git으로 자동 체크포인트를 생성한다.
문제 발생 시 특정 시점으로 되돌릴 수 있다.
Claude Code는 이걸 내장하고 있고, 다른 도구에서는 에이전트에게
"변경 전 커밋해" 규칙을 명시하면 동일 효과를 낼 수 있다.

### 적용 방법

**실제 구현 — Anthropic `coding_prompt.md` Step 8:**
```bash
git add .
git commit -m "Implement [feature name] - verified end-to-end

- Added [specific changes]
- Tested with browser automation
- Updated feature_list.json: marked test #X as passing
"
```
출처: https://github.com/anthropics/claude-quickstarts/blob/main/autonomous-coding/prompts/coding_prompt.md

Anthropic은 별도 checkpointing 도구가 아니라 user prompt에 "커밋하라"고 지시하는 형태.
Claude Code 내장 checkpointing은 이것과 별도로 자동 동작 (Esc Esc 또는 /rewind).

---

## 패턴 #3: 반복 실수 관찰 → 규칙으로 추가

### 출처
obviousworks/agentic-coding-rulebook
https://github.com/obviousworks/agentic-coding-rulebook/blob/main/best_practices.md

### 원문 인용

> "For 1-2 weeks, observe AI behavior:
> - What mistakes does it make repeatedly?
> - What questions does it ask?
> - What patterns does it miss?
> Add rules to address observed issues."

> "Monthly review checklist:
> - Are rules still relevant?
> - Are there new patterns to document?
> - Can any rules be simplified?
> - Are there redundant rules?
> - Does the file size need optimization?"

### 핵심

프로젝트 시작 시 규칙을 완벽하게 적을 필요 없다. 최소한만 적고,
1~2주 에이전트 행동을 관찰하면서 반복되는 실수를 발견하면 그때 규칙으로 추가한다.
월 1회 규칙을 리뷰해서 불필요한 건 삭제하고 단순화한다.

### 적용 방법

```
초기: 최소 규칙만 작성 (프로젝트 시작 시)
     ↓
1~2주 관찰: 에이전트가 뭘 틀리는가?
     ↓
규칙 추가: 반복 실수를 규칙 파일의 금지 사항에 추가
     ↓
월 1회: 규칙 유효성 리뷰, 불필요한 건 삭제
```

---

## 패턴 #4: "절대 하지 말 것"을 명시적으로 기술

### 출처 1
GitHub Blog — "How to write a great agents.md: Lessons from over 2,500 repositories" (2025-11-19)
https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/

### 원문 인용 1

> "Set clear boundaries: Tell AI what it should never touch (e.g., secrets, vendor
> directories, production configs, or specific folders). 'Never commit secrets'
> was the most common helpful constraint."

### 출처 2
Groff.dev — "Implementing CLAUDE.md and Agent Skills In Your Repository" (2026-02-10)
https://www.groff.dev/blog/implementing-claude-md-agent-skills

### 원문 인용 2

> "Boundaries:
> - ✅ Always do: Write new files to docs/, follow the style examples, run markdownlint
> - ⚠️ Ask first: Before modifying existing documents in a major way
> - 🚫 Never do: Modify code in src/, edit config files, commit secrets"

### 핵심

2,500개 레포 분석에서, 성공적인 에이전트 파일의 공통점은 **"하지 말 것"을
구체적으로 명시**하는 것이었다. 3단계 경계(항상 / 먼저 물어봐 / 절대 금지)가
효과적으로 확인됨.

### 적용 방법

규칙 파일에 금지 사항을 구체적으로 명시.

**실제 구현 — Exceptionless `AGENTS.md` Constraints:**
```markdown
- Use `npm ci` (not `npm install`)
- Never commit secrets — use environment variables
- Prefer additive documentation updates — don't replace strategic docs wholesale
```
출처: https://github.com/exceptionless/Exceptionless/blob/main/AGENTS.md

**실제 구현 — Anthropic `initializer_prompt.md`:**
```
IT IS CATASTROPHIC TO REMOVE OR EDIT FEATURES IN FUTURE SESSIONS.
Features can ONLY be marked as passing.
```
출처: https://github.com/anthropics/claude-quickstarts/blob/main/autonomous-coding/prompts/initializer_prompt.md

**실제 구현 — obviousworks `agent_example.md`:**
```markdown
### Explicitly DO NOT Use
- Redux (use Zustand instead)
- Axios (use native fetch with retry logic)
- Moment.js (use date-fns)
```
출처: https://github.com/obviousworks/agentic-coding-rulebook/blob/main/agent_example.md

---

## 패턴 #5: 규칙 파일은 짧게, 상세 내용은 분리

### 출처 1
Groff.dev — "Implementing CLAUDE.md and Agent Skills In Your Repository" (2026-02-10)
https://www.groff.dev/blog/implementing-claude-md-agent-skills

### 원문 인용 1

> "Target: under 100 lines. HumanLayer keeps theirs under 60. Anthropic recommends
> under 300 but less is better. In my experience, 60 to 100 lines is the sweet spot
> for a real production repo."

> "The key principle is progressive disclosure. The root file is a table of contents.
> Skills are chapters. Agent guides are appendices. The agent loads only what the
> current task requires."

### 출처 2
Agent READMEs 논문 (arxiv 2511.12884) + 별도 실증 연구 (arxiv 2602.11988)

### 원문 인용 2 (Groff.dev가 인용)

> "The [arxiv study on evaluating AGENTS.md](https://arxiv.org/abs/2602.11988) found
> exactly this: unnecessary requirements made tasks harder for agents, not easier."

### 핵심

루트 규칙 파일은 60~100줄. 상세 내용(아키텍처, 컨벤션, 패턴 예시)은
별도 스킬 파일이나 가이드 문서로 분리해서 필요할 때만 로딩한다.
**많이 넣을수록 좋은 게 아니다** — 불필요한 규칙이 오히려 에이전트 성능을 저하시킨다.

### 적용 방법

3-Tier 구조 (Groff.dev 원안):

```
Tier 1: 루트 규칙 파일 (60~100줄, 매 세션 자동 로딩)
Tier 2: 스킬 파일 (작업별, on-demand 로딩)
Tier 3: 상세 가이드 (스킬이 참조, 필요할 때만 로딩)
```

**실제 구현 — HumanLayer `CLAUDE.md`:**
60줄 미만의 실물. 레포 개요 + 컴포넌트 + 명령어 + 컨벤션만.
스킬, MCP, 상세 가이드 없이 루트 파일만으로 운영.
출처: https://github.com/humanlayer/humanlayer/blob/main/CLAUDE.md

**실제 구현 — Exceptionless `AGENTS.md`:**
~120줄. 스킬 22개를 별도 `.agents/skills/`에 분리하고, AGENTS.md에서는 테이블로 참조만.
출처: https://github.com/exceptionless/Exceptionless/blob/main/AGENTS.md

---

## 패턴 #6: Self-Review Checklist

### 출처 1
Groff.dev — 5개 필수 스킬

### 원문 인용 1

> "self-review-checklist — Quality gate the agent runs before finishing work.
> Catches convention drift and missing tests."

### 출처 2
obviousworks/agentic-coding-rulebook

### 원문 인용 2

> "Before we proceed, please review the code you just generated:
> 1. Security: Are all inputs validated? Any injection risks?
> 2. Performance: Any O(n²) operations? Unnecessary re-renders?
> 3. Error Handling: What happens if [edge case]?
> 4. Testing: What test cases should cover this?
> 5. Compliance: Does it follow our AGENTS.md rules?"

### 핵심

작업 완료 전에 에이전트가 스스로 실행하는 품질 게이트.
보안·성능·에러 핸들링·테스트·규칙 준수 여부를 체크한 후에만 완료 선언.
Groff.dev는 이것을 5개 필수 스킬 중 하나로 권장.

### 적용 방법

실제 레포들은 이것을 다양한 형태로 구현한다:

**실제 구현 — Anthropic `coding_prompt.md` Step 3 (회귀 테스트):**
```markdown
**MANDATORY BEFORE NEW WORK:**
The previous session may have introduced bugs. Before implementing anything
new, you MUST run verification tests.

**If you find ANY issues:**
- Mark that feature as "passes": false immediately
- Fix all issues BEFORE moving to new features
```
출처: https://github.com/anthropics/claude-quickstarts/blob/main/autonomous-coding/prompts/coding_prompt.md

**실제 구현 — Foundatio `AGENTS.md` Validation 섹션:**
```markdown
Before marking work complete, verify:
1. Builds successfully: `dotnet build Foundatio.slnx` exits with code 0
2. All tests pass: `dotnet test Foundatio.slnx` shows no failures
3. No new warnings
4. API compatibility: backward-compatible
5. Documentation updated: XML doc comments
6. Skill updated: when changing core abstractions
```
출처: https://github.com/FoundatioFx/Foundatio/blob/main/AGENTS.md

**실제 구현 — Exceptionless — 별도 `@reviewer` 에이전트:**
```
engineer → TDD → implement → verify (loop until clean)
         → @reviewer (loop until 0 blockers) → commit
```
출처: https://github.com/exceptionless/Exceptionless/blob/main/AGENTS.md

---

## 패턴 #7: Git Bisect로 회귀 원인 자동 탐색

### 출처
Simon Willison — "Using Git with coding agents" (Agentic Engineering Patterns)
https://simonwillison.net/guides/agentic-engineering-patterns/using-git-with-coding-agents/

### 원문 인용

> "When you run a bisect operation you provide Git with some kind of test condition
> and a start and ending commit range. Git then runs a binary search to identify
> the earliest commit for which your test condition fails."

> "Coding agents can handle this boilerplate for you. This upgrades Git bisect from
> an occasional use tool to one you can deploy any time you are curious about the
> historic behavior of your software."

### 핵심

bisect는 원래 진입 장벽이 높아서 개발자들이 잘 안 쓰는 도구인데,
에이전트가 boilerplate를 처리해주니까 일상적으로 쓸 수 있게 된다.
"이 테스트가 언제부터 실패했는지 찾아줘" 한 마디면 에이전트가 자동으로 이분 탐색 실행.

### 적용 방법

규칙 파일에 넣기보다는, 문제 상황에서 에이전트에게 직접 지시:

```
"테스트 X가 실패하고 있어. 언제부터 실패했는지 git bisect로 찾아줘."
```

전제 조건: 패턴 #2(Checkpointing)에 의해 커밋이 충분히 쌓여 있어야 정밀하게 동작.

---

## 패턴 #8: Conventional Commits로 구조화된 커밋 메시지

### 출처
GitHub Blog, Groff.dev (git-commit 스킬), obviousworks rulebook — 공통

### 원문 인용 (Groff.dev)

> "git-commit — Your commit message format, branch naming, what to check before
> committing. Prevents the agent from writing vague commit messages."

### 핵심

커밋 메시지가 `feat(auth): add JWT validation`이면 git log만 봐도 뭘 했는지 즉시 파악.
`update code`면 diff까지 봐야 하니까 컨텍스트 낭비.
에이전트에게 메시지 형식을 규칙으로 주면 vague한 메시지 방지.

### 적용 방법

**실제 구현 — Anthropic `coding_prompt.md` Step 8:**
```bash
git commit -m "Implement [feature name] - verified end-to-end

- Added [specific changes]
- Tested with browser automation
- Updated feature_list.json: marked test #X as passing
"
```
출처: https://github.com/anthropics/claude-quickstarts/blob/main/autonomous-coding/prompts/coding_prompt.md

**실제 구현 — obviousworks `agent_template.md` Git Workflow:**
```markdown
### Commit Messages
Format: `type(scope): description`

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Examples**:
- `feat(auth): add password reset functionality`
- `fix(api): handle null response from external service`
- `docs(readme): update setup instructions`
```
출처: https://github.com/obviousworks/agentic-coding-rulebook/blob/main/agent_template.md

---

## 패턴 #9: 코드 변경 시 문서 자동 업데이트

### 출처
Blake Niemyjski — "Agentic Driven Development (ADD)" (blakeniemyjski.com)
https://blakeniemyjski.com/blog/agentic-driven-development/

### 원문 인용

> "We also use the AGENTS.md to keep the documentation up to date. When the agent
> makes changes to Foundatio, the instructions tell it to update the relevant docs
> as part of the same task. This means the README and API docs stay in sync with
> the code without us having to remember to do it manually."

### 핵심

규칙에 "코드 변경 시 관련 문서도 같이 업데이트"를 명시하면,
별도 요청 없이 코드와 문서가 동기화된다.
Blake의 Exceptionless 프로젝트에서는 22개 스킬 중 하나로 `releasenotes` 스킬을 실제 운용.

### 적용 방법

AGENTS.md에 텍스트 규칙으로 명시.

**실제 구현 — Exceptionless `AGENTS.md`:**
```markdown
Each time you complete a task or learn important information about the project,
you must update the `AGENTS.md`, `README.md`, or relevant skill files.
**Only update skills if they are owned by us** (verify via `skills-lock.json`).
```
출처: https://github.com/exceptionless/Exceptionless/blob/main/AGENTS.md

**실제 구현 — Foundatio `AGENTS.md` Validation 항목:**
```markdown
5. Documentation updated: XML doc comments added/updated for public APIs
6. Interface documentation: Update interface definitions and docs with any API changes
7. Feature documentation: Add entries to docs/ folder for new features
8. Skill updated: When changing core abstractions, update .agents/skills/
```
출처: https://github.com/FoundatioFx/Foundatio/blob/main/AGENTS.md

**실제 구현 — Anthropic `coding_prompt.md` Step 9:**
```markdown
Update `claude-progress.txt` with:
- What you accomplished this session
- Which test(s) you completed
- Any issues discovered or fixed
- What should be worked on next
- Current completion status (e.g., "45/200 tests passing")
```
출처: https://github.com/anthropics/claude-quickstarts/blob/main/autonomous-coding/prompts/coding_prompt.md

---

## 패턴 #10: Git 히스토리를 의도적으로 편집

### 출처
Simon Willison — "Using Git with coding agents" (Agentic Engineering Patterns)
https://simonwillison.net/guides/agentic-engineering-patterns/using-git-with-coding-agents/

### 원문 인용

> "Don't think of the Git history as a permanent record of what actually happened
> — instead consider it to be a deliberately authored story that describes the
> progression of the software project."

> "This story is a tool to aid future development."

### 핵심

Git 히스토리는 "실제로 일어난 일의 영구 기록"이 아니라
"프로젝트의 진행을 서술하는 의도적으로 편집된 이야기"로 봐야 한다.
에이전트에게 커밋 합치기·메시지 수정을 시켜서 히스토리를 읽기 좋게 관리하면,
다음 세션에서 git log로 시딩할 때(#1) 노이즈가 줄어든다.

### 적용 방법

PR 머지 전 또는 마일스톤 후:

```
- 실험적 커밋들을 squash
- 잘못된 커밋 메시지 수정
- 의미 없는 "fix typo" 연쇄 커밋 합치기

"이 브랜치의 커밋들을 논리적 단위로 정리해줘"
```

---

## 패턴 #11: 구체적 기술 스택·명령어 명시

### 출처
GitHub Blog — "How to write a great agents.md: Lessons from over 2,500 repositories" (2025-11-19)
https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/

### 원문 인용

> "Be specific about your stack: Say 'React 18 with TypeScript, Vite, and Tailwind CSS'
> not 'React project.' Include versions and key dependencies."

> "Put commands early: Put relevant executable commands in an early section:
> npm test, npm run build, pytest -v. Include flags and options, not just tool names."

### 핵심

"Python 프로젝트"가 아니라 "Python 3.12 + FastAPI + uv + pytest".
빌드·테스트 명령은 플래그까지 포함해서 규칙 파일 상단에 배치.
도구 이름만 쓰지 말고 실제 실행 명령 전체를 적는다.

### 적용 방법

**실제 구현 — Exceptionless `AGENTS.md`:**
```markdown
## Quick Start

Run `Exceptionless.AppHost` from your IDE.

## Build & Test

| Task           | Command                                                         |
| -------------- | --------------------------------------------------------------- |
| Backend build  | `dotnet build`                                                  |
| Backend test   | `dotnet test`                                                   |
| Frontend build | `cd src/Exceptionless.Web/ClientApp && npm ci && npm run build` |
| E2E test       | `npm run test:e2e`                                              |
```
출처: https://github.com/exceptionless/Exceptionless/blob/main/AGENTS.md

**실제 구현 — obviousworks `agent_example.md`:**
```markdown
## Tech Stack

### Core Technologies
- **Language**: TypeScript 5.3+ (strict mode), Python 3.12+
- **Framework**: Next.js 14.2 (App Router), FastAPI 0.110+
- **Database**: PostgreSQL 16 with Prisma ORM 5.x
- **Cache**: Redis 7.2+
- **Package Manager**: pnpm 9.x

### File-Scoped Commands (Preferred - Fast)
# Type check single file (2-3 seconds)
pnpm tsc --noEmit apps/web/app/dashboard/page.tsx

# Lint single file
pnpm eslint apps/web/lib/utils.ts
```
출처: https://github.com/obviousworks/agentic-coding-rulebook/blob/main/agent_example.md

---

## 패턴 #12: 보안·성능 가드레일이 부족한 현실

### 출처
Agent READMEs 논문 (arxiv 2511.12884) — 2,303개 파일 분석

### 원문 인용

> "developers prioritize functional context, such as build and run commands (62.3%),
> implementation details (69.9%), and architecture (67.7%). We also identify a
> significant gap: non-functional requirements like security (14.5%) and
> performance (14.5%) are rarely specified."

> "These findings indicate that while developers use context files to make agents
> functional, they provide few guardrails to ensure that agent-written code is
> secure or performant, highlighting the need for improved tooling and practices."

### 핵심

2,303개 컨텍스트 파일 분석 결과, 대부분의 프로젝트가 기능적 컨텍스트는 잘 적지만
보안(14.5%)과 성능(14.5%)은 거의 안 적는다.
에이전트가 기능적으로는 작동하는 코드를 만들지만, 보안 취약점이나 성능 문제가 있는 코드를
만들 수 있다. 의식적으로 보안·성능 섹션을 규칙 파일에 포함해야 한다.

### 적용 방법

**실제 구현 — obviousworks `agent_template.md` Security:**
```markdown
### Secrets Management
- **NEVER** commit secrets, API keys, or credentials
- Use environment variables for sensitive data
- Reference: `.env.example` for required variables

### Security Requirements
- All database queries must use parameterization
- HTTPS enforced in production
- CORS properly configured
```
출처: https://github.com/obviousworks/agentic-coding-rulebook/blob/main/agent_template.md

**실제 구현 — Foundatio `AGENTS.md` Performance:**
```markdown
### Performance Considerations
- Avoid allocations in hot paths: Use Span<T>, Memory<T>, pooled buffers
- Prefer structs for small, immutable types
- Cache expensive computations: Use Lazy<T>
- Batch operations when possible: Reduce round trips for I/O
- Profile before optimizing: Don't guess—measure with benchmarks
- Consider concurrent access: Use ConcurrentDictionary, Interlocked
```
출처: https://github.com/FoundatioFx/Foundatio/blob/main/AGENTS.md
