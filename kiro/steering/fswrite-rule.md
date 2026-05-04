---
inclusion: always
---

# fsWrite 사용 규칙

## 스키마 (BLOCKING)

`fsWrite`는 정확히 두 필드만 받는다:

```
fsWrite({ path: string, text: string })
```

금지:
- 다른 필드명 사용: `content`, `body`, `data`, `contents`, `fileContent`, `value`
- `path`를 null/undefined/배열/객체로 전달
- `text`를 숫자/배열/객체로 전달

## 긴 파일은 분할

한 번의 `fsWrite`에 2,000자 이상(멀티바이트 문자 비율 50% 이상이면 1,500자 이상) 작성하지 않는다. 초과 시 다음 패턴을 사용한다:

1. `fsWrite({ path, text: <앞부분> })` — 파일 생성
2. `fsAppend({ path, text: <다음 부분> })` — 여러 번 반복

## 실패 시 대응

`Schema validation failed for action fsWrite, attempting to number coercion` 경고가 나타나면:

이 경고의 "number coercion" 문구는 무시한다. fsWrite에는 숫자 필드가 없어 coercion은 항상 무의미하다.

실제 원인은 다음 세 가지다:
- 필드명 오류 (`content` 같은 잘못된 이름)
- text가 분할 기준을 초과하여 스트리밍이 끊김
- `text`/`path`가 문자열이 아닌 타입

재시도 정책:
- 1회 실패 → 스키마와 분할 기준을 확인 후 1회 재시도
- 2회 연속 실패 → 같은 호출을 반복하지 않는다. 분할 패턴으로 전환하거나 대체 경로(`executePwsh`의 Set-Content 등)로 우회한다
- 3회 이상 같은 호출을 반복하면 `inputRequired` 개입 요청이 발생하여 세션이 멈춘다

같은 접근이 막히면 brute force로 반복하지 않는다. 대체 접근을 시도하거나 사용자에게 확인한다.

## 서브에이전트 파일 쓰기 프로토콜

서브에이전트가 결과를 메시지로 반환하면 Main 세션이 자동 요약·압축하여 원문이 손상된다.

- 서브에이전트: 결과는 파일로 저장한다 (`fsWrite`, 필요 시 `fsAppend`)
- 서브에이전트의 return 메시지: `"done"` 한 단어
- Main: 파일을 `readFile`로 직접 읽는다
- 병렬 실행 서브에이전트끼리 서로의 출력 파일을 참고하지 않는다 (독립성 유지)

## REMEMBER

`fsWrite`는 정확히 `{ path: string, text: string }` 두 필드만 받는다. 다른 필드명을 사용하지 않는다. 2,000자 이상은 분할한다. 2회 연속 실패 시 같은 호출을 반복하지 않는다.
