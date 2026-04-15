# 05. 참조 소스 전체 목록

> 이 가이드에서 인용한 모든 소스의 상세 정보.
> 각 소스가 어떤 패턴의 근거인지, 원문 접근 방법, 신뢰도 수준을 포함.

---

## 학술 논문

### 1. Agent READMEs: An Empirical Study of Context Files for Agentic Coding
- **저자**: Chatlatanagulchai, Li, Kashiwa, Reid 외
- **출처**: arxiv 2511.12884 (2025-11-17)
- **URL**: https://arxiv.org/abs/2511.12884
- **규모**: 1,925개 레포에서 2,303개 에이전트 컨텍스트 파일 분석
- **사용된 패턴**: #5 (규칙 간결화), #12 (보안·성능 가드레일 부족)
- **핵심 발견**:
  - 기능적 컨텍스트(빌드 62.3%, 구현 69.9%, 아키텍처 67.7%)는 높은 포함률
  - 보안(14.5%), 성능(14.5%)은 낮은 포함률
  - 컨텍스트 파일은 정적 문서가 아니라 configuration code처럼 진화
- **신뢰도**: 높음 (대규모 실증 연구, 정량적 분석)

### 2. 별도 실증 연구 (AGENTS.md 평가)
- **출처**: arxiv 2602.11988 (Groff.dev에서 인용)
- **URL**: https://arxiv.org/abs/2602.11988
- **사용된 패턴**: #5 (불필요한 규칙이 성능 저하)
- **핵심 발견**: 불필요한 요구사항이 에이전트의 작업 수행을 더 어렵게 만듦
- **신뢰도**: 높음 (실증 연구)
- **비고**: 직접 읽지 않았고, Groff.dev의 인용을 통해 확인

### 3. SkillClaw: Let Skills Evolve Collectively with Agentic Evolver
- **출처**: arxiv 2604.08377 (2026-04-10 trending)
- **URL**: https://arxiv.org/abs/2604.08377
- **사용된 패턴**: (직접 패턴화하지 않음 — 배경 조사용)
- **핵심**: 사용자 궤적 자동 수집 → 스킬 자동 진화
- **신뢰도**: 중간 (프레임워크 제안, 아직 대규모 검증 없음)

### 4. Combee: Scaling Prompt Learning for Self-Improving Language Model Agents
- **출처**: arxiv 2604.04247 (2026-04-10 trending)
- **URL**: https://arxiv.org/abs/2604.04247
- **사용된 패턴**: (직접 패턴화하지 않음 — 배경 조사용)
- **핵심**: 실행 트레이스에서 배워 시스템 프롬프트 자동 개선
- **신뢰도**: 중간 (Berkeley+Stanford, 프레임워크 제안)

---

## 실전 가이드 / 블로그

### 5. Simon Willison — Using Git with coding agents
- **출처**: Agentic Engineering Patterns (가이드 시리즈)
- **URL**: https://simonwillison.net/guides/agentic-engineering-patterns/using-git-with-coding-agents/
- **사용된 패턴**: #1 (git log 시딩), #7 (git bisect), #10 (히스토리 편집)
- **핵심**: Git을 에이전트와 함께 쓰는 실전 패턴
- **신뢰도**: 높음 (Simon Willison은 Django co-creator, Datasette 제작자. 에이전틱 코딩 분야의 대표적 실무 전문가)

### 6. Groff.dev — Implementing CLAUDE.md and Agent Skills In Your Repository
- **저자**: Matthew Groff
- **출처**: 블로그 (2026-02-10)
- **URL**: https://www.groff.dev/blog/implementing-claude-md-agent-skills
- **사용된 패턴**: #4 (3단계 경계), #5 (3-Tier 구조, 60~100줄), #6 (self-review 스킬)
- **핵심**: Progressive disclosure 기반 3-Tier 문서 아키텍처
- **신뢰도**: 중~높음 (실제 프로덕션 레포에서 운용, 구체적 수치 제시)

### 7. Blake Niemyjski — Agentic Driven Development (ADD)
- **출처**: 블로그 (blakeniemyjski.com)
- **URL**: https://blakeniemyjski.com/blog/agentic-driven-development/
- **사용된 패턴**: #9 (문서 자동 업데이트, releasenotes 스킬)
- **핵심**: AGENTS.md + 22개 스킬로 실제 오픈소스 프로젝트 운영
- **운영 프로젝트**: Exceptionless (에러 모니터링), Foundatio (.NET 빌딩 블록)
- **실제 코드 레포**:
  - Exceptionless: https://github.com/exceptionless/Exceptionless (`AGENTS.md` + `.agents/skills/`)
  - Foundatio: https://github.com/FoundatioFx/Foundatio (`AGENTS.md`)
- **신뢰도**: 높음 (실제 오픈소스 프로젝트에서 장기 운영)

### 8. obviousworks/agentic-coding-rulebook
- **출처**: GitHub 레포
- **URL**: https://github.com/obviousworks/agentic-coding-rulebook/blob/main/best_practices.md
- **사용된 패턴**: #3 (반복 실수 관찰 → 규칙 추가, 월간 리뷰), #6 (AI 자기 리뷰)
- **핵심**: 관찰 기반 점진적 규칙 구축
- **실제 코드 파일**:
  - `agent_template.md`: AGENTS.md 템플릿 전체 구조
  - `agent_example.md`: "FocusFlow" 프로젝트 구체적 예시
- **신뢰도**: 중간 (실전 가이드, 대규모 검증은 없지만 구체적이고 실용적)

---

## 대규모 분석

### 9. GitHub Blog — How to write a great agents.md
- **출처**: GitHub 공식 블로그 (2025-11-19)
- **URL**: https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
- **분석 규모**: 2,500개 이상의 agents.md 파일
- **사용된 패턴**: #4 (금지 사항 명시), #8 (커밋 규칙), #11 (스택·명령어 명시)
- **핵심 발견**:
  - "Never commit secrets"가 가장 흔한 유용한 제약
  - 성공적인 파일은 6개 영역을 커버: commands, testing, project structure, code style, git workflow, boundaries
  - 코드 예시 > 텍스트 설명
  - 구체적 스택 > 모호한 설명
- **신뢰도**: 높음 (GitHub 공식, 대규모 정량 분석)

---

## 도구/제품 문서

### 10. Claude Code — Checkpointing
- **출처**: Claude Code 공식 기능
- **기록**: shanraisshan/claude-code-best-practice (32K★)
- **URL**: https://github.com/shanraisshan/claude-code-best-practice
- **사용된 패턴**: #2 (git 기반 자동 checkpointing)
- **핵심**: 파일 편집마다 자동 git 체크포인트, Esc Esc 또는 /rewind로 되돌리기
- **신뢰도**: 높음 (제품 내장 기능)

---

## Anthropic 엔지니어링 블로그 (하네스 엔지니어링)

### 11. Effective Harnesses for Long-Running Agents
- **저자**: Justin Young (Anthropic)
- **발행일**: 2025-11-26
- **URL**: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- **코드**: https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding
- **사용된 하네스 패턴**: Initializer Agent, Coding Agent, Feature List (JSON), Progress File, Incremental Progress, 세션 시작 루틴
- **핵심 발견**:
  - 에이전트가 한 번에 모든 것을 하려 함 → feature list + 한 번에 하나만
  - 조기 완료 선언 → passes: false 플래그로 미완료 추적
  - 세션 간 맥락 손실 → progress file + git history
  - 기능 미검증 → e2e 테스트 도구(Puppeteer) 제공
- **신뢰도**: 높음 (Anthropic 공식, 코드 공개)

### 12. Harness Design for Long-Running Application Development
- **저자**: Prithvi Rajasekaran (Anthropic Labs)
- **발행일**: 2026-03-24
- **URL**: https://www.anthropic.com/engineering/harness-design-long-running-apps
- **사용된 하네스 패턴**: 3-Agent 아키텍처 (Planner/Generator/Evaluator), Sprint Contract, GAN 영감 평가 루프, Context Reset vs Compaction
- **핵심 발견**:
  - 자기 코드를 과대평가하는 문제 → Generator-Evaluator 분리
  - 평가 에이전트를 "의심 많게" 튜닝하는 게 생성 에이전트를 자기비판적으로 만드는 것보다 훨씬 쉬움
  - Sprint contract로 구현 전 완료 조건 사전 합의
  - Opus 4.5는 context anxiety가 적어서 context reset 불필요
- **신뢰도**: 높음 (Anthropic 공식, 포스트 1의 확장)
- **비고**: 6시간 $200 실험 (Solo 20분 $9 대비) — 하네스의 비용 대 품질 트레이드오프 시사

### 13. Effective Context Engineering for AI Agents
- **출처**: Anthropic 엔지니어링 블로그
- **URL**: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- **사용된 패턴**: Context rot, 시스템 프롬프트의 적정 고도, 도구 최소화, Just-in-Time Context, Progressive Disclosure
- **핵심 발견**:
  - Context rot: 토큰 수 증가 → 정보 회수 능력 감소
  - "good context engineering means finding the smallest possible set of high-signal tokens"
  - 도구 세트가 너무 크면 성능 저하
  - Just-in-Time 로딩이 전부 미리 넣는 것보다 효과적
- **신뢰도**: 높음 (Anthropic 공식)

### 14. My AI Adoption Journey
- **저자**: Mitchell Hashimoto (Ghostty 제작자, HashiCorp 공동창업자)
- **발행일**: 2026-02-05
- **URL**: https://mitchellh.com/writing/my-ai-adoption-journey
- **사용된 패턴**: 하네스 엔지니어링 정의 ("agent never makes that mistake again"), 계획/실행 분리, 검증 도구 제공
- **핵심**:
  - 6단계 AI 채택 여정 (Chatbot → Reproduce → End-of-Day → Slam Dunks → Harness → Always Running)
  - Step 5에서 "harness engineering" 용어를 (독자적으로) 사용
  - "anytime you find an agent makes a mistake, you take the time to engineer a solution such that the agent never makes that mistake again"
- **신뢰도**: 높음 (실제 Ghostty 프로젝트에서 적용, 구체적 경험 기반)

### 15. Skill Issue: Harness Engineering for Coding Agents
- **저자**: HumanLayer (Dex Horthy)
- **URL**: https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents
- **실제 코드 레포**: https://github.com/humanlayer/humanlayer (`CLAUDE.md` 실물 — 60줄 미만)
- **사용된 패턴**: 하네스 구성 요소 6가지 (AGENTS.md, MCP, Skills, Sub-agents, Hooks, Back-pressure), Context Firewall, MCP 도구 최소화
- **핵심 발견**:
  - `coding agent = AI model(s) + harness`
  - Harness engineering은 context engineering의 하위 집합
  - Sub-agents가 "context firewall"로 작동
  - ETH Zurich 연구: LLM 생성 AGENTS.md는 오히려 성능 저하 + 비용 20%↑
  - CLAUDE.md는 60줄 이하가 최적
  - MCP 도구 과다 → "dumb zone"에 빠짐
- **신뢰도**: 높음 (다수 엔터프라이즈 프로젝트에서 실전 경험)

### 16. How coding agents work (Agentic Engineering Patterns)
- **저자**: Simon Willison
- **URL**: https://simonwillison.net/guides/agentic-engineering-patterns/how-coding-agents-work/
- **사용된 패턴**: 하네스의 기본 정의 (LLM + system prompt + tools in a loop)
- **핵심**: "A coding agent is a piece of software that acts as a harness for an LLM"
- **신뢰도**: 높음 (Simon Willison — Django co-creator)

### 17. Karpathy의 "agentic engineering" 정의
- **저자**: Andrej Karpathy (OpenAI 공동창업자)
- **발행일**: 2026-02 (X 포스트)
- **참고 기사**: https://observer.com/2026/02/andrej-karpathy-new-term-ai-coding/
- **핵심**: "vibe coding" 폐기 → "agentic engineering" 제시
  - "programming via LLM agents is increasingly becoming a default workflow for professionals"
  - "Engineering emphasizes that there is an art and science and expertise to it"
- **신뢰도**: 높음 (용어 정의 수준, 실증 연구는 아님)

---

## 업계 표준/컨벤션

### 11. Keep a Changelog
- **URL**: https://keepachangelog.com/
- **사용**: CHANGELOG.md 형식 참고 (Added, Fixed, Changed, Removed)
- **비고**: 에이전틱 개발 특화는 아니지만, 변경 기록의 업계 표준

### 12. Conventional Commits
- **URL**: https://www.conventionalcommits.org/
- **사용**: #8의 커밋 메시지 형식 (`<type>(<scope>): <description>`)
- **비고**: 에이전틱 개발 이전부터 존재하는 업계 컨벤션

---

## 트렌딩/배경 소스

아래는 직접 패턴으로 추출하지 않았지만, 조사 과정에서 배경 맥락을 제공한 소스:

| 소스 | 브리핑 날짜 | 관련 내용 |
|------|-------------|-----------|
| shanraisshan/claude-code-best-practice | 2026-04-11 trends | Claude Code 베스트 프랙티스 전체 정리 |
| agentic-coding.github.io (6원칙 28실천) | 웹 조사 | Vibe Coding → Agentic Coding 원칙 프레임워크 |
| Anthropic — Quantifying Infrastructure Noise | 2026-04-11 trends | 인프라 설정이 벤치마크 수%p 흔들 수 있음 |
| Anthropic — Scaling Managed Agents | 2026-04-11 trends | 의사결정/실행 분리 아키텍처 |
| GLM-5: from Vibe Coding to Agentic Engineering | 2026-04-11 trends | arxiv 2602.15763, "vibe coding에서 agentic engineering으로" |
| RAGEN-2: Reasoning Collapse in Agentic RL | 2026-04-10 papers | 에이전트 RL의 template collapse 현상 |
| SEVerA: Verified Synthesis of Self-Evolving Agents | 2026-04-10 papers | 에이전트 코드의 형식 검증 |
| SkillClaw | 2026-04-12 papers | 스킬 자동 진화 프레임워크 |
| Combee | 2026-04-10 papers | 프롬프트 자동 개선 |

---

## 신뢰도 분류 기준

| 등급 | 기준 | 해당 소스 |
|------|------|-----------|
| **높음** | 대규모 실증 분석, 공식 제품 기능, 장기 운영 사례 | Agent READMEs 논문, GitHub Blog, Simon Willison, Claude Code, Blake Niemyjski |
| **중~높음** | 실제 프로덕션 운영, 구체적 수치, 다만 단일 사례 | Groff.dev |
| **중간** | 실전 가이드/프레임워크, 구체적이지만 대규모 검증 없음 | obviousworks, SkillClaw, Combee |
| **참고** | 업계 표준, 배경 맥락 | Keep a Changelog, Conventional Commits, 트렌딩 소스들 |

---

_이 소스 목록은 2026-04-12 기준이다. 에이전틱 개발 분야는 빠르게 변하므로 주기적으로 업데이트가 필요하다._
