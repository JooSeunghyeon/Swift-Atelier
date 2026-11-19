import Foundation

/// 콜백을 등록 시점에 저장하고 나중에 호출하는 이벤트 버스
/// 등록 시점이 아니라 호출 시점의 TaskLocal 값을 읽는 실패 사례
public actor EventBus {
    private var handlers: [String: @Sendable () async -> String] = [:]
    
    public init() {}
    
    /// 이벤트 핸들러 등록
    public func register(event: String, handler: @escaping @Sendable () async -> String) {
        handlers[event] = handler
    }
    
    /// 이벤트 발생 - 호출 시점의 컨텍스트에서 실행
    public func trigger(event: String) async -> String? {
        guard let handler = handlers[event] else {
            return nil
        }
        return await handler()
    }
    
    /// 모든 핸들러 제거
    public func clear() {
        handlers.removeAll()
    }
}

/// 등록 시점에 명시적으로 값을 캡처하는 설계
public func registerWithExplicitCapture(bus: EventBus, event: String) async {
    let capturedID = RequestContext.requestID
    await bus.register(event: event) {
        if let id = capturedID {
            return "RequestID: \(id)"
        } else {
            return "RequestID: unknown"
        }
    }
}

/// 등록 시점 값을 저장하고 호출 시 재바인딩하는 래퍼
public struct ContextPreservingHandler: Sendable {
    private let savedRequestID: String?
    private let handler: @Sendable () async -> String
    
    public init(handler: @escaping @Sendable () async -> String) {
        self.savedRequestID = RequestContext.requestID
        self.handler = handler
    }
    
    /// 저장된 컨텍스트 안에서 핸들러 실행
    public func execute() async -> String {
        await RequestContext.$requestID.withValue(savedRequestID) {
            await handler()
        }
    }
    
    /// 저장된 컨텍스트 안에서 핸들러 실행 (throwing 버전)
    public func executeThrows() async throws -> String {
        try await RequestContext.$requestID.withValue(savedRequestID) {
            await handler()
        }
    }
}

/// Task.detached에 값을 명시 인자로 넘기는 설계
public func detachedWithExplicitValue(requestID: String?) async -> String {
    await Task.detached {
        if let id = requestID {
            return "RequestID: \(id)"
        } else {
            return "RequestID: unknown"
        }
    }.value
}
