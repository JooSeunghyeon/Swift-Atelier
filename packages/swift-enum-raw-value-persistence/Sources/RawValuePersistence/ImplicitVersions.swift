import Foundation

/// 스키마 v1: 암묵적 Int rawValue (low=0, medium=1, high=2)
public enum ImplicitV1: Int, CaseIterable, Codable, Sendable {
    case low
    case medium
    case high
}

/// 스키마 v2: critical을 중간에 삽입 → rawValue가 밀림 (low=0, critical=1, medium=2, high=3)
public enum ImplicitV2: Int, CaseIterable, Codable, Sendable {
    case low
    case critical
    case medium
    case high
}

/// 암묵적 rawValue 마이그레이션 드리프트 분석
public struct ImplicitMigrationDrift: Equatable, Sendable {
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
public func analyzeImplicitMigrationDrift(storedV1RawValues: [Int]) -> [ImplicitMigrationDrift] {
    var drifts: [ImplicitMigrationDrift] = []
    
    for raw in storedV1RawValues {
        let v1Case = ImplicitV1(rawValue: raw)
        let v2Case = ImplicitV2(rawValue: raw)
        
        let v1Name = v1Case.map { "\($0)" }
        let v2Name = v2Case.map { "\($0)" }
        
        if v1Name != v2Name {
            drifts.append(ImplicitMigrationDrift(rawValue: raw, v1Name: v1Name, v2Name: v2Name))
        }
    }
    
    return drifts
}
