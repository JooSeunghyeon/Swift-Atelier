# Swift async let 형제 태스크의 실패 시 취소 동작과 await 순서 영향

Swift 구조적 동시성에서 `async let`으로 선언한 형제 태스크 중 하나가 실패할 때, 에러가 언제 관찰되는지와 미대기 자식 태스크의 암묵적 취소 동작을 측정한다. await 순서가 에러 전파 시점을 결정하고, 스코프를 빠져나갈 때 await하지 않은 async let은 암묵적으로 취소되어 완료를 대기한다는 점을 확인한다.

## 질문

1. `async let a`(느림, 300ms 후 성공)와 `async let b`(빠름, 10ms 후 throw)를 선언하고 `try await (a, b)` 또는 a를 먼저 await하면, b가 먼저 실패했는데도 a 대기가 끝난 뒤에야 에러가 관찰되는가? a는 취소되지 않고 끝까지 완료되는가?
2. 같은 구성에서 b를 먼저 await하면, 에러가 즉시(약 10ms) 전파되고 스코프를 빠져나갈 때 미대기 a는 암묵적으로 취소되며 그 취소 완료까지 기다리는가?
3. 한 번도 await하지 않은 `async let _ = ...` 또는 이름만 선언한 async let은 스코프 종료 시 암묵적으로 취소+대기되는가?
4. 두 자식이 모두 throw할 때, await 순서상 먼저 await한 쪽의 에러가 관찰되는가?
5. 둘 다 성공하면 결과를 정상적으로 합성할 수 있는가?
6. `withThrowingTaskGroup`은 async let과 달리 완료 순서로 첫 에러를 관찰하고 그룹을 빠져나갈 때 남은 자식을 취소하는가?

## 실행 방법

### 데모 실행

```bash
swiftc -swift-version 6 \
    src/SiblingFailureProbe.swift \
    src/main.swift \
    -o /tmp/sibling-demo && \
/tmp/sibling-demo
```

### 테스트 실행

```bash
./run-tests.sh
```

## 실제 실행 결과

### Swift 버전

```
Swift version 6.1.3 (swift-6.1.3-RELEASE)
Target: x86_64-unknown-linux-gnu
```

### 데모 출력

```
=== Swift async let 형제 태스크 실패 시 취소 동작 ===

시나리오 1: async let a(느림, 300ms) + b(빠름, 10ms throw) → try await (a, b)
예상: b가 먼저 실패하지만 a 대기 후에야 에러 관찰, a는 취소 안 됨
이벤트 순서: ["fail:throw", "slow:done", "caught"]
경과 시간: 300ms
에러: FastError

시나리오 2: async let a(느림) + b(빠름, throw) → b 먼저 await
예상: 에러 즉시 전파(~10ms), 미대기 a는 암묵적 취소
이벤트 순서: ["fail:throw", "slow:cancelled", "caught"]
경과 시간: 10ms
에러: FastError
주의: slow:cancelled는 함수 반환 후에 기록됨 (스코프 빠져나갈 때 대기)

시나리오 3: async let _ = ... (한 번도 await하지 않음)
예상: 스코프 종료 시 암묵적 취소+대기
이벤트 순서: ["body-end", "slow:cancelled"]
경과 시간: 0ms
결과: ("never", "awaited")

시나리오 4: 둘 다 throw, a 먼저 await
예상: a 대기 후 SlowError 관찰 (await 순서대로)
이벤트 순서: ["fail:throw", "slow:done", "caught"]
경과 시간: 300ms
에러: SlowError - slowFailed

시나리오 5: 둘 다 throw, b 먼저 await
예상: b 대기 후 FastError 관찰 (await 순서대로)
이벤트 순서: ["fail:throw", "slow:cancelled", "caught"]
경과 시간: 10ms
에러: FastError - fastFailed

시나리오 6: 둘 다 성공
이벤트 순서: ["fail:throw", "slow:done"]
경과 시간: 300ms
결과: ("slow-success", "fast-success")

시나리오 7: withThrowingTaskGroup 비교
예상: 완료 순서로 첫 에러 관찰, 그룹 throw 시 남은 자식 취소
이벤트 순서: ["fail:throw", "slow:cancelled", "caught"]
경과 시간: 10ms
에러: FastError

=== 결론 ===
- async let에서 await 순서가 에러 관찰 시점을 결정한다
- 먼저 await한 작업이 완료될 때까지 다른 작업의 에러는 관찰되지 않는다
- 스코프를 빠져나갈 때 미대기 async let은 암묵적으로 취소+대기된다
- withThrowingTaskGroup은 완료 순서로 첫 에러를 즉시 관찰하고 남은 자식을 취소한다
```

### 테스트 출력

```
=== Swift async let 형제 태스크 실패 시 취소 동작 테스트 ===

테스트 1: 느린 작업 먼저 await (a, b)
✓ 에러가 발생해야 함
✓ FastError여야 함 (실제: Optional<Error>)
✓ fail:throw 이벤트 있어야 함
✓ slow:done 이벤트 있어야 함 (취소 안 됨)
✓ caught 이벤트 있어야 함
✓ fail:throw가 slow:done보다 먼저 기록되어야 함
✓ slow:done이 caught보다 먼저 기록되어야 함
✓ 최소 250ms 이상이어야 함 (실제: 300ms)

테스트 2: 빠른 작업 먼저 await (b)
✓ 에러가 발생해야 함
✓ FastError여야 함
✓ fail:throw 이벤트 있어야 함
✓ caught 이벤트 있어야 함
✓ 200ms 미만이어야 함 (실제: 10ms)

테스트 3: 한 번도 await하지 않음
✓ 에러가 없어야 함
✓ 결과가 있어야 함
✓ body-end 이벤트 있어야 함
✓ slow:cancelled 이벤트 있어야 함 (암묵적 취소)
✓ body-end가 slow:cancelled보다 먼저 기록되어야 함

테스트 4: 둘 다 throw, 느린 작업 먼저 await
✓ 에러가 발생해야 함
✓ SlowError여야 함 (await 순서대로, 실제: Optional<Error>)
✓ slow:done 이벤트 있어야 함
✓ fail:throw 이벤트 있어야 함
✓ 최소 250ms 이상이어야 함 (실제: 300ms)

테스트 5: 둘 다 throw, 빠른 작업 먼저 await
✓ 에러가 발생해야 함
✓ FastError여야 함 (await 순서대로)
✓ fail:throw 이벤트 있어야 함
✓ 200ms 미만이어야 함 (실제: 10ms)

테스트 6: 둘 다 성공
✓ 에러가 없어야 함
✓ 결과가 있어야 함
✓ slow-success여야 함 (실제: slow-success)
✓ fast-success여야 함 (실제: fast-success)
✓ slow:done 이벤트 있어야 함

테스트 7: withThrowingTaskGroup
✓ 에러가 발생해야 함
✓ FastError여야 함 (완료 순서)
✓ fail:throw 이벤트 있어야 함
✓ slow:cancelled 이벤트 있어야 함 (그룹 취소)
✓ 200ms 미만이어야 함 (실제: 10ms)

===================
통과: 37
실패: 0
===================
```

테스트를 5회 연속 실행하여 플래키 여부를 확인한 결과, 모든 실행에서 통과: 37, 실패: 0으로 일관된 결과를 보였다.

### 뮤테이션 테스트 결과

**뮤테이션 1**: `scenario1AwaitBothSlowFirst`에서 `try await (a, b)` 대신 `b`를 먼저 await하도록 변경

```swift
let bResult = try await b
let aResult = try await a
return (aResult, bResult)
```

결과: 테스트 실패 (통과: 33, 실패: 2, exit code: 1)
- "slow:done 이벤트 있어야 함" 실패 (slow:cancelled가 기록됨)
- "최소 250ms 이상" 조건 실패 (실제: 10ms)

**뮤테이션 2**: `slowOperation`에서 `CancellationError` catch 블록의 `await log.record("slow:cancelled")` 제거

결과: 테스트 실패 (통과: 34, 실패: 2, exit code: 1)
- 테스트 3 "slow:cancelled 이벤트 있어야 함" 실패
- 테스트 7 "slow:cancelled 이벤트 있어야 함" 실패

두 뮤테이션 모두 테스트를 exit code 1로 실패시켜 테스트가 의도한 동작을 올바르게 검증함을 확인했다.

## 헷갈리는 점

### 1. async let의 await 순서가 에러 관찰 시점을 결정한다

`async let a`와 `async let b`를 선언하고 b가 먼저 실패해도, a를 먼저 await하면 b의 에러는 a의 완료 후에야 관찰된다. 이는 async let이 선언 순서가 아닌 **await 순서**로 에러를 전파하기 때문이다.

```swift
async let a = slowOperation()  // 300ms 소요
async let b = fastOperation()  // 10ms 후 throw

// a를 먼저 await하면 300ms 후 b의 에러 관찰
try await (a, b)  // 또는 let aResult = try await a; let bResult = try await b

// b를 먼저 await하면 10ms 후 즉시 에러 관찰, a는 암묵적 취소
let bResult = try await b  // 여기서 에러 전파
let aResult = try await a  // 도달하지 않음
```

### 2. 먼저 await한 작업은 취소되지 않고 완료된다

시나리오 1에서 b가 먼저 실패하지만, a를 먼저 await했으므로 a는 취소되지 않고 300ms 동안 끝까지 실행되어 완료된다. 로그는 `fail:throw → slow:done → caught` 순서로 기록되며, 경과 시간은 300ms이다.

이는 async let이 "먼저 await한 작업의 완료를 기다린 후 다음 작업의 결과를 확인한다"는 순차적 의미론을 따르기 때문이다.

### 3. 스코프 종료 시 미대기 async let의 암묵적 취소+대기

async let을 선언했지만 한 번도 await하지 않으면(또는 에러로 인해 await에 도달하지 못하면), 스코프를 빠져나갈 때 해당 태스크는 암묵적으로 취소되고 그 완료를 대기한다.

```swift
async let a = slowOperation()
async let b = fastOperation()
let bResult = try await b  // 에러 발생
// a는 await되지 않았으므로 스코프 종료 시 암묵적 취소+대기
// 함수 반환 전에 a의 취소 완료까지 기다림
```

시나리오 2의 로그에서 `slow:cancelled`는 함수가 반환된 후에 actor에서 읽을 수 있다. 이는 에러 전파 후 스코프 종료 과정에서 a의 취소와 대기가 일어나기 때문이다.

### 4. 둘 다 throw할 때는 await 순서상 먼저 대기한 쪽의 에러가 관찰된다

두 자식 태스크가 모두 throw하더라도, 먼저 await한 작업의 에러만 관찰된다. 시나리오 4(a 먼저 await)는 300ms 후 `SlowError`를, 시나리오 5(b 먼저 await)는 10ms 후 `FastError`를 각각 관찰한다.

이는 Swift가 한 스코프에서 하나의 에러만 전파하며, 먼저 await한 작업의 완료(성공 또는 실패)를 확인한 후 다음으로 진행하기 때문이다.

### 5. withThrowingTaskGroup과의 차이

`withThrowingTaskGroup`은 **완료 순서**로 첫 에러를 관찰하고, 그룹을 빠져나갈 때 남은 자식을 취소한다. 시나리오 7에서 빠른 작업(10ms)이 먼저 실패하면 즉시 에러가 전파되고, 느린 작업은 취소된다.

```swift
try await withThrowingTaskGroup(of: String.self) { group in
    group.addTask { try await slowOperation() }
    group.addTask { try await fastOperation() }
    for try await result in group {  // 완료 순서대로 순회
        // 첫 에러 즉시 관찰, 그룹 throw로 빠져나감 → 남은 자식 취소
    }
}
```

이는 async let의 await 순서 의미론과 대조적이다. async let은 명시적 await 순서를 따르지만, TaskGroup은 동적 완료 순서를 따른다.

### 6. 이벤트 로그 수집 시점

로그를 스코프 안에서 읽으면 암묵적 취소가 완료되기 전이므로 `slow:cancelled`가 보이지 않을 수 있다. 시나리오 2와 3에서 `slow:cancelled`가 기록되려면 함수가 완전히 반환된 후 actor의 이벤트를 읽어야 한다.

테스트는 이 점을 고려하여 `measureScenario` 함수가 에러를 catch한 후 모든 암묵적 대기가 끝난 뒤에 로그를 조회한다.

## 왜 확인했는지

Swift 공식 문서는 async let의 구조적 동시성을 설명하지만, 형제 태스크 간 실패 전파의 타이밍과 await 순서의 영향을 구체적인 로그와 경과 시간으로 보여주지 않는다. 특히 다음 질문들이 헷갈린다:

- 한 자식이 먼저 실패하면 다른 자식은 즉시 취소되는가, 아니면 await 순서에 따라 다른가?
- 미대기 async let은 정확히 언제 취소+대기되는가?
- 두 자식이 모두 실패하면 어느 에러가 관찰되는가?
- withThrowingTaskGroup과 async let의 에러 전파 동작이 어떻게 다른가?

이 예제는 Swift 6.1.3 Linux에서 직접 프로브하여, await 순서가 에러 관찰 시점을 결정하고, 먼저 await한 작업은 취소되지 않으며, 미대기 async let은 스코프 종료 시 암묵적으로 취소+대기된다는 점을 로그 순서와 경과 시간으로 증명한다.
