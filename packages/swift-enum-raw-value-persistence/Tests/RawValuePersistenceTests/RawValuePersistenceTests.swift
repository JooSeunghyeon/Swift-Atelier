import Testing
import Foundation
@testable import RawValuePersistence

@Suite("enum rawValue 영속성 호환 테스트")
struct RawValuePersistenceTests {
    
    // MARK: - ImplicitV1/V2 테스트
    
    @Test("ImplicitV1 rawValue 확인")
    func testImplicitV1RawValues() {
        #expect(ImplicitV1.low.rawValue == 0)
        #expect(ImplicitV1.medium.rawValue == 1)
        #expect(ImplicitV1.high.rawValue == 2)
    }
    
    @Test("ImplicitV2 rawValue 확인 (중간 삽입으로 밀림)")
    func testImplicitV2RawValues() {
        #expect(ImplicitV2.low.rawValue == 0)
        #expect(ImplicitV2.critical.rawValue == 1)
        #expect(ImplicitV2.medium.rawValue == 2)
        #expect(ImplicitV2.high.rawValue == 3)
    }
    
    @Test("ImplicitV1의 raw 1(medium)이 ImplicitV2에서 critical로 해석됨")
    func testImplicitV1Raw1BecomesV2Critical() {
        let v1Medium = ImplicitV1.medium
        #expect(v1Medium.rawValue == 1)
        
        let v2Case = ImplicitV2(rawValue: 1)
        #expect(v2Case == .critical)
    }
    
    @Test("ImplicitV1의 raw 2(high)가 ImplicitV2에서 medium으로 해석됨")
    func testImplicitV1Raw2BecomesV2Medium() {
        let v1High = ImplicitV1.high
        #expect(v1High.rawValue == 2)
        
        let v2Case = ImplicitV2(rawValue: 2)
        #expect(v2Case == .medium)
    }
    
    @Test("raw 3은 ImplicitV1에서 nil, ImplicitV2에서 high")
    func testRaw3ImplicitV1NilV2High() {
        let v1Case = ImplicitV1(rawValue: 3)
        #expect(v1Case == nil)
        
        let v2Case = ImplicitV2(rawValue: 3)
        #expect(v2Case == .high)
    }
    
    @Test("ImplicitV1 저장값 [0,1,2]를 V2로 해석 시 드리프트 발생")
    func testImplicitMigrationDrift() {
        let drifts = analyzeImplicitMigrationDrift(storedV1RawValues: [0, 1, 2])
        
        #expect(drifts.count == 2)
        
        let drift1 = drifts.first { $0.rawValue == 1 }
        #expect(drift1?.v1Name == "medium")
        #expect(drift1?.v2Name == "critical")
        
        let drift2 = drifts.first { $0.rawValue == 2 }
        #expect(drift2?.v1Name == "high")
        #expect(drift2?.v2Name == "medium")
    }
    
    @Test("빈 배열 ImplicitMigrationDrift는 빈 결과")
    func testEmptyImplicitMigrationDrift() {
        let drifts = analyzeImplicitMigrationDrift(storedV1RawValues: [])
        #expect(drifts.isEmpty)
    }
    
    // MARK: - ExplicitV1/V2 테스트
    
    @Test("ExplicitV1 rawValue 확인")
    func testExplicitV1RawValues() {
        #expect(ExplicitV1.low.rawValue == 0)
        #expect(ExplicitV1.medium.rawValue == 1)
        #expect(ExplicitV1.high.rawValue == 2)
    }
    
    @Test("ExplicitV2 rawValue 확인 (명시 값으로 안정)")
    func testExplicitV2RawValues() {
        #expect(ExplicitV2.low.rawValue == 0)
        #expect(ExplicitV2.critical.rawValue == 3)
        #expect(ExplicitV2.medium.rawValue == 1)
        #expect(ExplicitV2.high.rawValue == 2)
    }
    
    @Test("ExplicitV1 저장값 0/1/2가 ExplicitV2에서도 같은 이름")
    func testExplicitMigrationStable() {
        #expect(ExplicitV2(rawValue: 0) == .low)
        #expect(ExplicitV2(rawValue: 1) == .medium)
        #expect(ExplicitV2(rawValue: 2) == .high)
    }
    
    @Test("ExplicitV1 저장값 [0,1,2]를 V2로 해석 시 드리프트 없음")
    func testExplicitMigrationNoDrift() {
        let drifts = analyzeExplicitMigrationDrift(storedV1RawValues: [0, 1, 2])
        #expect(drifts.isEmpty)
    }
    
    @Test("빈 배열 ExplicitMigrationDrift는 빈 결과")
    func testEmptyExplicitMigrationDrift() {
        let drifts = analyzeExplicitMigrationDrift(storedV1RawValues: [])
        #expect(drifts.isEmpty)
    }
    
    @Test("ExplicitV2 allCases 순서와 rawValue 정렬 순서가 다름")
    func testExplicitV2AllCasesOrderDifferentFromSorted() {
        let allCasesOrder = ExplicitV2.allCases.map(\.rawValue)
        let sortedOrder = allCasesOrder.sorted()
        
        #expect(allCasesOrder == [0, 3, 1, 2])
        #expect(sortedOrder == [0, 1, 2, 3])
        #expect(allCasesOrder != sortedOrder)
    }
    
    // MARK: - StringV1/V2 테스트
    
    @Test("StringV1 rawValue 확인")
    func testStringV1RawValues() {
        #expect(StringV1.low.rawValue == "low")
        #expect(StringV1.medium.rawValue == "medium")
        #expect(StringV1.high.rawValue == "high")
    }
    
    @Test("StringV2 rawValue 확인")
    func testStringV2RawValues() {
        #expect(StringV2.low.rawValue == "low")
        #expect(StringV2.critical.rawValue == "critical")
        #expect(StringV2.medium.rawValue == "medium")
        #expect(StringV2.high.rawValue == "high")
    }
    
    @Test("StringV1 저장값이 StringV2에서도 같은 의미 유지")
    func testStringMigrationStable() {
        #expect(StringV2(rawValue: "low") == .low)
        #expect(StringV2(rawValue: "medium") == .medium)
        #expect(StringV2(rawValue: "high") == .high)
    }
    
    @Test("StringV1 저장값 [low,medium,high]를 V2로 해석 시 드리프트 없음")
    func testStringMigrationNoDrift() {
        let drifts = analyzeStringMigrationDrift(storedV1RawValues: ["low", "medium", "high"])
        #expect(drifts.isEmpty)
    }
    
    @Test("빈 배열 StringMigrationDrift는 빈 결과")
    func testEmptyStringMigrationDrift() {
        let drifts = analyzeStringMigrationDrift(storedV1RawValues: [])
        #expect(drifts.isEmpty)
    }
    
    // MARK: - 경계값 테스트
    
    @Test("ExplicitV2 rawValue 음수는 nil 반환")
    func testExplicitV2NegativeRawValueReturnsNil() {
        #expect(ExplicitV2(rawValue: -1) == nil)
        #expect(ExplicitV2(rawValue: -100) == nil)
    }
    
    @Test("ExplicitV2 rawValue Int.max는 nil 반환")
    func testExplicitV2MaxRawValueReturnsNil() {
        #expect(ExplicitV2(rawValue: Int.max) == nil)
    }
    
    @Test("ExplicitV2 rawValue 99는 nil 반환")
    func testExplicitV2UnknownRawValue99ReturnsNil() {
        #expect(ExplicitV2(rawValue: 99) == nil)
    }
    
    // MARK: - StoredPriority 테스트
    
    @Test("StoredPriority는 알려진 rawValue를 known으로 해석")
    func testStoredPriorityKnownValues() {
        let low = StoredPriority(rawValue: 0)
        #expect(low.known == .low)
        
        let medium = StoredPriority(rawValue: 1)
        #expect(medium.known == .medium)
        
        let high = StoredPriority(rawValue: 2)
        #expect(high.known == .high)
        
        let critical = StoredPriority(rawValue: 3)
        #expect(critical.known == .critical)
    }
    
    @Test("StoredPriority는 알 수 없는 rawValue를 known=nil로 보존")
    func testStoredPriorityUnknownValues() {
        let unknown99 = StoredPriority(rawValue: 99)
        #expect(unknown99.rawValue == 99)
        #expect(unknown99.known == nil)
        
        let unknownNegative = StoredPriority(rawValue: -1)
        #expect(unknownNegative.rawValue == -1)
        #expect(unknownNegative.known == nil)
        
        let unknownMax = StoredPriority(rawValue: Int.max)
        #expect(unknownMax.rawValue == Int.max)
        #expect(unknownMax.known == nil)
    }
    
    @Test("StoredPriority JSON round-trip (99 보존)")
    func testStoredPriorityRoundTrip99() throws {
        let original = StoredPriority(rawValue: 99)
        let json = try encodeToJSON(original)
        let decoded = try decodeFromJSON(json, as: StoredPriority.self)
        
        #expect(decoded.rawValue == 99)
        #expect(decoded == original)
    }
    
    @Test("StoredPriority JSON round-trip (-1 보존)")
    func testStoredPriorityRoundTripNegative() throws {
        let original = StoredPriority(rawValue: -1)
        let json = try encodeToJSON(original)
        let decoded = try decodeFromJSON(json, as: StoredPriority.self)
        
        #expect(decoded.rawValue == -1)
        #expect(decoded == original)
    }
    
    @Test("StoredPriority JSON round-trip (Int.max 보존)")
    func testStoredPriorityRoundTripMax() throws {
        let original = StoredPriority(rawValue: Int.max)
        let json = try encodeToJSON(original)
        let decoded = try decodeFromJSON(json, as: StoredPriority.self)
        
        #expect(decoded.rawValue == Int.max)
        #expect(decoded == original)
    }
    
    @Test("StoredPriority JSON round-trip (알려진 값도 보존)")
    func testStoredPriorityRoundTripKnownValue() throws {
        let original = StoredPriority(rawValue: 0)
        let json = try encodeToJSON(original)
        let decoded = try decodeFromJSON(json, as: StoredPriority.self)
        
        #expect(decoded.rawValue == 0)
        #expect(decoded.known == .low)
        #expect(decoded == original)
    }
    
    // MARK: - JSON 디코딩 에러 테스트
    
    @Test("ExplicitV2를 알 수 없는 rawValue JSON으로 디코딩하면 DecodingError")
    func testExplicitV2DecodingErrorOnUnknownRawValue() {
        struct Wrapper: Codable {
            let priority: ExplicitV2
        }
        
        let json = #"{"priority":99}"#
        
        do {
            _ = try decodeFromJSON(json, as: Wrapper.self)
            Issue.record("디코딩이 성공하면 안 됨")
        } catch let error as DecodingError {
            if case .dataCorrupted = error {
                // 예상된 에러
            } else {
                Issue.record("dataCorrupted가 아닌 다른 DecodingError: \(error)")
            }
        } catch {
            Issue.record("DecodingError가 아닌 다른 에러: \(error)")
        }
    }
    
    @Test("StoredPriority는 알 수 없는 rawValue JSON도 디코딩 성공")
    func testStoredPriorityDecodingSuccessOnUnknownRawValue() throws {
        struct Wrapper: Codable {
            let priority: StoredPriority
        }
        
        let json = #"{"priority":99}"#
        let decoded = try decodeFromJSON(json, as: Wrapper.self)
        
        #expect(decoded.priority.rawValue == 99)
        #expect(decoded.priority.known == nil)
    }
    
    @Test("JSON 키 누락 시 DecodingError")
    func testDecodingErrorOnMissingKey() {
        struct Wrapper: Codable {
            let priority: ExplicitV2
        }
        
        let json = #"{}"#
        
        do {
            _ = try decodeFromJSON(json, as: Wrapper.self)
            Issue.record("디코딩이 성공하면 안 됨")
        } catch is DecodingError {
            // 예상된 에러
        } catch {
            Issue.record("DecodingError가 아닌 다른 에러: \(error)")
        }
    }
    
    // MARK: - 추가 경계 케이스
    
    @Test("중복 rawValue 입력 시 각각 독립적으로 처리")
    func testDuplicateRawValuesInMigrationDrift() {
        let drifts = analyzeImplicitMigrationDrift(storedV1RawValues: [1, 1, 2, 2])
        
        #expect(drifts.count == 4)
        
        let drift1Count = drifts.filter { $0.rawValue == 1 }.count
        #expect(drift1Count == 2)
        
        let drift2Count = drifts.filter { $0.rawValue == 2 }.count
        #expect(drift2Count == 2)
    }
    
    @Test("compareAllCasesWithSortedRawValues 반환값 확인")
    func testCompareAllCasesWithSortedRawValues() {
        let (allCasesOrder, sortedOrder) = compareAllCasesWithSortedRawValues()
        
        #expect(allCasesOrder == [0, 3, 1, 2])
        #expect(sortedOrder == [0, 1, 2, 3])
    }
    
    @Test("StoredPriority Equatable 구현 확인")
    func testStoredPriorityEquatable() {
        let a = StoredPriority(rawValue: 99)
        let b = StoredPriority(rawValue: 99)
        let c = StoredPriority(rawValue: 100)
        
        #expect(a == b)
        #expect(a != c)
    }
    
    @Test("StoredPriority init from ExplicitV2")
    func testStoredPriorityInitFromExplicitV2() {
        let stored = StoredPriority(.low)
        #expect(stored.rawValue == 0)
        #expect(stored.known == .low)
    }
}
