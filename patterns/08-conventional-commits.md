# Pattern 8: Conventional Commits

## 문제

`fix stuff`, `update`, `wip` — 커밋 메시지가 무의미하면 히스토리가 쓸모없어진다.

## 해결

**Conventional Commits** 형식을 강제한다.

## 형식

```
<type>(<scope>): <description>
```

### Type

| type | 용도 |
|------|------|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `test` | 테스트 추가/수정 |
| `refactor` | 기능 변경 없는 리팩토링 |
| `docs` | 문서 |
| `chore` | 빌드, 설정 등 |

### 예시

```
feat(auth): add JWT refresh token rotation
fix(api): handle null response from payment gateway
test(user): add edge case for duplicate email registration
refactor(db): extract connection pooling to shared module
```

## 왜?

- Pattern 1 (Session Seeding)에서 `git log`가 의미 있으려면 메시지가 좋아야 함
- Pattern 10 (History Hygiene)에서 squash 판단이 가능해짐
- changelog 자동 생성 가능
