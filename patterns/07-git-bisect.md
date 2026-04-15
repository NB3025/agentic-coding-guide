# Pattern 7: Git Bisect

## 문제

"어디서부터 망가졌지?" — 에이전트가 여러 커밋을 한 뒤 문제를 발견하면 하나씩 되돌려보느라 시간을 낭비한다.

## 해결

`git bisect`로 **이진 탐색**한다. O(n) → O(log n).

## 방법

```bash
git bisect start
git bisect bad              # 현재가 깨진 상태
git bisect good abc1234     # 마지막으로 정상이던 커밋
# git이 중간 커밋을 체크아웃 → 테스트 → good/bad 반복
git bisect reset            # 완료 후 복구
```

## 자동화

```bash
git bisect start HEAD abc1234
git bisect run pytest tests/  # 테스트로 자동 판별
```

## 전제 조건

- Pattern 2 (Checkpointing)가 잘 되어 있어야 함
- 각 커밋이 빌드 가능한 상태여야 함
- 커밋 단위가 작을수록 효과적
