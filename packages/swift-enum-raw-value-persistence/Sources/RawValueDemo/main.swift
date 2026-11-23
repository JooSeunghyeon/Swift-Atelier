import Foundation
import RawValuePersistence

print("=== Swift enum rawValue 영속성 호환 테스트 ===")
print()

// 1. ImplicitV1과 ImplicitV2 rawValue 비교
print("1. 암묵적 Int rawValue (중간 삽입 시 밀림)")
print("ImplicitV1.allCases.map(\\.rawValue): \(ImplicitV1.allCases.map(\.rawValue))")
print("ImplicitV2.allCases.map(\\.rawValue): \(ImplicitV2.allCases.map(\.rawValue))")
print()

// 2. ImplicitV1에서 저장한 값을 ImplicitV2로 해석
print("2. 암묵적 rawValue 마이그레이션 드리프트")
let implicitV1Stored: [Int] = [0, 1, 2]
let implicitDrifts = analyzeImplicitMigrationDrift(storedV1RawValues: implicitV1Stored)
print("v1 저장값 [0, 1, 2]를 v2로 해석:")
for drift in implicitDrifts {
    print("  raw \(drift.rawValue): v1=\(drift.v1Name ?? "nil") → v2=\(drift.v2Name ?? "nil")")
}
print()

// 3. ExplicitV1과 ExplicitV2 rawValue 비교
print("3. 명시적 Int rawValue (안정적)")
print("ExplicitV1 rawValues: low=\(ExplicitV1.low.rawValue), medium=\(ExplicitV1.medium.rawValue), high=\(ExplicitV1.high.rawValue)")
print("ExplicitV2.allCases.map(\\.rawValue): \(ExplicitV2.allCases.map(\.rawValue))")
print()

// 4. ExplicitV1에서 저장한 값을 ExplicitV2로 해석
print("4. 명시적 rawValue 마이그레이션 (드리프트 없음)")
let explicitV1Stored: [Int] = [0, 1, 2]
let explicitDrifts = analyzeExplicitMigrationDrift(storedV1RawValues: explicitV1Stored)
print("v1 저장값 [0, 1, 2]를 v2로 해석:")
if explicitDrifts.isEmpty {
    print("  드리프트 없음 (모든 값이 같은 의미 유지)")
} else {
    for drift in explicitDrifts {
        print("  raw \(drift.rawValue): v1=\(drift.v1Name ?? "nil") → v2=\(drift.v2Name ?? "nil")")
    }
}
print()

// 5. StringV1과 StringV2 rawValue 비교
print("5. 문자열 rawValue (항상 안정적)")
print("StringV1 rawValues: low=\"\(StringV1.low.rawValue)\", medium=\"\(StringV1.medium.rawValue)\", high=\"\(StringV1.high.rawValue)\"")
print("StringV2.allCases.map(\\.rawValue): \(StringV2.allCases.map(\.rawValue))")
print()

// 6. StringV1에서 저장한 값을 StringV2로 해석
print("6. 문자열 rawValue 마이그레이션 (드리프트 없음)")
let stringV1Stored: [String] = ["low", "medium", "high"]
let stringDrifts = analyzeStringMigrationDrift(storedV1RawValues: stringV1Stored)
print("v1 저장값 [\"low\", \"medium\", \"high\"]를 v2로 해석:")
if stringDrifts.isEmpty {
    print("  드리프트 없음 (모든 값이 같은 의미 유지)")
} else {
    for drift in stringDrifts {
        print("  raw \"\(drift.rawValue)\": v1=\(drift.v1Name ?? "nil") → v2=\(drift.v2Name ?? "nil")")
    }
}
print()

// 7. CaseIterable allCases 순서와 rawValue 정렬 순서 비교
print("7. ExplicitV2 allCases 순서 vs rawValue 정렬 순서")
let (allCasesOrder, sortedOrder) = compareAllCasesWithSortedRawValues()
print("allCases 순서: \(allCasesOrder)")
print("정렬된 순서: \(sortedOrder)")
print("순서가 다름: \(allCasesOrder != sortedOrder)")
print()

// 8. StoredPriority unknown 보존
print("8. StoredPriority unknown 보존 설계")
let unknownValues: [Int] = [99, -1, Int.max, 0, 1, 2, 3]
for raw in unknownValues {
    let stored = StoredPriority(rawValue: raw)
    let knownName = stored.known.map { "\($0)" } ?? "unknown"
    print("StoredPriority(rawValue: \(raw)): known=\(knownName), rawValue=\(stored.rawValue)")
}
print()

// 9. JSON 디코딩 비교
print("9. JSON 디코딩 (enum vs StoredPriority)")
let testJSON = #"{"priority":99}"#
print("JSON: \(testJSON)")

struct PriorityEnumWrapper: Codable {
    let priority: ExplicitV2
}
struct PriorityStoredWrapper: Codable {
    let priority: StoredPriority
}

do {
    let decoded = try decodeFromJSON(testJSON, as: PriorityEnumWrapper.self)
    print("ExplicitV2 디코딩: 성공 (\(decoded.priority))")
} catch {
    print("ExplicitV2 디코딩: 실패 (DecodingError)")
}

do {
    let decoded = try decodeFromJSON(testJSON, as: PriorityStoredWrapper.self)
    print("StoredPriority 디코딩: 성공 (rawValue=\(decoded.priority.rawValue), known=\(decoded.priority.known.map { "\($0)" } ?? "nil"))")
} catch {
    print("StoredPriority 디코딩: 실패")
}
print()

// 10. StoredPriority round-trip
print("10. StoredPriority JSON round-trip")
let testValues: [Int] = [99, -1, 0, 3]
for raw in testValues {
    let original = StoredPriority(rawValue: raw)
    if let json = try? encodeToJSON(["priority": original]),
       let decoded = try? decodeFromJSON(json, as: [String: StoredPriority].self),
       let restored = decoded["priority"] {
        print("raw \(raw): 원본=\(original.rawValue), 복원=\(restored.rawValue), 일치=\(original == restored)")
    }
}
print()

print("=== 테스트 완료 ===")
