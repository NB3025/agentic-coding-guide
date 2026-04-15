# 07. 실전 시뮬레이션 — LLM 기반 콜봇 프로젝트

> 12개 패턴 + 하네스 엔지니어링이 실제 프로젝트에서 어떻게 활성화되는지
> 콜봇 프로젝트를 처음부터 끝까지 시뮬레이션.
>
> **원칙**: Anthropic의 실제 코드/프롬프트를 최대한 인용.
> 출처: https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding

---

## 프로젝트 전제

- **목표**: 고객센터에서 사용하는 LLM 기반 콜봇
- **시작 상태**: 맨바닥 (코드 없음, repo 없음)
- **사용자 패턴**: 
  - Phase A: 시나리오 정의 → 기능정의서 → 구현계획까지 개발자가 참여
  - Phase B: 구현계획 확정 후 에이전트가 혼자 e2e까지 개발
  - Phase C: 개발자가 실행해보고 버그/요구사항 피드백

---

## Phase A: 개발자 + 에이전트 협업 (Day 1~2)

### 장면 1: 첫 대화

```
개발자: "고객센터에서 사용하는 LLM기반의 콜봇 만들어줘. 시나리오부터 정의하자."
```

이 시점에서는 **아직 아무 패턴도 활성화되지 않는다.**
개발자와 에이전트가 대화하면서 시나리오를 잡고, 기능정의서와 구현계획을 작성한다.

### 장면 2: 하네스 파일 세팅 — ⚡ Phase 0 활성화

구현 시작 전에, Anthropic 방식으로 하네스를 구성한다.

#### 하네스의 실제 구조 (Anthropic 코드 기반)

Anthropic의 실제 파일 구조:
```
autonomous-coding/
├── autonomous_agent_demo.py    # 진입점
├── agent.py                    # 세션 루프
├── client.py                   # Claude SDK 클라이언트 설정
├── security.py                 # bash 명령어 allowlist (훅)
├── prompts/
│   ├── app_spec.txt            # 앱 스펙
│   ├── initializer_prompt.md   # 첫 세션 user prompt
│   └── coding_prompt.md        # 이후 세션 user prompt
```
출처: https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding

콜봇 프로젝트에 적용하면:
```
callbot-harness/
├── agent.py                    # 세션 루프 (Anthropic agent.py 기반)
├── client.py                   # SDK 클라이언트 설정
├── security.py                 # bash allowlist
├── prompts/
│   ├── app_spec.txt            # 콜봇 스펙 (개발자가 작성)
│   ├── initializer_prompt.md   # 첫 세션 user prompt
│   └── coding_prompt.md        # 이후 세션 user prompt
```

#### 시스템 프롬프트 — 실제 구현: SDK 파라미터 1줄

Anthropic의 실제 `client.py`:
```python
return ClaudeSDKClient(
    options=ClaudeCodeOptions(
        system_prompt="You are an expert full-stack developer building a production-quality web application.",
        ...
    )
)
```
출처: client.py

시스템 프롬프트는 **1줄**이다. 나머지 모든 행동 지시는 user prompt(md 파일)에 있다.

#### MCP 서버 — 실제 구현: Puppeteer 1개만

Anthropic의 실제 `client.py`:
```python
return ClaudeSDKClient(
    options=ClaudeCodeOptions(
        allowed_tools=[
            "Read", "Write", "Edit", "Glob", "Grep", "Bash",  # 내장 도구
            "mcp__puppeteer__puppeteer_navigate",               # 브라우저 테스트
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
출처: client.py

MCP 서버는 **Puppeteer 1개만**. 나머지(git, pytest, curl 등)는 Bash 도구로 직접 실행.
HumanLayer가 말한 "CLI로 충분한 것은 MCP 불필요" 원칙과 일치.

#### 보안 훅 — 실제 구현: bash allowlist

Anthropic의 실제 `security.py`:
```python
ALLOWED_COMMANDS = {
    "ls", "cat", "head", "tail", "wc", "grep",   # 파일 검사
    "cp", "mkdir", "chmod",                        # 파일 조작
    "pwd",                                         # 디렉토리
    "npm", "node",                                 # Node.js
    "git",                                         # 버전 관리
    "ps", "lsof", "sleep", "pkill",               # 프로세스
    "init.sh",                                     # 스크립트
}
```

Anthropic의 실제 `client.py`에서 훅 등록:
```python
from security import bash_security_hook

hooks={
    "PreToolUse": [
        HookMatcher(matcher="Bash", hooks=[bash_security_hook]),
    ],
},
```
출처: client.py, security.py

**Anthropic 코드에서 훅은 이 보안 목적 1개만 존재한다.**

---

## Phase B: 에이전트 자율 개발 (Day 2~10, 개발자 없음)

### 하네스 루프의 실제 구현

Anthropic의 실제 `agent.py` — 세션 루프:
```python
# feature_list.json이 있는지 확인해서 첫 실행인지 판별
tests_file = project_dir / "feature_list.json"
is_first_run = not tests_file.exists()

while True:
    # 매 세션마다 새 클라이언트 = 새 컨텍스트 윈도우
    client = create_client(project_dir, model)

    # 첫 세션이면 initializer, 아니면 coding prompt
    if is_first_run:
        prompt = get_initializer_prompt()
        is_first_run = False
    else:
        prompt = get_coding_prompt()

    # user prompt 주입 → 에이전트 실행
    async with client:
        status, response = await run_agent_session(client, prompt, project_dir)

    # 3초 대기 후 다음 세션 (자동 반복)
    await asyncio.sleep(AUTO_CONTINUE_DELAY_SECONDS)
```
출처: agent.py

**핵심**: 매 루프가 새 `create_client()` = 자동 context reset. 별도 reset 로직 없음.

### 세션 1: Initializer Agent (첫 실행)

하네스가 `initializer_prompt.md`를 user prompt로 주입한다.

Anthropic의 실제 `initializer_prompt.md`:
```markdown
## YOUR ROLE - INITIALIZER AGENT (Session 1 of Many)

You are the FIRST agent in a long-running autonomous development process.
Your job is to set up the foundation for all future coding agents.

### FIRST: Read the Project Specification

Start by reading `app_spec.txt` in your working directory.

### CRITICAL FIRST TASK: Create feature_list.json

Based on `app_spec.txt`, create a file called `feature_list.json` with 200
detailed end-to-end test cases.

**Format:**
[
  {
    "category": "functional",
    "description": "Brief description of the feature",
    "steps": [
      "Step 1: Navigate to relevant page",
      "Step 2: Perform action",
      "Step 3: Verify expected result"
    ],
    "passes": false
  }
]

**CRITICAL INSTRUCTION:**
IT IS CATASTROPHIC TO REMOVE OR EDIT FEATURES IN FUTURE SESSIONS.
Features can ONLY be marked as passing (change "passes": false to "passes": true).
Never remove features, never edit descriptions, never modify testing steps.

### SECOND TASK: Create init.sh
Create a script that future agents can use to quickly set up and run
the development environment.

### THIRD TASK: Initialize Git
Create a git repository and make your first commit.
Commit message: "Initial setup: feature_list.json, init.sh, and project structure"

### ENDING THIS SESSION
Before your context fills up:
1. Commit all work with descriptive messages
2. Create `claude-progress.txt` with a summary
3. Ensure feature_list.json is complete and saved
4. Leave the environment in a clean, working state
```
출처: prompts/initializer_prompt.md (발췌)

콜봇 프로젝트에서 이 세션이 실행되면:
- `app_spec.txt` 읽음 (콜봇 스펙)
- `feature_list.json` 생성 (8개 기능에 대한 테스트 케이스들, 전부 `passes: false`)
- `init.sh` 생성
- `claude-progress.txt` 초기화
- git init + 첫 커밋

### 세션 2+: Coding Agent (이후 모든 세션)

하네스가 `coding_prompt.md`를 user prompt로 주입한다.

Anthropic의 실제 `coding_prompt.md` — 전체 10단계:

#### Step 1: 세션 시작 루틴 (실제 코드)

```markdown
### STEP 1: GET YOUR BEARINGS (MANDATORY)

Start by orienting yourself:

```bash
# 1. See your working directory
pwd

# 2. List files to understand project structure
ls -la

# 3. Read the project specification
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
```
출처: prompts/coding_prompt.md Step 1

이것이 에이전트의 실제 동작이 된다:
```
[Assistant] I'll start by getting my bearings and understanding the current state.
[Tool Use] <bash - pwd>
[Tool Use] <read - claude-progress.txt>
[Tool Use] <read - feature_list.json>
[Tool Use] <bash - git log --oneline -20>
```

#### Step 2: 서버 시작 (실제 코드)

```markdown
### STEP 2: START SERVERS (IF NOT RUNNING)

If `init.sh` exists, run it:
```bash
chmod +x init.sh
./init.sh
```
```
출처: prompts/coding_prompt.md Step 2

#### Step 3: 기존 기능 회귀 테스트 (실제 코드)

```markdown
### STEP 3: VERIFICATION TEST (CRITICAL!)

**MANDATORY BEFORE NEW WORK:**

The previous session may have introduced bugs. Before implementing anything
new, you MUST run verification tests.

Run 1-2 of the feature tests marked as `"passes": true` that are most core
to the app's functionality to verify they still work.

**If you find ANY issues (functional or visual):**
- Mark that feature as "passes": false immediately
- Add issues to a list
- Fix all issues BEFORE moving to new features
- This includes UI bugs like:
  * White-on-white text or poor contrast
  * Random characters displayed
  * Layout issues or overflow
  * Console errors
```
출처: prompts/coding_prompt.md Step 3

**이것이 Anthropic의 "self-review" 구현이다.** 별도 스킬이 아니라 **user prompt의 Step 3**.

#### Step 4: 기능 선택 — 한 번에 하나만 (실제 코드)

```markdown
### STEP 4: CHOOSE ONE FEATURE TO IMPLEMENT

Look at feature_list.json and find the highest-priority feature with "passes": false.

Focus on completing one feature perfectly in this session before moving on.
It's ok if you only complete one feature in this session, as there will be
more sessions later that continue to make progress.
```
출처: prompts/coding_prompt.md Step 4

#### Step 6: e2e 브라우저 테스트 (실제 코드)

```markdown
### STEP 6: VERIFY WITH BROWSER AUTOMATION

**CRITICAL:** You MUST verify features through the actual UI.

Available tools:
- puppeteer_navigate - Start browser and go to URL
- puppeteer_screenshot - Capture screenshot
- puppeteer_click - Click elements
- puppeteer_fill - Fill form inputs

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
```
출처: prompts/coding_prompt.md Step 6

#### Step 7: feature_list.json 업데이트 (실제 코드)

```markdown
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
```
출처: prompts/coding_prompt.md Step 7

#### Step 8~10: 세션 정리 (실제 코드)

```markdown
### STEP 8: COMMIT YOUR PROGRESS

```bash
git add .
git commit -m "Implement [feature name] - verified end-to-end

- Added [specific changes]
- Tested with browser automation
- Updated feature_list.json: marked test #X as passing
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
```
출처: prompts/coding_prompt.md Step 8~10

### 콜봇 프로젝트에서 실제 세션 흐름 예시

**세션 2** (Coding Agent, STT 엔진):

```
[하네스] coding_prompt.md를 user prompt로 주입

[에이전트 — Step 1 실행]
> pwd
/home/user/callbot
> cat claude-progress.txt
## 완료: 초기 셋업 (feature_list.json, init.sh)
## 미시작: 기능 1~8
> cat feature_list.json | grep '"passes": false' | wc -l
47   ← 전부 false
> git log --oneline -20
abc1234 Initial setup: feature_list.json, init.sh, and project structure

[에이전트 — Step 2 실행]
> chmod +x init.sh
> ./init.sh
✅ Server running

[에이전트 — Step 3 스킵]
(아직 passes: true인 기능이 없으므로 회귀 테스트 대상 없음)

[에이전트 — Step 4 실행]
"feature_list.json에서 최우선 기능: STT 엔진 (passes: false)"

[에이전트 — Step 5 실행]
src/stt/transcribe_engine.py 작성
→ git commit -m "feat(stt): add TranscribeSTTEngine with streaming support"

tests/test_stt.py 작성
→ git commit -m "test(stt): add unit tests for TranscribeSTTEngine"

[에이전트 — Step 6 실행 (e2e 검증)]
> puppeteer_navigate → http://localhost:8000
> (또는 curl로 API 테스트 — 콜봇은 UI가 아닌 API이므로)
> 실제 Transcribe API 호출 테스트

[에이전트 — Step 7 실행]
feature_list.json에서 STT 관련 테스트들: passes: false → true

[에이전트 — Step 8~10 실행]
> git add .
> git commit -m "Implement STT engine - verified end-to-end"
> claude-progress.txt 업데이트:
  "## 완료: STT 엔진 (5 tests passing)
   ## 다음: 인텐트 분류기"

[하네스] 세션 종료 → 3초 대기 → 새 client 생성 → coding_prompt.md 다시 주입 → 세션 3 시작
```

**세션 3** (Coding Agent, 인텐트 분류기):

```
[하네스] 새 client = 새 컨텍스트 윈도우. coding_prompt.md 주입.

[에이전트 — Step 1 실행]
> cat claude-progress.txt
## 완료: STT 엔진 (5 tests passing)
## 다음: 인텐트 분류기
> cat feature_list.json | grep '"passes": false' | wc -l
42
> git log --oneline -20
def5678 Implement STT engine - verified end-to-end
abc1234 Initial setup

[에이전트 — Step 2 실행]
> ./init.sh
✅ Server running

[에이전트 — Step 3 실행 — 회귀 테스트!]
"STT 기능이 passes: true이므로, 먼저 STT가 여전히 작동하는지 확인"
> curl -X POST /api/stt -d @test_audio.wav
→ 정상 응답 ✅

[에이전트 — Step 4 실행]
"다음 기능: 인텐트 분류기 (passes: false)"

[에이전트 — Step 5 실행]
src/nlu/classifier.py 작성
...

[에이전트 — Step 6에서 버그 발견!]
> curl -X POST /api/classify -d '{"text": ""}'
→ 500 Internal Server Error
→ "LLM 호출 실패 시 None 반환 문제 발견. Step 3의 원칙에 따라 새 기능 전에 수정."

수정 후:
→ git commit -m "fix(nlu): raise exception on LLM failure instead of returning None"

[에이전트 — Step 7~10]
feature_list.json 업데이트, progress 업데이트, 커밋
```

**세션 3에서 벌어진 일의 핵심:**
- **Step 3** (회귀 테스트)이 기존 기능 정상 확인
- **Step 6** (e2e 검증)에서 에이전트가 직접 버그 발견
- 이것은 Anthropic이 설계한 coding_prompt.md의 구조 덕분 — 별도 self-review 스킬이 아님

---

## Phase C: 개발자가 실행 + 피드백 (Day 11~)

### 장면 1: 개발자가 직접 테스트

Phase B가 끝나고, 개발자가 직접 실행:

```
개발자: "응답이 너무 딱딱해. '~하겠습니다' 체가 아니라 '~해 드릴게요' 체 써야 해."
개발자: "상담원 전환할 때 '잠시만 기다려 주세요' 멘트가 없어."
```

이것들은 Phase B의 에이전트가 찾지 못한 것들이다.

Anthropic (포스트 2):
> "agents tend to confidently praise the work—even when quality is obviously mediocre"

톤과 UX는 사용자만 판단 가능.

### 장면 2: ⚡ #3 → #4 피드백 루프

12개 패턴의 #3(실수 관찰 → 규칙 추가)이 발동:

```markdown
## Boundaries 업데이트 (규칙 파일에 추가)
- ✅ Always:
  - 응답 톤: '~해 드릴게요' 체
  - 상태 전환 시 안내 멘트 포함
```

### 장면 3: Mitchell 패턴 — "도구로 막아라"

Mitchell Hashimoto:
> "anytime you find an agent makes a mistake, you take the time to engineer
> a solution such that the agent never makes that mistake again."
> "The most sure-fire way to achieve this is to give the agent fast, high quality
> tools to automatically tell it when it is wrong."
출처: https://mitchellh.com/writing/my-ai-adoption-journey

규칙 파일에 적는 것(#3 → #4) **외에**, 검증을 자동화하는 방법:

Anthropic의 방식을 따르면 → **coding_prompt.md의 Step 3에 검증 항목을 추가**:

```markdown
### STEP 3: VERIFICATION TEST (CRITICAL!)

... (기존 내용) ...

추가 검증 (Phase C에서 축적):
- 응답 텍스트에서 '~하겠습니다' 패턴이 없는지 확인
- 상태 전환 시 안내 멘트가 포함되어 있는지 확인
```

또는 Anthropic의 **보안 훅과 같은 패턴**으로 — `security.py`처럼 검증 훅을 추가:

```python
# tone_check.py — Mitchell 패턴: 도구로 자동 감지
def check_response_tone(response_text):
    forbidden = ["하겠습니다", "드리겠습니다", "됩니다"]
    for pattern in forbidden:
        if pattern in response_text:
            return f"BLOCKED: '{pattern}' 사용 금지. '~해 드릴게요' 체를 사용하세요."
    return None
```

**Anthropic은 실제 코드에서 이런 형태를 사용하지 않았다** — 보안 훅만 있었다.
하지만 Mitchell이 말한 "tools to automatically tell it when it is wrong"의
구체적 구현 형태로, Anthropic의 훅 패턴(`PreToolUse` + 검증 함수)을 재활용하는 것은
소스에 기반한 합리적 확장이다. (이 부분은 내 조합임을 명시.)

### 장면 4: 버그 발견 — ⚡ #7 활성화

```
개발자: "어제까지 되던 세션 타임아웃이 안 돼."
```

Simon Willison:
> "Coding agents can handle this boilerplate for you. This upgrades Git bisect
> from an occasional use tool to one you can deploy any time."
출처: https://simonwillison.net/guides/agentic-engineering-patterns/using-git-with-coding-agents/

```bash
git bisect start
git bisect bad HEAD
git bisect good <Day 5 커밋>
# 원인 커밋 발견
```

Phase B에서 Anthropic의 Step 8("Commit your progress")을 따라 잘게 커밋했기 때문에
bisect가 정확히 원인 커밋을 가리킨다.

### 장면 5: 릴리스 노트 자동 생성 — Exceptionless 패턴

프로젝트가 성숙하면, 릴리스 노트를 수동으로 쓰는 대신
Exceptionless의 releasenotes 스킬 패턴을 적용할 수 있다.

**실제 구현 — Exceptionless `.agents/skills/releasenotes/SKILL.md`:**
```yaml
---
name: releasenotes
description: Generate formatted changelogs from git history since the last release tag.
triggers:
- /releasenotes
---

## Steps
1. Find the most recent release tag using `git tag --sort=-creatordate`
2. Get commits and merged PRs since that tag
3. Look at previous releases in this repo to match their format and style
4. Categorize changes into sections: Breaking Changes, Added, Changed, Fixed, Notes
5. Focus on user-facing changes
6. Include PR links and contributor attribution
```
출처: https://github.com/exceptionless/Exceptionless/blob/main/.agents/skills/releasenotes/SKILL.md

`/releasenotes` 커맨드 한 번으로 git history에서 changelog 자동 생성.
이것이 "changelog.md를 에이전트가 관리하는" 검증된 유일한 실제 구현.

### 장면 6: Continuous Improvement — Exceptionless 패턴

개발자의 피드백으로 축적된 규칙이 프로젝트 지식으로 정착되는 과정.

**실제 구현 — Exceptionless `AGENTS.md`:**
```markdown
Each time you complete a task or learn important information about the project,
you must update the `AGENTS.md`, `README.md`, or relevant skill files.

If you encounter recurring questions or patterns during planning, document them:
- Project-specific knowledge → `AGENTS.md` or relevant skill file
- Reusable domain patterns → Create/update appropriate skill in `.agents/skills/`
```
출처: https://github.com/exceptionless/Exceptionless/blob/main/AGENTS.md

이것은 패턴 #3(실수→규칙) + #9(문서 업데이트)의 **프로덕션 레벨 구현**.
"반복되는 패턴을 발견하면 AGENTS.md 또는 스킬로 문서화하라"를
AGENTS.md 자체에 규칙으로 넣어둔 것.

### 장면 7: PR 전 — ⚡ #10 활성화

```
개발자: "통화 녹음 기능도 추가해줘."
```

Anthropic 방식: feature_list.json에 새 항목 추가 (passes: false) →
하네스가 다시 Phase B 루프를 돌리면서 이 기능을 구현.

### 장면 6: PR 전 — ⚡ #10 활성화

Simon Willison:
> "Don't think of the Git history as a permanent record of what actually happened
> — instead consider it to be a deliberately authored story."
출처: https://simonwillison.net/guides/agentic-engineering-patterns/using-git-with-coding-agents/

히스토리 정리 후 PR.

---

## 패턴 활성화 타임라인 (전체)

```
Day 1~2 ─── Phase A ──────────────────────────────────
  시나리오 정의 + 기능정의서 + 구현계획 (패턴 없음, 순수 대화)
  
  하네스 셋업:
  ⚡ app_spec.txt 작성 (개발자가 스펙 정의)
  ⚡ initializer_prompt.md + coding_prompt.md 준비
  ⚡ client.py 설정 (system_prompt 1줄 + Puppeteer MCP + 보안 훅)
  ⚡ agent.py 루프 준비

Day 2 ─── Phase B 시작: Initializer Agent ────────────
  [하네스] initializer_prompt.md 주입
  ⚡ feature_list.json 생성 (전부 passes: false)
  ⚡ init.sh 생성
  ⚡ claude-progress.txt 초기화
  ⚡ git init + 첫 커밋

Day 2~10 ─── Phase B: Coding Agent 반복 ─────────────
  [매 세션 — coding_prompt.md 자동 주입]

  Step 1: pwd, progress.txt, feature_list.json, git log 읽기
  Step 2: init.sh 실행
  Step 3: 기존 기능 회귀 테스트 (passes: true인 것 검증)
  Step 4: 다음 기능 선택 (passes: false 중 최우선)
  Step 5: 구현
  Step 6: e2e 검증 (Puppeteer 또는 curl)
  Step 7: feature_list.json passes: true 변경
  Step 8: git commit
  Step 9: progress.txt 업데이트
  Step 10: 세션 정리
  → [하네스] 3초 대기 → 새 client → coding_prompt.md 다시 주입

  [에이전트 자가 발견 순간들]
  - 세션 3: Step 6에서 LLM None 반환 버그 발견 → 수정
  - 세션 6: Step 3에서 기존 기능 깨짐 발견 → 새 기능 전에 수정
  - 세션 8: Step 6에서 WebSocket 라우트 충돌 발견 → 수정

Day 11+ ─── Phase C (개발자 피드백) ────────────────────────
  ⚡ #3  실수 관찰 → 규칙 추가 (톤, 안내 멘트)
  ⚡ Mitchell: coding_prompt.md Step 3에 검증 항목 추가
  ⚡ #7  git bisect (Simon Willison)
  ⚡ Exceptionless: /releasenotes 스킬로 changelog 자동 생성
  ⚡ Exceptionless: Continuous Improvement — AGENTS.md/스킬에 지식 축적
  ⚡ #9  문서 업데이트
  ⚡ #10 PR 전 히스토리 정리 (Simon Willison)
  ⚡ feature_list.json에 새 기능 추가 → Phase B 재진입
```

---

## Anthropic 하네스에서 각 기능의 실제 구현 형태 요약

| 기능 | 실제 구현 형태 | 실제 파일 |
|------|--------------|----------|
| 시스템 프롬프트 | SDK 파라미터 (1줄) | `client.py` |
| 세션 시작 루틴 | user prompt Step 1 | `coding_prompt.md` |
| Feature List | 일반 JSON 파일 + user prompt에서 규칙 | `feature_list.json` |
| Progress File | 일반 텍스트 파일 + user prompt에서 규칙 | `claude-progress.txt` |
| init.sh | 셸 스크립트 (Initializer가 생성) | `init.sh` |
| 회귀 테스트 | user prompt Step 3 | `coding_prompt.md` |
| 한 번에 하나만 | user prompt Step 4 | `coding_prompt.md` |
| e2e 브라우저 테스트 | MCP 서버 (Puppeteer) + user prompt Step 6 | `client.py` + `coding_prompt.md` |
| feature_list 보호 | user prompt에서 강한 어조로 금지 | `coding_prompt.md` Step 7 |
| bash 보안 제한 | 훅 (PreToolUse) | `security.py` + `client.py` |
| Context Reset | 루프에서 매번 새 client 생성 | `agent.py` |
| 세션 정리 | user prompt Step 8~10 | `coding_prompt.md` |
| 세션 자동 반복 | Python while 루프 + 3초 sleep | `agent.py` |

**핵심 발견: 대부분은 user prompt(md 파일)로 해결.**
스킬 없음. 훅은 보안 1개만. MCP는 Puppeteer 1개만.
나머지는 전부 일반 파일(JSON, txt, sh) + Python 오케스트레이션.

---

## 소스 출처

| 인용 | 출처 |
|------|------|
| agent.py, client.py, security.py, prompts/*.md | Anthropic claude-quickstarts (코드) |
| "agents tend to confidently praise the work" | Anthropic 포스트 2 (2026-03-24) |
| "engineer a solution such that the agent never makes that mistake again" | Mitchell Hashimoto (2026-02-05) |
| "plug too many MCP tools... dumb zone" | HumanLayer |
| Git bisect, 히스토리 편집 | Simon Willison |
| 패턴 #3 (실수→규칙), #7 (bisect), #10 (히스토리) | 01-verified-patterns.md |

**내 조합이 들어간 부분:**
- Mitchell 패턴을 Anthropic의 훅 패턴으로 구현하자는 제안 (장면 3) — 명시적으로 표시함
- 콜봇 프로젝트 특유의 내용 (STT, NLU, TTS 등 기능명) — 시뮬레이션 시나리오
- Phase C의 톤/UX 피드백 예시 — 시뮬레이션 시나리오
