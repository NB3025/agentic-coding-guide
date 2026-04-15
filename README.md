# Agentic Dev Guide

AI 코딩 에이전트(Kiro, Claude Code, Cursor 등)를 **자기 개선(self-improving) 개발 파트너**로 만들기 위한 실전 패턴 가이드.

> 에이전트에게 코드만 시키지 말고, **일하는 방법**을 가르쳐라.

## 왜 필요한가?

에이전트는 매 세션 stateless로 시작한다. 이전에 뭘 했는지, 뭘 실수했는지 기억하지 못한다.

이 가이드의 12가지 패턴을 적용하면:
- ✅ 반복 실수를 규칙으로 승격시킨다
- ✅ 세션 간 학습을 축적한다
- ✅ 스스로 리뷰하고 개선한다

## 12 Patterns

| # | 패턴 | 한줄 설명 | 단계 |
|---|------|----------|------|
| 1 | [Session Seeding](patterns/01-session-seeding.md) | git log로 컨텍스트 주입 | 세션 시작 |
| 2 | [Checkpointing](patterns/02-checkpointing.md) | 변경 전 현재 상태 저장 | 작업 중 |
| 3 | [Mistake → Rule](patterns/03-mistake-to-rule.md) | 반복 실수를 규칙으로 승격 | 사후 |
| 4 | [Boundaries](patterns/04-boundaries.md) | Always / Ask first / Never 3단계 | 셋업 |
| 5 | [Short Rules](patterns/05-short-rules.md) | 규칙은 짧고 구체적으로 | 셋업 |
| 6 | [Self-Review](patterns/06-self-review.md) | 완료 전 체크리스트 실행 | 완료 시 |
| 7 | [Git Bisect](patterns/07-git-bisect.md) | 문제 발생 시 이진 탐색 | 문제 시 |
| 8 | [Conventional Commits](patterns/08-conventional-commits.md) | 구조화된 커밋 메시지 | 작업 중 |
| 9 | [Doc Sync](patterns/09-doc-sync.md) | 코드 변경 시 문서도 업데이트 | 완료 시 |
| 10 | [History Hygiene](patterns/10-history-hygiene.md) | 커밋 히스토리 정리 | 사후 |
| 11 | [Stack Declaration](patterns/11-stack-declaration.md) | 기술 스택 명시 | 셋업 |
| 12 | [Security & Perf Guard](patterns/12-security-perf-guard.md) | 보안·성능 재검증 | 완료 시 |

## Self-Improvement Loop

12개 패턴의 핵심은 **피드백 루프**다:

```
작업 실행 → 셀프 리뷰 → 학습 기록 → 규칙 승격 → 다음 작업에 반영
    ↑                                                    │
    └────────────────────────────────────────────────────┘
```

## Quick Start — 도구별 구현

| 도구 | 가이드 | 상태 |
|------|--------|------|
| [Kiro](kiro/) | Steering 파일 + Hook 설정 | ✅ 완료 |
| [Claude Code](claude-code/) | CLAUDE.md + Hook 설정 | ✅ 완료 |
| Cursor | .cursorrules + 자동화 | 🔜 예정 |
| Windsurf | .windsurfrules | 🔜 예정 |

### Kiro 사용자
```bash
cp -r kiro/steering/ .kiro/steering/
cp kiro/hooks/*.kiro.hook .kiro/hooks/
```

### Claude Code 사용자
```bash
cp claude-code/CLAUDE.md ./CLAUDE.md
# 프로젝트에 맞게 수정
```

## Deep Dive — 연구 문서

패턴의 근거와 심층 분석이 궁금하다면:

| 문서 | 내용 |
|------|------|
| [01-verified-patterns.md](01-verified-patterns.md) | 12개 패턴 상세 — 소스 원문 인용 포함 |
| [02-pattern-relationships.md](02-pattern-relationships.md) | 패턴 간 연관성 분석 + 구성 의도 |
| [03-integration-guide.md](03-integration-guide.md) | Phase별 통합 적용 가이드 |
| [04-project-template.md](04-project-template.md) | 프로젝트에 바로 쓸 수 있는 템플릿 |
| [05-sources.md](05-sources.md) | 전체 참조 소스 목록 |
| [06-harness-engineering.md](06-harness-engineering.md) | 하네스 엔지니어링 (Anthropic) |
| [07-simulation-callbot.md](07-simulation-callbot.md) | 실전 시뮬레이션: LLM 콜봇 프로젝트 |
| [08-real-code-references.md](08-real-code-references.md) | 실제 프로덕션 코드 레퍼런스 |
| [09-anthropic-persona.md](09-anthropic-persona.md) | Anthropic 페르소나 분석 |

### 조사 배경

2026년 4월 기준, 에이전틱 개발 관련 주요 소스:

- **학술 논문**: Agent READMEs (arxiv 2511.12884), Combee (arxiv 2604.04247), SkillClaw (arxiv 2604.08377)
- **Anthropic 엔지니어링**: Effective Harnesses (2025-11), Harness Design (2026-03), Infrastructure Noise (2026-03)
- **실전 가이드**: Simon Willison의 Agentic Engineering Patterns, Groff.dev 3-Tier Architecture
- **대규모 분석**: GitHub Blog (2,500개 agents.md 분석), Agent READMEs 논문 (2,303개 컨텍스트 파일)

## 기여하기

- 새 도구 구현 추가 (Cursor, Windsurf 등)
- 패턴 개선 제안
- 실전 사례 공유

PR 환영합니다.

## License

MIT
