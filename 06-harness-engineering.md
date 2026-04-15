# 06. 하네스 엔지니어링 — 종합 가이드

> 에이전트를 감싸는 실행 환경/시스템을 설계하여, 에이전트의 출력 품질과 신뢰성을 높이는 분야.
> Anthropic, Mitchell Hashimoto, HumanLayer, Simon Willison, Andrej Karpathy 등
> 다양한 소스에서 검증된 내용을 종합.

---

## 하네스 엔지니어링이란

### 정의

여러 사람이 각자의 관점에서 정의했다:

**Mitchell Hashimoto** (Ghostty 제작자, HashiCorp 공동창업자):
> "[Harness engineering] is the idea that anytime you find an agent makes a mistake,
> you take the time to engineer a solution such that the agent never makes that
> mistake again."
>
> — "My AI Adoption Journey" (2026-02-05)
> https://mitchellh.com/writing/my-ai-adoption-journey

**HumanLayer** (Dex Horthy, Dexter 창업자):
> "Harness engineering is the art and science of leveraging your coding agent's
> configuration points to improve output quality and increase task success rates."
>
> "We view harness engineering as a subset of context engineering."
>
> — "Skill Issue: Harness Engineering for Coding Agents"
> https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents

**Simon Willison** (Django 공동제작자):
> "A coding agent is a piece of software that acts as a harness for an LLM,
> extending that LLM with additional capabilities that are powered by invisible
> prompts and implemented as callable tools."
>
> — "How coding agents work" (Agentic Engineering Patterns)
> https://simonwillison.net/guides/agentic-engineering-patterns/how-coding-agents-work/

**공식**: HumanLayer에서 제시한 등식:
> `coding agent = AI model(s) + harness`

### 관련 용어의 계층 관계

**Andrej Karpathy** (OpenAI 공동창업자)가 2025-02에 "vibe coding"을 만들고,
2026-02에 이를 폐기하고 "agentic engineering"을 제시:

> "Today (1 year later), programming via LLM agents is increasingly becoming
> a default workflow for professionals, except with more oversight."
> "Engineering emphasizes that there is an art and science and expertise to it."
>
> — Karpathy on X, 2026-02
> https://observer.com/2026/02/andrej-karpathy-new-term-ai-coding/

**Anthropic**이 "context engineering"을 정의:
> "Context engineering refers to the set of strategies for curating and maintaining
> the optimal set of tokens (information) during LLM inference."
> "We view context engineering as the natural progression of prompt engineering."
>
> — "Effective context engineering for AI agents"
> https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents

**HumanLayer**가 계층을 정리:
> "Harness engineering is the subset of context engineering which primarily involves
> leveraging harness configuration points to carefully manage the context windows
> of coding agents."

정리하면:

```
Agentic Engineering (Karpathy) — 가장 넓은 범위
  └── Context Engineering (Anthropic) — 에이전트에 주는 컨텍스트 최적화
       └── Harness Engineering (Mitchell Hashimoto, HumanLayer) — 에이전트 실행 환경 설계
            └── Prompt Engineering — 프롬프트 작성 (가장 좁은 범위)
```

---

## 왜 하네스 엔지니어링이 필요한가

### 모델 문제가 아니라 구성 문제

**HumanLayer**:
> "it's not a model problem. It's a configuration problem."
>
> "Yes, models will get smarter, and some existing failure modes will disappear.
> And then because they are smarter, we will give them new problems which are bigger
> and harder, and they will continue to fail in unexpected ways."

### Mitchell Hashimoto의 발견

> "agents are much more efficient when they produce the right result the first time,
> or at worst produce a result that requires minimal touch-ups. The most sure-fire
> way to achieve this is to give the agent fast, high quality tools to automatically
> tell it when it is wrong."
>
> "If you give an agent a way to verify its work, it more often than not fixes its
> own mistakes and prevents regressions."

### Anthropic의 Context Rot 발견

> "as the number of tokens in the context window increases, the model's ability to
> accurately recall information from that context decreases."
>
> "Context, therefore, must be treated as a finite resource with diminishing marginal
> returns."
>
> — "Effective context engineering for AI agents"

---

## 하네스의 구성 요소

### HumanLayer의 6가지 레버

HumanLayer 포스트에서 정리한 하네스의 구성 표면:

1. **CLAUDE.md / AGENTS.md** — 시스템 프롬프트에 주입되는 규칙 파일
2. **MCP 서버** — 에이전트에 도구 추가 (Linear, Sentry, DB 등)
3. **Skills** — 작업별 on-demand 지식 주입 (Progressive Disclosure)
4. **Sub-agents** — 컨텍스트 격리 + 오케스트레이션
5. **Hooks** — 특정 이벤트에 자동 실행되는 스크립트/핸들러
6. **Back-pressure mechanisms** — 에이전트의 행동을 제어하는 검증 장치

**HumanLayer 원문**:
> "Sub-agents are a particularly powerful lever. When working on hard problems
> that require many, many context windows to solve, sub-agents are the key to
> maintaining coherency across many sessions. Sub-agents function as a 'context
> firewall' that ensures discrete tasks can run in isolated context windows so
> none of the intermediate noise accumulates in your parent thread."

### Simon Willison의 정의

Simon Willison은 하네스를 더 근본적으로 정의:

> "A coding agent is a piece of software that acts as a harness for an LLM,
> extending that LLM with additional capabilities that are powered by invisible
> prompts and implemented as callable tools."

하네스 = 시스템 프롬프트 + 도구 + 루프:
> "Believe it or not, that's most of what it takes to build a coding agent!
> LLM + system prompt + tools in a loop."

---

## Anthropic의 장시간 자율 개발 하네스

### 실패 패턴 (포스트 1, 2025-11-26)

출처: "Effective Harnesses for Long-Running Agents"
https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents

**실패 1: 한 번에 너무 많이 하려 함**
> "the agent tended to try to do too much at once—essentially to attempt to
> one-shot the app."

**실패 2: 조기 완료 선언**
> "a later agent instance would look around, see that progress had been made,
> and declare the job done."

**실패 3: 기능 미검증 완료**
> "Claude's tendency to mark a feature as complete without proper testing."

### 해결책 (포스트 1)

**Initializer + Coding Agent 분리:**
> "an initializer agent that sets up the environment on the first run, and a
> coding agent that is tasked with making incremental progress in every session."

**Feature List (JSON):**
> "features were all initially marked as 'failing'"
> "We prompt coding agents to edit this file only by changing the status of a
> passes field"
> "we landed on using JSON for this, as the model is less likely to inappropriately
> change or overwrite JSON files compared to Markdown files."

**Progress File:**
> "The key insight here was finding a way for agents to quickly understand the
> state of work when starting with a fresh context window, which is accomplished
> with the claude-progress.txt file alongside the git history."

**한 번에 하나만:**
> "work on only one feature at a time. This incremental approach turned out to be
> critical."

**e2e 테스트 도구 제공:**
> "Providing Claude with these kinds of testing tools dramatically improved
> performance, as the agent was able to identify and fix bugs that weren't
> obvious from the code alone."

**세션 시작 루틴:**
> 1. pwd → 2. git log + progress 읽기 → 3. feature list 읽기 → 4. init.sh 실행
> 5. 기본 테스트 → 6. 새 기능 시작

### 추가 실패 패턴 + 해결책 (포스트 2, 2026-03-24)

출처: "Harness Design for Long-Running Application Development"
https://www.anthropic.com/engineering/harness-design-long-running-apps

**실패 4: 자기 코드를 과대평가**
> "agents tend to respond by confidently praising the work—even when quality
> is obviously mediocre."

**실패 5: 컨텍스트 불안**
> "context anxiety, in which they begin wrapping up work prematurely"

**해결: Generator-Evaluator 분리**
> "Separating the agent doing the work from the agent judging it proves to be
> a strong lever. Tuning a standalone evaluator to be skeptical turns out to be
> far more tractable than making a generator critical of its own work."

**해결: 3-Agent 아키텍처**
> Planner → Generator → Evaluator
> "a three-agent architecture that produced rich full-stack applications over
> multi-hour autonomous coding sessions."

**해결: Sprint Contract**
> "Before each sprint, the generator and evaluator negotiated a sprint contract:
> agreeing on what 'done' looked like for that chunk of work before any code
> was written."

**해결: Context Reset vs Compaction**
> "A reset provides a clean slate, at the cost of the handoff artifact having
> enough state for the next agent to pick up the work cleanly."
> "Opus 4.5 largely removed that behavior [context anxiety] on its own, so I was
> able to drop context resets from this harness entirely."

---

## HumanLayer의 실전 교훈

출처: "Skill Issue: Harness Engineering for Coding Agents"
https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents

### CLAUDE.md에 대한 ETH Zurich 연구 결과

HumanLayer가 인용한 ETH Zurich 연구 (arxiv 2602.11988):

> "LLM-generated ones actually hurt performance while costing 20%+ more"
> "human-written ones only helped about 4%"
> "Agents spent 14-22% more reasoning tokens processing context file instructions"
> "Codebase overviews and directory listings didn't help at all; agents discover
> repository structure on their own just fine."

HumanLayer의 결론:
> "Our CLAUDE.md is under 60 lines."

### MCP 도구 과다의 위험

> "plug too many MCP tools into your agent, and the context window fills up with
> tool descriptions, pushing you into the dumb zone much faster"
>
> "if an MCP server duplicates functionality that's already available as a CLI
> well-represented in training data, it works better to just prompt the agent to
> use the CLI."

HumanLayer의 실제 사례 — Linear MCP를 CLI 래퍼로 교체:
> "This saved us thousands of tokens from the MCP server's tool definitions"

### Sub-agents as Context Firewall

> "Sub-agents function as a 'context firewall' that ensures discrete tasks can
> run in isolated context windows so none of the intermediate noise accumulates
> in your parent thread which is responsible for orchestration."

### 모델-하네스 결합도 주의

> "models can be over-fitted to their harness. Viv cites Terminal Bench 2.0
> where Opus 4.6 in Claude Code comes in position #33, but when placed in a
> different harness that wasn't seen during post-training, it comes in at #5."

---

## Mitchell Hashimoto의 실전 여정

출처: "My AI Adoption Journey" (2026-02-05)
https://mitchellh.com/writing/my-ai-adoption-journey

Mitchell의 6단계 AI 채택 여정 중 Step 5가 하네스 엔지니어링:

**Step 2에서 발견한 3가지 원칙:**
> 1. "Break down sessions into separate clear, actionable tasks. Don't try to
>    'draw the owl' in one mega session."
> 2. "For vague requests, split the work into separate planning vs. execution
>    sessions."
> 3. "If you give an agent a way to verify its work, it more often than not
>    fixes its own mistakes and prevents regressions."

**Step 5: 하네스 엔지니어링의 핵심:**
> "anytime you find an agent makes a mistake, you take the time to engineer a
> solution such that the agent never makes that mistake again."

이것은 내 가이드의 **패턴 #3(실수 관찰 → 규칙 추가)**과 정확히 일치하지만,
Mitchell은 이것을 **하네스 레벨**에서 해결한다 — 규칙 파일뿐 아니라
도구, 검증 스크립트, 자동화된 피드백 루프로.

---

## Anthropic의 Context Engineering 원칙

출처: "Effective context engineering for AI agents"
https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents

### 핵심 원칙

> "good context engineering means finding the smallest possible set of high-signal
> tokens that maximize the likelihood of some desired outcome."

### 시스템 프롬프트의 적정 고도

> "At one extreme, we see engineers hardcoding complex, brittle logic in their
> prompts. At the other extreme, engineers sometimes provide vague, high-level
> guidance that fails to give the LLM concrete signals."
>
> "The optimal altitude strikes a balance: specific enough to guide behavior
> effectively, yet flexible enough to provide the model with strong heuristics."

### 도구 설계

> "One of the most common failure modes we see is bloated tool sets that cover
> too much functionality or lead to ambiguous decision points about which tool
> to use. If a human engineer can't definitively say which tool should be used
> in a given situation, an AI agent can't be expected to do better."

### Just-in-Time Context vs Pre-loaded Context

> "Rather than pre-processing all relevant data up front, agents built with the
> 'just in time' approach maintain lightweight identifiers (file paths, stored
> queries, web links, etc.) and use these references to dynamically load data
> into context at runtime using tools."

### Progressive Disclosure (에이전틱 탐색)

> "Letting agents navigate and retrieve data autonomously enables progressive
> disclosure—agents incrementally discover relevant context through exploration.
> Each interaction yields context that informs the next decision."

---

## 12개 패턴과의 관계

### 겹치는 것

| 내 가이드 패턴 | 하네스 엔지니어링 대응 | 차이 |
|---|---|---|
| #1 git log 시딩 | Anthropic "git log + progress 읽기" | 하네스는 progress file 추가 |
| #2 Checkpointing | Anthropic "git commit" | 동일 메커니즘 |
| #3 실수→규칙 | Mitchell "agent never makes that mistake again" | Mitchell은 하네스 레벨(도구/검증)로 해결 |
| #5 규칙 짧게 | HumanLayer "under 60 lines" + ETH Zurich 연구 | 동일 원칙, 정량 근거 추가 |
| #6 Self-Review | Anthropic Evaluator 에이전트 | 하네스는 별도 에이전트로 분리 |
| #8 Conv. Commits | Anthropic "descriptive commit messages" | 동일 원칙 |

### 하네스만 다루는 것

| 하네스 패턴 | 내용 | 출처 |
|---|---|---|
| Feature List (JSON) | 기능 목록 + passes 플래그 | Anthropic 포스트 1 |
| Progress File | 세션 간 상태 전달 | Anthropic 포스트 1 |
| Generator-Evaluator 분리 | 만드는 것과 평가하는 것 분리 | Anthropic 포스트 2 |
| Sprint Contract | 구현 전 완료 조건 합의 | Anthropic 포스트 2 |
| Sub-agents as Context Firewall | 컨텍스트 격리 | HumanLayer |
| MCP 도구 최소화 | 불필요한 도구가 성능 저하 | HumanLayer |
| Just-in-Time Context | 필요할 때만 로딩 | Anthropic Context Engineering |
| Context Reset/Compaction | 세션 완전 초기화 + handoff | Anthropic 포스트 2 |

---

## 소스 목록

| # | 소스 | 저자 | 날짜 | URL |
|---|------|------|------|-----|
| 1 | Effective Harnesses for Long-Running Agents | Justin Young (Anthropic) | 2025-11-26 | https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents |
| 2 | Harness Design for Long-Running App Dev | Prithvi Rajasekaran (Anthropic Labs) | 2026-03-24 | https://www.anthropic.com/engineering/harness-design-long-running-apps |
| 3 | Effective Context Engineering for AI Agents | Anthropic | 2025 | https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents |
| 4 | My AI Adoption Journey | Mitchell Hashimoto | 2026-02-05 | https://mitchellh.com/writing/my-ai-adoption-journey |
| 5 | Skill Issue: Harness Engineering for Coding Agents | HumanLayer (Dex Horthy) | 2026 | https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents |
| 6 | How coding agents work | Simon Willison | 2026-03 | https://simonwillison.net/guides/agentic-engineering-patterns/how-coding-agents-work/ |
| 7 | Karpathy "agentic engineering" 정의 | Andrej Karpathy | 2026-02 | https://observer.com/2026/02/andrej-karpathy-new-term-ai-coding/ |
| 8 | ETH Zurich AGENTS.md 연구 | (HumanLayer 인용) | 2026 | https://arxiv.org/abs/2602.11988 |
