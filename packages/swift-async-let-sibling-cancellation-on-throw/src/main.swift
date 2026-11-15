print("=== Swift async let 형제 태스크 실패 시 취소 동작 ===\n")

print("시나리오 1: async let a(느림, 300ms) + b(빠름, 10ms throw) → try await (a, b)")
print("예상: b가 먼저 실패하지만 a 대기 후에야 에러 관찰, a는 취소 안 됨")
let result1 = await measureScenario("scenario1") { log in
    try await scenario1AwaitBothSlowFirst(log: log)
}
print("이벤트 순서: \(result1.events)")
print("경과 시간: \(result1.elapsedMs)ms")
if let error = result1.error {
    print("에러: \(type(of: error))")
} else {
    print("결과: \(result1.result!)")
}
print()

print("시나리오 2: async let a(느림) + b(빠름, throw) → b 먼저 await")
print("예상: 에러 즉시 전파(~10ms), 미대기 a는 암묵적 취소")
let result2 = await measureScenario("scenario2") { log in
    try await scenario2AwaitFastFirst(log: log)
}
print("이벤트 순서: \(result2.events)")
print("경과 시간: \(result2.elapsedMs)ms")
if let error = result2.error {
    print("에러: \(type(of: error))")
} else {
    print("결과: \(result2.result!)")
}
print("주의: slow:cancelled는 함수 반환 후에 기록됨 (스코프 빠져나갈 때 대기)")
print()

print("시나리오 3: async let _ = ... (한 번도 await하지 않음)")
print("예상: 스코프 종료 시 암묵적 취소+대기")
let result3 = await measureScenario("scenario3") { log in
    try await scenario3NeverAwait(log: log)
}
print("이벤트 순서: \(result3.events)")
print("경과 시간: \(result3.elapsedMs)ms")
if let error = result3.error {
    print("에러: \(type(of: error))")
} else {
    print("결과: \(result3.result!)")
}
print()

print("시나리오 4: 둘 다 throw, a 먼저 await")
print("예상: a 대기 후 SlowError 관찰 (await 순서대로)")
let result4 = await measureScenario("scenario4") { log in
    try await scenario4BothThrowAwaitSlowFirst(log: log)
}
print("이벤트 순서: \(result4.events)")
print("경과 시간: \(result4.elapsedMs)ms")
if let error = result4.error {
    print("에러: \(type(of: error)) - \(error)")
} else {
    print("결과: \(result4.result!)")
}
print()

print("시나리오 5: 둘 다 throw, b 먼저 await")
print("예상: b 대기 후 FastError 관찰 (await 순서대로)")
let result5 = await measureScenario("scenario5") { log in
    try await scenario5BothThrowAwaitFastFirst(log: log)
}
print("이벤트 순서: \(result5.events)")
print("경과 시간: \(result5.elapsedMs)ms")
if let error = result5.error {
    print("에러: \(type(of: error)) - \(error)")
} else {
    print("결과: \(result5.result!)")
}
print()

print("시나리오 6: 둘 다 성공")
let result6 = await measureScenario("scenario6") { log in
    try await scenario6BothSucceed(log: log)
}
print("이벤트 순서: \(result6.events)")
print("경과 시간: \(result6.elapsedMs)ms")
if let error = result6.error {
    print("에러: \(type(of: error))")
} else {
    print("결과: \(result6.result!)")
}
print()

print("시나리오 7: withThrowingTaskGroup 비교")
print("예상: 완료 순서로 첫 에러 관찰, 그룹 throw 시 남은 자식 취소")
let result7 = await measureScenario("scenario7") { log in
    try await scenario7TaskGroup(log: log)
}
print("이벤트 순서: \(result7.events)")
print("경과 시간: \(result7.elapsedMs)ms")
if let error = result7.error {
    print("에러: \(type(of: error))")
} else {
    print("결과: \(result7.result!)")
}
print()

print("=== 결론 ===")
print("- async let에서 await 순서가 에러 관찰 시점을 결정한다")
print("- 먼저 await한 작업이 완료될 때까지 다른 작업의 에러는 관찰되지 않는다")
print("- 스코프를 빠져나갈 때 미대기 async let은 암묵적으로 취소+대기된다")
print("- withThrowingTaskGroup은 완료 순서로 첫 에러를 즉시 관찰하고 남은 자식을 취소한다")
