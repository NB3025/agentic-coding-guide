# Pattern 1: Session Seeding

## 문제

AI 에이전트는 매 세션마다 컨텍스트를 잃는다. 어제 뭘 했는지, 지금 어떤 상태인지 모른 채 시작한다.

## 해결

세션 시작 시 **자동으로 컨텍스트를 주입**한다.

## 방법

```bash
# 최소한 이 두 가지:
git log --oneline -15   # 최근 작업 흐름
git status              # 현재 상태
```

## 왜 15줄?

- 5줄: 너무 적다 — 어제 작업 맥락이 빠질 수 있음
- 15줄: 1~2일치 작업 흐름이 보통 들어감
- 50줄: 토큰 낭비, 핵심이 묻힘

## 확장

- `learnings.md` 최근 항목도 함께 로드하면 반복 실수 방지
- 미완료 TODO가 있으면 자동으로 다음 작업 추천

## 도구별 구현

- **Kiro**: Manual Trigger Hook (`/start`) → [kiro/README.md](../kiro/README.md)
- **Claude Code**: Hook (`PreToolUse` 또는 세션 시작 스크립트) → [claude-code/README.md](../claude-code/README.md)
