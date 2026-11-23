import Foundation

/// JSON 페이로드에서 타입 T로 디코딩
public func decodeFromJSON<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
    let data = Data(json.utf8)
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
}

/// 값을 JSON 문자열로 인코딩
public func encodeToJSON<T: Encodable>(_ value: T) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let data = try encoder.encode(value)
    return String(data: data, encoding: .utf8) ?? ""
}

/// ExplicitV2의 allCases 순서와 rawValue 정렬 순서 비교
public func compareAllCasesWithSortedRawValues() -> (allCasesOrder: [Int], sortedOrder: [Int]) {
    let allCasesOrder = ExplicitV2.allCases.map(\.rawValue)
    let sortedOrder = allCasesOrder.sorted()
    return (allCasesOrder, sortedOrder)
}
