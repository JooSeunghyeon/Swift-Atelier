import Foundation

/// 스키마 v1: 명시적 Int rawValue
public enum ExplicitV1: Int, Codable, Sendable {
    case low = 0
    case medium = 1
    case high = 2
}

/// 스키마 v2: critical 추가, 명시 rawValue로 기존 값 보존 (선언 순서와 raw 값 순서가 다름)
public enum ExplicitV2: Int, CaseIterable, Codable, Sendable {
    case low = 0
    case critical = 3
    case medium = 1
    case high = 2
}

/// 명시적 rawValue 마이그레이션 드리프트 분석
public struct ExplicitMigrationDrift: Equatable, Sendable {
    public let rawValue: Int
    public let v1Name: String?
    public let v2Name: String?
    
    public init(rawValue: Int, v1Name: String?, v2Name: String?) {
        self.rawValue = rawValue
        self.v1Name = v1Name
        self.v2Name = v2Name
    }
}

/// v1에서 저장한 rawValue 배열을 v2로 해석했을 때 의미가 바뀐 항목 보고
public func analyzeExplicitMigrationDrift(storedV1RawValues: [Int]) -> [ExplicitMigrationDrift] {
    var drifts: [ExplicitMigrationDrift] = []
    
    for raw in storedV1RawValues {
        let v1Case = ExplicitV1(rawValue: raw)
        let v2Case = ExplicitV2(rawValue: raw)
        
        let v1Name = v1Case.map { "\($0)" }
        let v2Name = v2Case.map { "\($0)" }
        
        if v1Name != v2Name {
            drifts.append(ExplicitMigrationDrift(rawValue: raw, v1Name: v1Name, v2Name: v2Name))
        }
    }
    
    return drifts
}
