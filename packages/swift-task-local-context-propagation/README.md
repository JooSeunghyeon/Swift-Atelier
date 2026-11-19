# Swift TaskLocal 컨텍스트 전파

## 목적

Swift의 `@TaskLocal` 속성 래퍼를 사용한 요청별 컨텍스트(예: requestID)가 구조화된 동시성 환경에서 어디까지 전파되고 어디서 끊기는지를 직접 관찰하고, 끊기는 지점을 처리하는 설계 패턴을 비교한다.

## 개념

`@TaskLocal`은 태스크 계층 구조를 따라 암묵적으로 전파되는 값을 저장하는 메커니즘이다. `withValue(_:operation:)` 메서드로 특정 범위 안에서 값을 바인딩하면, 그 범위 안에서 생성된 구조화된 자식 태스크(`async let`, `Task { }`, `withTaskGroup`)는 부모의 TaskLocal 값을 자동으로 상속한다. 하지만 분리된 태스크(`Task.detached`)나 클로저로 저장된 콜백은 이 전파 경로 밖에 있다.

## 시나리오별 관찰 결과

| 시나리오 | 전파 여부 | 설명 |
|---------|----------|------|
| 기본값 (바인딩 없음) | - | nil 반환, 폴백 로직으로 "unknown" 표시 |
| `withValue` 범위 안 | ✅ 전파 | 바인딩된 값 읽기 가능 |
| `withValue` 범위 밖 | ❌ 복원 | 범위 종료 후 nil로 복원 |
| `async let` 자식 | ✅ 전파 | 부모 컨텍스트 상속 |
| `Task { }` 자식 | ✅ 전파 | 부모 컨텍스트 상속 |
| `Task.detached` | ❌ 끊김 | 부모 컨텍스트를 상속하지 않음 |
| `withTaskGroup` 자식 | ✅ 전파 | 모든 자식이 부모 컨텍스트 상속 |
| 중첩 `withValue` 안쪽 | ✅ 전파 | 가장 안쪽 바인딩 값 |
| 중첩 `withValue` 종료 후 | ✅ 복원 | 바깥쪽 바인딩 값으로 복원 |
| `Task` 생성 후 범위 종료 | ✅ 유지 | 생성 시점 컨텍스트를 Task가 유지 |
| 저장된 콜백 (등록 시점 컨텍스트) | ❌ 끊김 | 호출 시점 컨텍스트를 읽음 |
| 동시 여러 요청 | ✅ 격리 | 각 요청의 컨텍스트가 섞이지 않음 |

## 실패 사례: 저장된 콜백

이벤트 버스나 핸들러 레지스트리에 클로저를 저장할 때, 클로저가 등록 시점의 TaskLocal 값을 자동으로 캡처하지 않는다. 대신 클로저가 실행되는 시점의 TaskLocal 값을 읽는다.

```swift
let bus = EventBus()

await RequestContext.$requestID.withValue("A") {
    await bus.register(event: "test") {
        currentContextLog()  // 등록 시점에는 "A"
    }
}

// 컨텍스트 없는 곳에서 호출
let result = await bus.trigger(event: "test")
// 결과: "RequestID: unknown" (등록 시점 "A"가 아님)

// 다른 컨텍스트에서 호출
let result2 = await RequestContext.$requestID.withValue("C") {
    await bus.trigger(event: "test")
}
// 결과: "RequestID: C" (호출 시점 컨텍스트)
```

## 설계 비교

### (a) 명시적 캡처

등록 시점에 TaskLocal 값을 명시적으로 로컬 변수에 저장하고, 클로저가 그 변수를 캡처하도록 한다.

```swift
let capturedID = RequestContext.requestID
await bus.register(event: "test") {
    if let id = capturedID {
        return "RequestID: \(id)"
    } else {
        return "RequestID: unknown"
    }
}
```

**장점:**
- 간단하고 직관적
- 추가 래퍼 없음
- 성능 오버헤드 최소

**단점:**
- 여러 TaskLocal 값이 있을 때 모두 수동으로 캡처해야 함
- 일관성 유지가 어려움 (개발자가 놓칠 수 있음)

### (b) 재바인딩 래퍼

등록 시점의 TaskLocal 값을 저장하고, 실행 시 `withValue`로 재바인딩하는 래퍼 타입을 사용한다.

```swift
struct ContextPreservingHandler {
    private let savedRequestID: String?
    private let handler: @Sendable () async -> String
    
    init(handler: @escaping @Sendable () async -> String) {
        self.savedRequestID = RequestContext.requestID
        self.handler = handler
    }
    
    func execute() async -> String {
        await RequestContext.$requestID.withValue(savedRequestID) {
            await handler()
        }
    }
}
```

**장점:**
- 여러 TaskLocal 값을 일관되게 보존 가능
- 핸들러 내부에서 throw 해도 바깥 컨텍스트 복원 보장
- 타입 안전성

**단점:**
- 추가 래퍼 타입 필요
- 약간의 성능 오버헤드 (withValue 재바인딩 비용)

### (c) 명시적 인자

분리된 태스크에 필요한 값을 명시적으로 인자로 전달한다.

```swift
func detachedWithExplicitValue(requestID: String?) async -> String {
    await Task.detached {
        if let id = requestID {
            return "RequestID: \(id)"
        } else {
            return "RequestID: unknown"
        }
    }.value
}

// 사용
await RequestContext.$requestID.withValue("R") {
    await detachedWithExplicitValue(requestID: RequestContext.requestID)
}
```

**장점:**
- 명시적이고 추적 가능
- Task.detached에 적합
- 추가 타입 불필요

**단점:**
- 함수 시그니처에 컨텍스트 인자 추가
- 여러 값 전달 시 보일러플레이트 증가

## 성능 비교

벤치마크는 다음 세 가지 접근의 비용을 측정한다:

1. **TaskLocal 읽기**: `withValue` 범위 안에서 반복적으로 TaskLocal 값을 읽는다.
2. **명시 파라미터 전달**: 로컬 변수를 반복적으로 읽는다 (기준선).
3. **withValue 바인딩 반복**: 매번 새로운 `withValue` 범위를 만들고 값을 읽는다.

### 실제 측정 결과

**환경:** Swift 6.0.3 (Linux Ubuntu 24.04, x86_64)

```
=== TaskLocal 성능 비교 벤치마크 ===

TaskLocal 읽기 (100000회)
  소요 시간: 0.001732179 seconds
  평균: 1.732179e-08 seconds

명시 파라미터 전달 (100000회)
  소요 시간: 6.1e-08 seconds
  평균: 6.1e-13 seconds

withValue 바인딩 반복 (100000회)
  소요 시간: 0.009897606 seconds
  평균: 9.897606e-08 seconds
```

**관찰:**
- TaskLocal 읽기는 명시 파라미터 전달보다 약 28,000배 느리다.
- `withValue` 바인딩 반복은 TaskLocal 읽기보다 약 5.7배 더 느리다.
- 성능이 중요한 핫패스에서는 명시 캡처나 명시 파라미터 전달이 유리하다.
- 대부분의 일반적인 사용 사례에서는 TaskLocal의 편의성이 성능 비용을 상쇄한다.

**주의:** 측정 결과는 실행 환경(CPU, 메모리, Swift 버전)에 따라 달라질 수 있다.

## 실행 방법

### 테스트 실행

```bash
cd packages/swift-task-local-context-propagation
swift test
```

### 벤치마크 실행

```bash
cd packages/swift-task-local-context-propagation
swift run -c release TaskLocalBenchmark
```

## 테스트 결과 확인

**환경:** Swift 6.0.3 (Linux Ubuntu 24.04, x86_64)

모든 17개 테스트가 통과함을 확인했다:
- 기본값 nil에서 폴백 "unknown" 반환
- withValue 안에서 바인딩된 값 읽기
- withValue 범위 종료 후 nil 복원
- 중첩 withValue의 안쪽 값과 바깥 값 복원
- async let, Task{}, TaskGroup 자식들의 부모 컨텍스트 상속
- Task.detached는 부모 컨텍스트를 상속하지 않음
- Task 생성 후 범위 종료에도 생성 시점 값 유지
- 저장된 콜백이 호출 시점 컨텍스트를 읽는 실패 사례
- 명시 캡처 설계가 등록 시점 값 유지
- 재바인딩 래퍼가 등록 시점 값 유지
- 재바인딩 래퍼 안에서 throw 해도 바깥 값 복원
- detached에 명시 인자로 넘기기
- 동시 여러 요청에서 컨텍스트 값이 섞이지 않음

## 결론

`@TaskLocal`은 구조화된 동시성 환경에서 컨텍스트를 암묵적으로 전파하는 강력한 도구지만, 분리된 태스크나 저장된 콜백에서는 전파가 끊긴다. 이런 경우 명시적 캡처, 재바인딩 래퍼, 명시적 인자 전달 등의 설계 패턴을 선택해야 한다. 각 패턴은 복잡도, 유지보수성, 성능 간의 트레이드오프가 있으므로, 사용 사례에 맞는 접근을 선택해야 한다.
