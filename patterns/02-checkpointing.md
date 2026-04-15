# Pattern 2: Checkpointing

## 문제

에이전트가 큰 변경을 하다 실패하면 되돌리기 어렵다.

## 해결

**변경 전 반드시 현재 상태를 커밋**한다. 실패해도 `git checkout`으로 즉시 복구.

## 방법

```bash
# 변경 시작 전
git add -A && git commit -m "checkpoint: before refactoring auth module"

# 실패 시
git checkout .
```

## 규칙

- 하나의 논리적 변경 = 하나의 커밋
- 체크포인트 커밋은 `checkpoint:` 접두어로 구분
- 작업 완료 후 squash 가능 (Pattern 10 참조)

## 안티패턴

- ❌ 여러 파일을 한꺼번에 바꾸고 커밋 안 함
- ❌ "나중에 한 번에 커밋하지" → 실패 시 복구 불가
