import Foundation

/// 요청별 컨텍스트를 저장하는 TaskLocal 정의
public enum RequestContext {
    @TaskLocal
    public static var requestID: String?
}

/// 현재 컨텍스트의 requestID를 읽어 로그 문자열 반환
public func currentContextLog() -> String {
    if let id = RequestContext.requestID {
        return "RequestID: \(id)"
    } else {
        return "RequestID: unknown"
    }
}
