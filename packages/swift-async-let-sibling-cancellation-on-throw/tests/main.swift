import Foundation

@main
struct TestRunner {
    nonisolated static func main() async {
        var passedTests = 0
        var failedTests = 0
        
        func check(_ condition: Bool, _ message: String) {
            if condition {
                passedTests += 1
                print("✓ \(message)")
            } else {
                failedTests += 1
                print("✗ \(message)")
            }
        }
        
        print("=== Swift async let 형제 태스크 실패 시 취소 동작 테스트 ===\n")
        
        print("테스트 1: 느린 작업 먼저 await (a, b)")
        let result1 = await measureScenario("test1") { log in
            try await scenario1AwaitBothSlowFirst(log: log)
        }
        check(result1.error != nil, "에러가 발생해야 함")
        check(result1.error is FastError, "FastError여야 함 (실제: \(type(of: result1.error)))")
        check(result1.events.contains("fail:throw"), "fail:throw 이벤트 있어야 함")
        check(result1.events.contains("slow:done"), "slow:done 이벤트 있어야 함 (취소 안 됨)")
        check(result1.events.contains("caught"), "caught 이벤트 있어야 함")
        if let failIdx = result1.events.firstIndex(of: "fail:throw"),
           let slowIdx = result1.events.firstIndex(of: "slow:done"),
           let caughtIdx = result1.events.firstIndex(of: "caught") {
            check(failIdx < slowIdx, "fail:throw가 slow:done보다 먼저 기록되어야 함")
            check(slowIdx < caughtIdx, "slow:done이 caught보다 먼저 기록되어야 함")
        }
        check(result1.elapsedMs >= 250, "최소 250ms 이상이어야 함 (실제: \(result1.elapsedMs)ms)")
        print()
        
        print("테스트 2: 빠른 작업 먼저 await (b)")
        let result2 = await measureScenario("test2") { log in
            try await scenario2AwaitFastFirst(log: log)
        }
        check(result2.error != nil, "에러가 발생해야 함")
        check(result2.error is FastError, "FastError여야 함")
        check(result2.events.contains("fail:throw"), "fail:throw 이벤트 있어야 함")
        check(result2.events.contains("caught"), "caught 이벤트 있어야 함")
        check(result2.elapsedMs < 200, "200ms 미만이어야 함 (실제: \(result2.elapsedMs)ms)")
        print()
        
        print("테스트 3: 한 번도 await하지 않음")
        let result3 = await measureScenario("test3") { log in
            try await scenario3NeverAwait(log: log)
        }
        check(result3.error == nil, "에러가 없어야 함")
        check(result3.result != nil, "결과가 있어야 함")
        check(result3.events.contains("body-end"), "body-end 이벤트 있어야 함")
        check(result3.events.contains("slow:cancelled"), "slow:cancelled 이벤트 있어야 함 (암묵적 취소)")
        if let bodyIdx = result3.events.firstIndex(of: "body-end"),
           let cancelIdx = result3.events.firstIndex(of: "slow:cancelled") {
            check(bodyIdx < cancelIdx, "body-end가 slow:cancelled보다 먼저 기록되어야 함")
        }
        print()
        
        print("테스트 4: 둘 다 throw, 느린 작업 먼저 await")
        let result4 = await measureScenario("test4") { log in
            try await scenario4BothThrowAwaitSlowFirst(log: log)
        }
        check(result4.error != nil, "에러가 발생해야 함")
        check(result4.error is SlowError, "SlowError여야 함 (await 순서대로, 실제: \(type(of: result4.error)))")
        check(result4.events.contains("slow:done"), "slow:done 이벤트 있어야 함")
        check(result4.events.contains("fail:throw"), "fail:throw 이벤트 있어야 함")
        check(result4.elapsedMs >= 250, "최소 250ms 이상이어야 함 (실제: \(result4.elapsedMs)ms)")
        print()
        
        print("테스트 5: 둘 다 throw, 빠른 작업 먼저 await")
        let result5 = await measureScenario("test5") { log in
            try await scenario5BothThrowAwaitFastFirst(log: log)
        }
        check(result5.error != nil, "에러가 발생해야 함")
        check(result5.error is FastError, "FastError여야 함 (await 순서대로)")
        check(result5.events.contains("fail:throw"), "fail:throw 이벤트 있어야 함")
        check(result5.elapsedMs < 200, "200ms 미만이어야 함 (실제: \(result5.elapsedMs)ms)")
        print()
        
        print("테스트 6: 둘 다 성공")
        let result6 = await measureScenario("test6") { log in
            try await scenario6BothSucceed(log: log)
        }
        check(result6.error == nil, "에러가 없어야 함")
        check(result6.result != nil, "결과가 있어야 함")
        if let r = result6.result {
            check(r.0 == "slow-success", "slow-success여야 함 (실제: \(r.0))")
            check(r.1 == "fast-success", "fast-success여야 함 (실제: \(r.1))")
        }
        check(result6.events.contains("slow:done"), "slow:done 이벤트 있어야 함")
        print()
        
        print("테스트 7: withThrowingTaskGroup")
        let result7 = await measureScenario("test7") { log in
            try await scenario7TaskGroup(log: log)
        }
        check(result7.error != nil, "에러가 발생해야 함")
        check(result7.error is FastError, "FastError여야 함 (완료 순서)")
        check(result7.events.contains("fail:throw"), "fail:throw 이벤트 있어야 함")
        check(result7.events.contains("slow:cancelled"), "slow:cancelled 이벤트 있어야 함 (그룹 취소)")
        check(result7.elapsedMs < 200, "200ms 미만이어야 함 (실제: \(result7.elapsedMs)ms)")
        print()
        
        print("===================")
        print("통과: \(passedTests)")
        print("실패: \(failedTests)")
        print("===================")
        
        if failedTests > 0 {
            exit(1)
        }
    }
}
