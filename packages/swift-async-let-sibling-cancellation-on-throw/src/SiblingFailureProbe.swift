import Foundation

actor EventLog {
    private var events: [String] = []
    
    func record(_ message: String) {
        events.append(message)
    }
    
    func getEvents() -> [String] {
        return events
    }
}

enum SlowError: Error, Equatable {
    case slowFailed
}

enum FastError: Error, Equatable {
    case fastFailed
}

func slowOperation(log: EventLog, shouldThrow: Bool = false) async throws -> String {
    do {
        try await Task.sleep(for: .milliseconds(300))
        await log.record("slow:done")
        if shouldThrow {
            throw SlowError.slowFailed
        }
        return "slow-success"
    } catch is CancellationError {
        await log.record("slow:cancelled")
        throw CancellationError()
    }
}

func fastOperation(log: EventLog, shouldThrow: Bool = true) async throws -> String {
    do {
        try await Task.sleep(for: .milliseconds(10))
        if shouldThrow {
            await log.record("fail:throw")
            throw FastError.fastFailed
        } else {
            await log.record("fast:done")
            return "fast-success"
        }
    } catch is CancellationError {
        await log.record("fast:cancelled")
        throw CancellationError()
    }
}

struct ScenarioResult {
    let events: [String]
    let elapsedMs: Int64
    let error: (any Error)?
    let result: (String, String)?
}

func milliseconds(_ duration: Duration) -> Int64 {
    let seconds = duration.components.seconds
    let attoseconds = duration.components.attoseconds
    return seconds * 1000 + attoseconds / 1_000_000_000_000_000
}

func measureScenario(_ name: String, _ block: @Sendable (EventLog) async throws -> (String, String)) async -> ScenarioResult {
    let log = EventLog()
    let start = ContinuousClock.now
    
    do {
        let result = try await block(log)
        let elapsed = start.duration(to: .now)
        let elapsedMs = milliseconds(elapsed)
        let events = await log.getEvents()
        return ScenarioResult(events: events, elapsedMs: elapsedMs, error: nil, result: result)
    } catch {
        await log.record("caught")
        let elapsed = start.duration(to: .now)
        let elapsedMs = milliseconds(elapsed)
        let events = await log.getEvents()
        return ScenarioResult(events: events, elapsedMs: elapsedMs, error: error, result: nil)
    }
}

func scenario1AwaitBothSlowFirst(log: EventLog) async throws -> (String, String) {
    async let a = slowOperation(log: log)
    async let b = fastOperation(log: log)
    return try await (a, b)
}

func scenario2AwaitFastFirst(log: EventLog) async throws -> (String, String) {
    async let a = slowOperation(log: log)
    async let b = fastOperation(log: log)
    let bResult = try await b
    let aResult = try await a
    return (aResult, bResult)
}

func scenario3NeverAwait(log: EventLog) async throws -> (String, String) {
    async let _ = slowOperation(log: log)
    await log.record("body-end")
    return ("never", "awaited")
}

func scenario4BothThrowAwaitSlowFirst(log: EventLog) async throws -> (String, String) {
    async let a = slowOperation(log: log, shouldThrow: true)
    async let b = fastOperation(log: log, shouldThrow: true)
    return try await (a, b)
}

func scenario5BothThrowAwaitFastFirst(log: EventLog) async throws -> (String, String) {
    async let a = slowOperation(log: log, shouldThrow: true)
    async let b = fastOperation(log: log, shouldThrow: true)
    let bResult = try await b
    let aResult = try await a
    return (aResult, bResult)
}

func scenario6BothSucceed(log: EventLog) async throws -> (String, String) {
    async let a = slowOperation(log: log, shouldThrow: false)
    async let b = fastOperation(log: log, shouldThrow: false)
    return try await (a, b)
}

func scenario7TaskGroup(log: EventLog) async throws -> (String, String) {
    try await withThrowingTaskGroup(of: String.self) { group in
        group.addTask {
            try await slowOperation(log: log)
        }
        group.addTask {
            try await fastOperation(log: log)
        }
        
        var results: [String] = []
        for try await result in group {
            results.append(result)
        }
        if results.count >= 2 {
            return (results[0], results[1])
        } else {
            return (results.first ?? "", "")
        }
    }
}
