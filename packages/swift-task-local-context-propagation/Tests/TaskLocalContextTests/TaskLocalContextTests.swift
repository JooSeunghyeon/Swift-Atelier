import Testing
@testable import TaskLocalContext

@Suite("TaskLocal 컨텍스트 전파 테스트")
struct TaskLocalContextTests {
    
    @Test("기본값 nil에서 폴백 unknown 반환")
    func testDefaultNilFallback() async {
        let log = currentContextLog()
        #expect(log == "RequestID: unknown")
    }
    
    @Test("withValue 안에서 바인딩된 값 읽기")
    func testWithValueInside() async {
        let log = await readInsideWithValue()
        #expect(log == "RequestID: A")
    }
    
    @Test("withValue 범위 종료 후 nil 복원")
    func testWithValueOutside() async {
        let log = await readOutsideWithValue()
        #expect(log == "RequestID: unknown")
    }
    
    @Test("중첩 withValue 안쪽 값 읽기")
    func testNestedWithValueInner() async {
        let log = await readNestedWithValueInner()
        #expect(log == "RequestID: G")
    }
    
    @Test("중첩 withValue 종료 후 바깥 값 복원")
    func testNestedWithValueOuter() async {
        let log = await readNestedWithValueOuter()
        #expect(log == "RequestID: H")
    }
    
    @Test("async let 자식이 부모 컨텍스트 상속")
    func testAsyncLetInheritance() async {
        let log = await readInAsyncLet()
        #expect(log == "RequestID: B")
    }
    
    @Test("Task{} 자식이 부모 컨텍스트 상속")
    func testStructuredTaskInheritance() async {
        let log = await readInStructuredTask()
        #expect(log == "RequestID: C")
    }
    
    @Test("Task.detached는 부모 컨텍스트를 상속하지 않음")
    func testDetachedTaskNoInheritance() async {
        let log = await readInDetachedTask()
        #expect(log == "RequestID: unknown")
    }
    
    @Test("TaskGroup 자식들이 부모 컨텍스트 상속")
    func testTaskGroupInheritance() async {
        let logs = await readInTaskGroup()
        #expect(logs.count == 2)
        for log in logs {
            #expect(log == "RequestID: E")
        }
    }
    
    @Test("Task 생성 후 바깥 범위가 끝나도 생성 시점 값 유지")
    func testTaskPreservesCreationContext() async {
        let log = await taskPreservesCreationContext()
        #expect(log == "RequestID: J")
    }
    
    @Test("저장된 콜백은 호출 시점 컨텍스트를 읽음 - 컨텍스트 없음")
    func testStoredCallbackReadsCallSiteContext_NoContext() async {
        let bus = EventBus()
        
        await RequestContext.$requestID.withValue("K") {
            await bus.register(event: "test") {
                currentContextLog()
            }
        }
        
        let result = await bus.trigger(event: "test")
        #expect(result == "RequestID: unknown")
    }
    
    @Test("저장된 콜백은 호출 시점 컨텍스트를 읽음 - 다른 컨텍스트")
    func testStoredCallbackReadsCallSiteContext_DifferentContext() async {
        let bus = EventBus()
        
        await RequestContext.$requestID.withValue("L") {
            await bus.register(event: "test") {
                currentContextLog()
            }
        }
        
        let result = await RequestContext.$requestID.withValue("M") {
            await bus.trigger(event: "test")
        }
        #expect(result == "RequestID: M")
    }
    
    @Test("명시 캡처 설계는 등록 시점 값 유지")
    func testExplicitCapturePreservesRegistrationContext() async {
        let bus = EventBus()
        
        await RequestContext.$requestID.withValue("N") {
            await registerWithExplicitCapture(bus: bus, event: "test")
        }
        
        let result = await bus.trigger(event: "test")
        #expect(result == "RequestID: N")
    }
    
    @Test("재바인딩 래퍼는 등록 시점 값 유지")
    func testContextPreservingHandlerPreservesRegistrationContext() async {
        let handler = RequestContext.$requestID.withValue("O") {
            ContextPreservingHandler {
                currentContextLog()
            }
        }
        
        let result = await handler.execute()
        #expect(result == "RequestID: O")
    }
    
    @Test("throwing 래퍼는 에러 전파하며 등록 시점 값 유지하고 바깥 값 복원")
    func testThrowingContextPreservingHandlerRestoresContextOnThrow() async {
        let handler = RequestContext.$requestID.withValue("P") {
            ThrowingContextPreservingHandler {
                let observedID = currentContextLog()
                throw HandlerError(observedRequestID: observedID)
            }
        }
        
        let result = await RequestContext.$requestID.withValue("Q") {
            var caughtError: HandlerError?
            do {
                _ = try await handler.execute()
            } catch let error as HandlerError {
                caughtError = error
            } catch {
                // 예상치 못한 에러
            }
            let outerLog = currentContextLog()
            return (error: caughtError, outer: outerLog)
        }
        
        #expect(result.error?.observedRequestID == "RequestID: P")
        #expect(result.outer == "RequestID: Q")
    }
    
    @Test("detached에 명시 인자로 넘기기")
    func testDetachedWithExplicitValue() async {
        let result = await RequestContext.$requestID.withValue("R") {
            await detachedWithExplicitValue(requestID: RequestContext.requestID)
        }
        #expect(result == "RequestID: R")
    }
    
    @Test("동시 여러 요청에서 컨텍스트 값이 섞이지 않음")
    func testConcurrentRequestsDoNotMixContexts() async {
        let results = await withTaskGroup(of: (String, String).self) { group in
            for i in 1...5 {
                group.addTask {
                    let id = "Request-\(i)"
                    let log = await RequestContext.$requestID.withValue(id) {
                        try? await Task.sleep(for: .milliseconds(10))
                        return currentContextLog()
                    }
                    return (id, log)
                }
            }
            
            var collected: [(String, String)] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }
        
        #expect(results.count == 5)
        for (expectedID, actualLog) in results {
            #expect(actualLog == "RequestID: \(expectedID)")
        }
    }
}
