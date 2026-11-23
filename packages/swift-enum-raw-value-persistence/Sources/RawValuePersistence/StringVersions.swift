import Foundation

/// 스키마 v1: 문자열 rawValue
public enum StringV1: String, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// 스키마 v2: critical 추가, 문자열 rawValue는 선언 순서와 무관하게 안정적
public enum StringV2: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case critical = "critical"
    case medium = "medium"
    case high = "high"
}

/// 문자열 rawValue 마이그레이션 드리프트 분석
public struct StringMigrationDrift: Equatable, Sendable {
    public let rawValue: String
    public let v1Name: String?
    public let v2Name: String?
    
    public init(rawValue: String, v1Name: String?, v2Name: String?) {
        self.rawValue = rawValue
        self.v1Name = v1Name
        self.v2Name = v2Name
    }
}

/// v1에서 저장한 rawValue 배열을 v2로 해석했을 때 의미가 바뀐 항목 보고
public func analyzeStringMigrationDrift(storedV1RawValues: [String]) -> [StringMigrationDrift] {
    var drifts: [StringMigrationDrift] = []
    
    for raw in storedV1RawValues {
        let v1Case = StringV1(rawValue: raw)
        let v2Case = StringV2(rawValue: raw)
        
        let v1Name = v1Case.map { "\($0)" }
        let v2Name = v2Case.map { "\($0)" }
        
        if v1Name != v2Name {
            drifts.append(StringMigrationDrift(rawValue: raw, v1Name: v1Name, v2Name: v2Name))
        }
    }
    
    return drifts
}
