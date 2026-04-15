# Pattern 11: Stack Declaration

## 문제

에이전트가 프로젝트 기술 스택을 모르고 엉뚱한 라이브러리를 추천하거나, 잘못된 문법을 사용한다.

## 해결

프로젝트의 **기술 스택을 명시적으로 선언**한다.

## 예시

```markdown
## 기술 스택
- Language: TypeScript 5.x (strict mode)
- Runtime: Node.js 22
- Framework: Next.js 15 (App Router)
- DB: PostgreSQL 16 + Drizzle ORM
- Testing: Vitest + Testing Library
- Package Manager: pnpm
- Linter/Formatter: Biome
```

## 왜?

- 에이전트가 "Python이면 pip? uv? poetry?" 같은 추측을 안 해도 됨
- 버전이 명시되면 deprecated API 사용 방지
- 프로젝트 간 전환 시 혼동 방지

## 팁

- 버전까지 명시하면 효과 극대화
- 선호하는 패턴도 같이 적으면 좋음 (예: "상태 관리는 Zustand, Redux 사용 금지")
