# 08. 실제 코드 레퍼런스 — 프로덕션에서 쓰이는 실물

> 블로그/논문이 아닌, 실제 GitHub 레포에서 가져온 코드와 파일.
> 각 소스가 하네스/규칙/스킬을 **어떤 형태**로 구현했는지 원본 그대로 수록.

---

## 1. Anthropic — claude-quickstarts/autonomous-coding

**레포**: https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding
**용도**: 장시간 자율 코딩 하네스 레퍼런스 구현

### 1-1. 시스템 프롬프트 — 1줄 (`client.py`)

```python
return ClaudeSDKClient(
    options=ClaudeCodeOptions(
        system_prompt="You are an expert full-stack developer building a production-quality web application.",
        ...
    )
)
```

### 1-2. MCP 서버 — Puppeteer 1개만 (`client.py`)

```python
return ClaudeSDKClient(
    options=ClaudeCodeOptions(
        allowed_tools=[
            "Read", "Write", "Edit", "Glob", "Grep", "Bash",
            "mcp__puppeteer__puppeteer_navigate",
            "mcp__puppeteer__puppeteer_screenshot",
            "mcp__puppeteer__puppeteer_click",
            "mcp__puppeteer__puppeteer_fill",
            "mcp__puppeteer__puppeteer_select",
            "mcp__puppeteer__puppeteer_hover",
            "mcp__puppeteer__puppeteer_evaluate",
        ],
        mcp_servers={
            "puppeteer": {"command": "npx", "args": ["puppeteer-mcp-server"]}
        },
    )
)
```

### 1-3. 보안 훅 — bash allowlist (`security.py` + `client.py`)

```python
# security.py
ALLOWED_COMMANDS = {
    "ls", "cat", "head", "tail", "wc", "grep",
    "cp", "mkdir", "chmod",
    "pwd",
    "npm", "node",
    "git",
    "ps", "lsof", "sleep", "pkill",
    "init.sh",
}
```

```python
# client.py — 훅 등록
from security import bash_security_hook

hooks={
    "PreToolUse": [
        HookMatcher(matcher="Bash", hooks=[bash_security_hook]),
    ],
},
```

### 1-4. 세션 루프 (`agent.py`)

```python
tests_file = project_dir / "feature_list.json"
is_first_run = not tests_file.exists()

while True:
    client = create_client(project_dir, model)

    if is_first_run:
        prompt = get_initializer_prompt()
        is_first_run = False
    else:
        prompt = get_coding_prompt()

    async with client:
        status, response = await run_agent_session(client, prompt, project_dir)

    await asyncio.sleep(AUTO_CONTINUE_DELAY_SECONDS)  # 3초
```

### 1-5. Initializer Prompt (`prompts/initializer_prompt.md`) — 전문

```markdown
## YOUR ROLE - INITIALIZER AGENT (Session 1 of Many)

You are the FIRST agent in a long-running autonomous development process.
Your job is to set up the foundation for all future coding agents.

### FIRST: Read the Project Specification

Start by reading `app_spec.txt` in your working directory. This file contains
the complete specification for what you need to build. Read it carefully
before proceeding.

### CRITICAL FIRST TASK: Create feature_list.json

Based on `app_spec.txt`, create a file called `feature_list.json` with 200 detailed
end-to-end test cases. This file is the single source of truth for what
needs to be built.

**Format:**
[
  {
    "category": "functional",
    "description": "Brief description of the feature and what this test verifies",
    "steps": [
      "Step 1: Navigate to relevant page",
      "Step 2: Perform action",
      "Step 3: Verify expected result"
    ],
    "passes": false
  },
  {
    "category": "style",
    "description": "Brief description of UI/UX requirement",
    "steps": [
      "Step 1: Navigate to page",
      "Step 2: Take screenshot",
      "Step 3: Verify visual requirements"
    ],
    "passes": false
  }
]

**Requirements for feature_list.json:**
- Minimum 200 features total with testing steps for each
- Both "functional" and "style" categories
- Mix of narrow tests (2-5 steps) and comprehensive tests (10+ steps)
- At least 25 tests MUST have 10+ steps each
- Order features by priority: fundamental features first
- ALL tests start with "passes": false
- Cover every feature in the spec exhaustively

**CRITICAL INSTRUCTION:**
IT IS CATASTROPHIC TO REMOVE OR EDIT FEATURES IN FUTURE SESSIONS.
Features can ONLY be marked as passing (change "passes": false to "passes": true).
Never remove features, never edit descriptions, never modify testing steps.
This ensures no functionality is missed.

### SECOND TASK: Create init.sh

Create a script called `init.sh` that future agents can use to quickly
set up and run the development environment. The script should:

1. Install any required dependencies
2. Start any necessary servers or services
3. Print helpful information about how to access the running application

Base the script on the technology stack specified in `app_spec.txt`.

### THIRD TASK: Initialize Git

Create a git repository and make your first commit with:
- feature_list.json (complete with all 200+ features)
- init.sh (environment setup script)
- README.md (project overview and setup instructions)

Commit message: "Initial setup: feature_list.json, init.sh, and project structure"

### FOURTH TASK: Create Project Structure

Set up the basic project structure based on what's specified in `app_spec.txt`.

### OPTIONAL: Start Implementation

If you have time remaining in this session, you may begin implementing
the highest-priority features from feature_list.json. Remember:
- Work on ONE feature at a time
- Test thoroughly before marking "passes": true
- Commit your progress before session ends

### ENDING THIS SESSION

Before your context fills up:
1. Commit all work with descriptive messages
2. Create `claude-progress.txt` with a summary of what you accomplished
3. Ensure feature_list.json is complete and saved
4. Leave the environment in a clean, working state

The next agent will continue from here with a fresh context window.

---

**Remember:** You have unlimited time across many sessions. Focus on
quality over speed. Production-ready is the goal.
```

### 1-6. Coding Prompt (`prompts/coding_prompt.md`) — 전문

```markdown
## YOUR ROLE - CODING AGENT

You are continuing work on a long-running autonomous development task.
This is a FRESH context window - you have no memory of previous sessions.

### STEP 1: GET YOUR BEARINGS (MANDATORY)

Start by orienting yourself:

```bash
# 1. See your working directory
pwd

# 2. List files to understand project structure
ls -la

# 3. Read the project specification to understand what you're building
cat app_spec.txt

# 4. Read the feature list to see all work
cat feature_list.json | head -50

# 5. Read progress notes from previous sessions
cat claude-progress.txt

# 6. Check recent git history
git log --oneline -20

# 7. Count remaining tests
cat feature_list.json | grep '"passes": false' | wc -l
```

Understanding the `app_spec.txt` is critical - it contains the full requirements
for the application you're building.

### STEP 2: START SERVERS (IF NOT RUNNING)

If `init.sh` exists, run it:
```bash
chmod +x init.sh
./init.sh
```

Otherwise, start servers manually and document the process.

### STEP 3: VERIFICATION TEST (CRITICAL!)

**MANDATORY BEFORE NEW WORK:**

The previous session may have introduced bugs. Before implementing anything
new, you MUST run verification tests.

Run 1-2 of the feature tests marked as `"passes": true` that are most core to
the app's functionality to verify they still work.

**If you find ANY issues (functional or visual):**
- Mark that feature as "passes": false immediately
- Add issues to a list
- Fix all issues BEFORE moving to new features
- This includes UI bugs like:
  * White-on-white text or poor contrast
  * Random characters displayed
  * Incorrect timestamps
  * Layout issues or overflow
  * Buttons too close together
  * Missing hover states
  * Console errors

### STEP 4: CHOOSE ONE FEATURE TO IMPLEMENT

Look at feature_list.json and find the highest-priority feature with "passes": false.

Focus on completing one feature perfectly and completing its testing steps in this
session before moving on to other features.
It's ok if you only complete one feature in this session, as there will be more
sessions later that continue to make progress.

### STEP 5: IMPLEMENT THE FEATURE

Implement the chosen feature thoroughly:
1. Write the code (frontend and/or backend as needed)
2. Test manually using browser automation (see Step 6)
3. Fix any issues discovered
4. Verify the feature works end-to-end

### STEP 6: VERIFY WITH BROWSER AUTOMATION

**CRITICAL:** You MUST verify features through the actual UI.

Use browser automation tools:
- Navigate to the app in a real browser
- Interact like a human user (click, type, scroll)
- Take screenshots at each step
- Verify both functionality AND visual appearance

**DO:**
- Test through the UI with clicks and keyboard input
- Take screenshots to verify visual appearance
- Check for console errors in browser
- Verify complete user workflows end-to-end

**DON'T:**
- Only test with curl commands (backend testing alone is insufficient)
- Use JavaScript evaluation to bypass UI (no shortcuts)
- Skip visual verification
- Mark tests passing without thorough verification

### STEP 7: UPDATE feature_list.json (CAREFULLY!)

**YOU CAN ONLY MODIFY ONE FIELD: "passes"**

After thorough verification, change:
"passes": false → "passes": true

**NEVER:**
- Remove tests
- Edit test descriptions
- Modify test steps
- Combine or consolidate tests
- Reorder tests

**ONLY CHANGE "passes" FIELD AFTER VERIFICATION WITH SCREENSHOTS.**

### STEP 8: COMMIT YOUR PROGRESS

Make a descriptive git commit:
```bash
git add .
git commit -m "Implement [feature name] - verified end-to-end

- Added [specific changes]
- Tested with browser automation
- Updated feature_list.json: marked test #X as passing
- Screenshots in verification/ directory
"
```

### STEP 9: UPDATE PROGRESS NOTES

Update `claude-progress.txt` with:
- What you accomplished this session
- Which test(s) you completed
- Any issues discovered or fixed
- What should be worked on next
- Current completion status (e.g., "45/200 tests passing")

### STEP 10: END SESSION CLEANLY

Before context fills up:
1. Commit all working code
2. Update claude-progress.txt
3. Update feature_list.json if tests verified
4. Ensure no uncommitted changes
5. Leave app in working state (no broken features)

---

## TESTING REQUIREMENTS

**ALL testing must use browser automation tools.**

Available tools:
- puppeteer_navigate - Start browser and go to URL
- puppeteer_screenshot - Capture screenshot
- puppeteer_click - Click elements
- puppeteer_fill - Fill form inputs
- puppeteer_evaluate - Execute JavaScript (use sparingly, only for debugging)

Test like a human user with mouse and keyboard. Don't take shortcuts.

---

## IMPORTANT REMINDERS

**Your Goal:** Production-quality application with all 200+ tests passing

**This Session's Goal:** Complete at least one feature perfectly

**Priority:** Fix broken tests before implementing new features

**Quality Bar:**
- Zero console errors
- Polished UI matching the design specified in app_spec.txt
- All features work end-to-end through the UI
- Fast, responsive, professional

**You have unlimited time.** Take as long as needed to get it right.

---

Begin by running Step 1 (Get Your Bearings).
```

---

## 2. Exceptionless — Blake Niemyjski

**레포**: https://github.com/exceptionless/Exceptionless
**용도**: 실시간 에러 모니터링 플랫폼 (ASP.NET Core 10 + Svelte 5), 22개 스킬로 운영

### 2-1. AGENTS.md (실물, 발췌)

```markdown
# Exceptionless

Real-time error monitoring platform handling billions of requests (ASP.NET Core 10 + Svelte 5).
Act as a distinguished engineer focusing on readability, performance while maintaining
backwards compatibility.

## Quick Start

Run `Exceptionless.AppHost` from your IDE. Aspire starts all services automatically.

## Build & Test

| Task           | Command                                                         |
| -------------- | --------------------------------------------------------------- |
| Backend build  | `dotnet build`                                                  |
| Backend test   | `dotnet test`                                                   |
| Frontend build | `cd src/Exceptionless.Web/ClientApp && npm ci && npm run build` |
| Frontend test  | `npm run test:unit`                                             |
| E2E test       | `npm run test:e2e`                                              |

## Continuous Improvement

Each time you complete a task or learn important information about the project,
you must update the `AGENTS.md`, `README.md`, or relevant skill files.
**Only update skills if they are owned by us** (verify via `skills-lock.json`).

If you encounter recurring questions or patterns during planning, document them:
- Project-specific knowledge → `AGENTS.md` or relevant skill file
- Reusable domain patterns → Create/update appropriate skill in `.agents/skills/`

## Skills

Load from `.agents/skills/<name>/SKILL.md` when working in that domain:

| Domain        | Skills                                                                    |
| ------------- | ------------------------------------------------------------------------- |
| Backend       | dotnet-conventions, backend-architecture, dotnet-cli, backend-testing     |
| Frontend      | svelte-components, tanstack-form, shadcn-svelte, typescript-conventions   |
| Testing       | frontend-testing, e2e-testing                                             |
| Cross-cutting | security-principles, releasenotes                                         |
| Billing       | stripe-best-practices, upgrade-stripe                                     |
| Agents        | agent-browser, dogfood                                                    |

## Agents

Available in `.claude/agents/`. Use `@agent-name` to invoke:

- `engineer`: implementing features, fixing bugs — plans, TDD, implements, verify loop, ships
- `reviewer`: reviewing code quality — adversarial 4-pass analysis. Read-only.
- `triage`: analyzing issues, investigating bugs — impact assessment, RCA, reproduction
- `pr-reviewer`: end-to-end PR review — security pre-screen, dependency audit, verdict

### Orchestration Flow

engineer → TDD → implement → verify (loop until clean)
         → @reviewer (loop until 0 blockers) → commit → push → PR
         → @copilot review → CI checks → resolve feedback → merge

## Constraints

- Use `npm ci` (not `npm install`)
- Never commit secrets — use environment variables
- Prefer additive documentation updates — don't replace strategic docs wholesale
```

출처: https://github.com/exceptionless/Exceptionless/blob/main/AGENTS.md

### 2-2. releasenotes 스킬 (실물, 전문)

```yaml
---
name: releasenotes
description: Generate formatted changelogs from git history since the last release tag.
  Use when preparing release notes that categorize changes into breaking changes,
  features, fixes, and other sections.
triggers:
- /releasenotes
---

Generate a changelog for all changes from the most recent release until now.

## Steps
1. Find the most recent release tag using `git tag --sort=-creatordate`
2. Get commits and merged PRs since that tag
3. Look at previous releases in this repo to match their format and style
4. Categorize changes into sections: Breaking Changes, Added, Changed, Fixed, Notes
5. Focus on user-facing changes (features, important bug fixes, breaking changes)
6. Include PR links and contributor attribution

## Output
Present the changelog in a markdown code block, ready to copy-paste into a GitHub release.
```

출처: https://github.com/exceptionless/Exceptionless/blob/main/.agents/skills/releasenotes/SKILL.md

**주목할 점:**
- `triggers: [/releasenotes]` — 사용자가 `/releasenotes` 커맨드를 치면 발동
- git history에서 자동으로 changelog을 생성하는 구조
- Keep a Changelog 표준(Added, Changed, Fixed)과 일치

---

## 3. Foundatio — Blake Niemyjski

**레포**: https://github.com/FoundatioFx/Foundatio
**용도**: .NET 분산 애플리케이션 빌딩 블록 라이브러리

### 3-1. AGENTS.md (실물, 발췌 — 핵심 부분만)

```markdown
# Agent Guidelines for Foundatio

You are an expert .NET engineer working on Foundatio, a production-grade library
used by thousands of developers. Your changes must maintain backward compatibility,
performance, and reliability.

**Craftsmanship Mindset**: Every line of code should be intentional, readable, and
maintainable. Write code you'd be proud to have reviewed by senior engineers.
Prefer simplicity over cleverness.

## Quick Start

```bash
dotnet build Foundatio.slnx
dotnet test Foundatio.slnx
dotnet format Foundatio.slnx
```

## Making Changes

### Before Starting

1. **Gather context**: Read related files, search for similar implementations
2. **Research patterns**: Find existing usages using grep/semantic search
3. **Understand completely**: Know the problem, side effects, and edge cases
4. **Plan the approach**: Choose the simplest solution
5. **Check dependencies**: Verify how changes affect dependent code

### Pre-Implementation Analysis

Before writing any implementation code, think critically:

1. **What could go wrong?** Race conditions, null references, edge cases
2. **What are the failure modes?** Network failures, timeouts, concurrent access
3. **What assumptions am I making?** Validate each against the codebase
4. **Is this the root cause?** Don't fix symptoms—trace to the core problem
5. **Will this scale?** Consider performance under load
6. **Is there existing code that does this?** Search before creating new utilities

### Test-First Development

**Always write or extend tests before implementing changes:**

1. **Find existing tests first**: Search for tests covering the code you're modifying
2. **Extend existing tests**: Add test cases to existing test classes when possible
3. **Write failing tests**: Create tests that demonstrate the bug or missing feature
4. **Implement the fix**: Write minimal code to make tests pass
5. **Refactor**: Clean up while keeping tests green

### Validation

Before marking work complete, verify:

1. **Builds successfully**: `dotnet build Foundatio.slnx` exits with code 0
2. **All tests pass**: `dotnet test Foundatio.slnx` shows no failures
3. **No new warnings**: Check build output
4. **API compatibility**: Public API changes are intentional and backward-compatible
5. **Documentation updated**: XML doc comments added/updated
6. **Skill updated**: When changing core abstractions, update `.agents/skills/`
```

출처: https://github.com/FoundatioFx/Foundatio/blob/main/AGENTS.md

**주목할 점:**
- "Craftsmanship Mindset" 프리앰블 — Blake가 블로그에서 강조한 "톤 설정이 중요하다"의 실제 구현
- "Pre-Implementation Analysis" 6개 질문 — self-review가 아니라 **구현 전** 분석
- "Test-First Development" — TDD를 규칙으로 명시
- Validation 체크리스트 — 이것이 실제 self-review의 구현 형태

---

## 4. HumanLayer

**레포**: https://github.com/humanlayer/humanlayer
**용도**: AI 코딩 에이전트의 human-in-the-loop 플랫폼

### 4-1. CLAUDE.md (실물, 전문)

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Repository Overview

This is a monorepo containing two distinct but interconnected project groups:

**Project 1: HumanLayer SDK & Platform** - Human-in-the-loop capabilities for AI agents
**Project 2: Local Tools Suite** - Tools that leverage HumanLayer SDK

## Project 1: HumanLayer SDK & Platform

### Components
- `humanlayer-ts/` - TypeScript SDK for Node.js and browser environments
- `humanlayer-go/` - Minimal Go client for building tools
- `humanlayer-ts-vercel-ai-sdk/` - Specialized integration for Vercel AI SDK
- `docs/` - Mintlify documentation site

### Core Concepts
- **Contact Channels**: Slack, Email, CLI, and web interfaces for human interaction
- **Multi-language Support**: Feature parity across TypeScript and Go SDKs

## Project 2: Local Tools Suite

### Components
- `hld/` - Go daemon that coordinates approvals and manages Claude Code sessions
- `hlyr/` - TypeScript CLI with MCP server for Claude integration
- `humanlayer-wui/` - Desktop/Web UI (Tauri + React) for graphical approval management
- `claudecode-go/` - Go SDK for programmatically launching Claude Code sessions

### Architecture Flow
Claude Code → MCP Protocol → hlyr → JSON-RPC → hld → HumanLayer Cloud API
                                         ↑         ↑
                                    TUI ─┘         └─ WUI

## Development Commands

### Quick Actions
- `make setup` - Resolve dependencies and installation issues
- `make check-test` - Run all checks and tests
- `make check` - Run linting and type checking
- `make test` - Run all test suites

### GitHub Workflows
- **Trigger macOS nightly build**: `gh workflow run "Build macOS Release Artifacts"`

### TypeScript Development
- Package managers vary - check `package.json` for npm or bun
- Build/test commands differ - check `package.json` scripts section
- Some use Jest, others Vitest, check `package.json` devDependencies

### Go Development
- Check `go.mod` for Go version (varies between 1.21 and 1.24)
- Check if directory has a `Makefile` for available commands

## Technical Guidelines

### TypeScript
- Modern ES6+ features
- Strict TypeScript configuration
- Maintain CommonJS/ESM compatibility

### Go
- Standard Go idioms
- Context-first API design

## Development Conventions

### TODO Annotations
- `TODO(0)`: Critical - never merge
- `TODO(1)`: High - architectural flaws, major bugs
- `TODO(2)`: Medium - minor bugs, missing features
- `TODO(3)`: Low - polish, tests, documentation
- `TODO(4)`: Questions/investigations needed
- `PERF`: Performance optimization opportunities

## Additional Resources
- Consult `docs/` for user-facing documentation
```

출처: https://github.com/humanlayer/humanlayer/blob/main/CLAUDE.md

**주목할 점:**
- **60줄 미만** — 블로그에서 말한 "Our CLAUDE.md is under 60 lines" 그대로
- MCP나 스킬 언급 없음 — 순수 규칙 파일만
- TODO 우선순위 시스템 — 에이전트가 "TODO(0)는 절대 머지 안 된다"를 알게 됨
- 아키텍처 다이어그램을 텍스트로 포함 (ASCII)

---

## 5. obviousworks/agentic-coding-rulebook

**레포**: https://github.com/obviousworks/agentic-coding-rulebook
**용도**: 에이전틱 코딩 규칙/템플릿 모음

### 5-1. agent_template.md — AGENTS.md 템플릿 (발췌, 핵심 구조)

```markdown
# [Project Name]

## Project Overview
[Brief description]
**Architecture**: [e.g., Microservices, Monolith]
**Domain**: [e.g., E-commerce, Healthcare]

## Tech Stack

### Core Technologies
- **Language**: [Python 3.11+, TypeScript 5.x, etc.]
- **Framework**: [FastAPI, Next.js, etc.]
- **Database**: [PostgreSQL 15, MongoDB 6, etc.]
- **Package Manager**: [npm, pnpm, pip, poetry, etc.]

## Build and Development Commands

### File-Scoped Commands (Preferred - Fast)
```bash
# Type check single file (3 seconds)
[command] path/to/file.ext

# Lint single file (1 second)
[command] path/to/file.ext

# Run single test file (2 seconds)
[command] path/to/test.ext
```

### Project-Wide Commands (Use Sparingly)
```bash
# Full build (5 minutes) - ASK BEFORE RUNNING
[command]

# Full test suite (4 minutes) - ASK BEFORE RUNNING
[command]
```

## Security Considerations

### Secrets Management
- **NEVER** commit secrets, API keys, or credentials
- Use environment variables for sensitive data
- Reference: `.env.example` for required variables

## Git Workflow and PR Process

### Commit Messages
Format: `type(scope): description`
Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Pull Request Requirements

**Before Creating PR**:
- [ ] Run `[lint command]` - all checks pass
- [ ] Run `[type check command]` - no errors
- [ ] Run `[test command]` - all tests pass
- [ ] Update relevant documentation
- [ ] Remove debug logs and commented code

## Safety and Permissions

### Operations Allowed Without Prompting
- Read files, list directory contents
- Type check, lint, format single files
- Run single unit test
- Search codebase, read documentation
- Create git branches and commits

### Operations That Require Approval
- Deleting files or directories
- Modifying CI/CD pipeline configuration
- Changing database schemas
- Running project-wide commands
- Pushing to main/master branch
```

출처: https://github.com/obviousworks/agentic-coding-rulebook/blob/main/agent_template.md

### 5-2. agent_example.md — 구체적 예시 "FocusFlow" (발췌)

```markdown
# FocusFlow - AI-Powered Productivity Platform

**Architecture**: Microservices with event-driven architecture
**Domain**: Productivity SaaS / Team Collaboration
**Scale**: Series A startup targeting 10K+ MAU

## Tech Stack

### Core Technologies
- **Language**: TypeScript 5.3+ (strict mode), Python 3.12+ (analytics services)
- **Framework**: Next.js 14.2 (App Router), FastAPI 0.110+
- **Database**: PostgreSQL 16 with Prisma ORM 5.x, MongoDB 7.0 (time-series analytics)
- **Cache**: Redis 7.2+ (sessions, real-time state)
- **Package Manager**: pnpm 9.x (workspace management)

### Explicitly DO NOT Use
- Redux (use Zustand instead)
- Axios (use native fetch with retry logic)
- Moment.js (use date-fns)
- class-based React components (functional only)
- CSS-in-JS libraries (TailwindCSS only)
- GraphQL (REST + WebSocket architecture)

### File-Scoped Commands (Preferred - Fast)
```bash
# Type check single file (2-3 seconds)
pnpm tsc --noEmit apps/web/app/dashboard/page.tsx

# Lint single file
pnpm eslint apps/web/lib/utils.ts

# Run single test file
pnpm vitest run apps/web/__tests__/timer.test.ts

# Python lint single file
ruff check services/analytics/app/models.py
```
```

출처: https://github.com/obviousworks/agentic-coding-rulebook/blob/main/agent_example.md

**주목할 점:**
- "Explicitly DO NOT Use" 섹션 — 패턴 #4(금지 사항)의 구체적 구현
- file-scoped vs project-wide 명령어 분리 — "ASK BEFORE RUNNING" 표시
- Safety and Permissions의 2단계 분리 — Groff.dev의 ✅/⚠️/🚫와 유사

---

## 소스 간 비교: 같은 패턴의 다른 구현

### "금지 사항"을 어떻게 표현하는가

| 소스 | 구현 형태 | 실제 코드 |
|------|----------|----------|
| Anthropic | user prompt에서 강한 어조 | `"IT IS CATASTROPHIC TO REMOVE OR EDIT FEATURES"` |
| Exceptionless | AGENTS.md Constraints 섹션 | `"Never commit secrets"`, `"Use npm ci (not npm install)"` |
| HumanLayer | CLAUDE.md에 없음 (60줄이라 금지 사항 별도 안 넣음) | — |
| obviousworks | "DO NOT Use" + "Require Approval" 섹션 | `"Redux (use Zustand instead)"`, `"Deleting files → requires approval"` |
| Foundatio | "Craftsmanship Mindset" + Validation 체크리스트 | `"Prefer simplicity over cleverness"` |

### "self-review"를 어떻게 구현하는가

| 소스 | 구현 형태 | 위치 |
|------|----------|------|
| Anthropic | coding_prompt.md의 Step 3 (회귀 테스트) + Step 6 (e2e 검증) | user prompt |
| Foundatio | AGENTS.md의 "Validation" 섹션 (6개 체크 항목) | AGENTS.md |
| Exceptionless | @reviewer 에이전트 (별도 에이전트로 분리) | `.claude/agents/` |
| obviousworks | "Before Creating PR" 체크리스트 | agent_template.md |

### "문서 자동 업데이트"를 어떻게 구현하는가

| 소스 | 구현 형태 | 실제 코드 |
|------|----------|----------|
| Exceptionless | AGENTS.md에 텍스트 규칙 | `"Each time you complete a task, you must update AGENTS.md, README.md, or relevant skill files"` |
| Foundatio | AGENTS.md Validation 체크리스트 항목 | `"Documentation updated: XML doc comments added/updated"` |
| Anthropic | coding_prompt.md Step 9 | `"Update claude-progress.txt with what you accomplished"` |

### "changelog/릴리스 노트"를 어떻게 구현하는가

| 소스 | 구현 형태 | 실제 코드 |
|------|----------|----------|
| Exceptionless | 스킬 (`.agents/skills/releasenotes/SKILL.md`) | `/releasenotes` 트리거, git history에서 자동 생성 |
| Anthropic | 없음 (하네스에 릴리스 노트 기능 없음) | — |
| 나머지 | 없음 | — |

→ **changelog/릴리스 노트를 스킬로 구현한 것은 Exceptionless가 유일.**
```

출처: 각 레포의 실제 파일 (위 URL 참조)
