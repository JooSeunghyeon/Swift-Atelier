import Foundation

/// unknown 보존 설계: 알 수 없는 rawValue도 디코딩 실패 없이 보존
public struct StoredPriority: RawRepresentable, Codable, Equatable, Sendable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(_ known: ExplicitV2) {
        self.rawValue = known.rawValue
    }
    
    /// 알려진 case로 해석 (알 수 없으면 nil)
    public var known: ExplicitV2? {
        ExplicitV2(rawValue: rawValue)
    }
}
