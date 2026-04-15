# Pattern 10: History Hygiene

## 문제

에이전트가 만든 커밋 히스토리가 지저분하다. checkpoint 커밋, 실패한 시도, 되돌린 커밋이 뒤섞여 있다.

## 해결

주기적으로 **히스토리를 정리**한다.

## 방법

```bash
# 대화형 rebase로 최근 10개 커밋 정리
git rebase -i HEAD~10
```

### 정리 기준

| 상황 | 액션 |
|------|------|
| checkpoint → 본 커밋 연속 | squash |
| 실패 시도 → 되돌림 연속 | drop (또는 squash) |
| 같은 기능의 여러 fix | squash |
| 의미 있는 단독 커밋 | 유지 |

## ⚠️ 주의

- `main` 브랜치에서 rebase 금지 (이미 push된 히스토리)
- 에이전트가 직접 실행하지 말고 **제안만** → 사람이 판단
- force push 필요 → 반드시 확인

## 타이밍

- 기능 브랜치 merge 전
- `/review` (사후 리뷰) 시점
