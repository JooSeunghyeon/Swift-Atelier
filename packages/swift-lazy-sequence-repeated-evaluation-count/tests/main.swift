import Foundation

@main
struct TestRunner {
    static func main() {
        var passedTests = 0
        var failedTests = 0
        
        func check(_ condition: Bool, _ message: String) {
            if condition {
                passedTests += 1
                print("✓ \(message)")
            } else {
                failedTests += 1
                print("✗ \(message)")
            }
        }
        
        print("=== Swift lazy 시퀀스 평가 횟수 테스트 ===\n")
        
        let testArray = [1, 2, 3, 4, 5]
        
        // 테스트 1: Eager map은 생성 시점에 원소 수만큼 클로저 호출
        print("테스트 1: Eager map 평가")
        let (_, eagerCount) = measureEagerMap(array: testArray)
        check(eagerCount == testArray.count, "eager map은 배열 크기(\(testArray.count))만큼 호출되어야 함 (실제: \(eagerCount))")
        print()
        
        // 테스트 2: Lazy map 생성만으로는 0회 호출
        print("테스트 2: Lazy map 생성")
        let lazyCreationCount = measureLazyMapCreation(array: testArray)
        check(lazyCreationCount == 0, "lazy map 생성만으로는 0회 호출되어야 함 (실제: \(lazyCreationCount))")
        print()
        
        // 테스트 3: Lazy map 순회 시 원소 수만큼 호출
        print("테스트 3: Lazy map 순회")
        let (_, lazyIterCount) = measureLazyMapIteration(array: testArray)
        check(lazyIterCount == testArray.count, "lazy map 순회 시 배열 크기(\(testArray.count))만큼 호출되어야 함 (실제: \(lazyIterCount))")
        print()
        
        // 테스트 4: Lazy filter().map().first 단락 평가
        print("테스트 4: Lazy 단락 평가 (target: 3)")
        let (shortResult, filterCount, mapCount) = measureLazyShortCircuit(array: testArray, target: 3)
        check(shortResult == 6, "결과는 6이어야 함 (실제: \(shortResult ?? -1))")
        check(filterCount == 3, "filter는 첫 일치(3)까지 3회 호출되어야 함 (실제: \(filterCount))")
        check(mapCount == 1, "map은 1회만 호출되어야 함 (실제: \(mapCount))")
        print()
        
        // 테스트 5: target이 첫 원소일 때 최소 평가
        print("테스트 5: Lazy 단락 평가 (target: 1)")
        let (shortResult2, filterCount2, mapCount2) = measureLazyShortCircuit(array: testArray, target: 1)
        check(shortResult2 == 2, "결과는 2여야 함 (실제: \(shortResult2 ?? -1))")
        check(filterCount2 == 1, "filter는 1회만 호출되어야 함 (실제: \(filterCount2))")
        check(mapCount2 == 1, "map은 1회만 호출되어야 함 (실제: \(mapCount2))")
        print()
        
        // 테스트 6: 같은 lazy 시퀀스를 두 번 순회하면 재평가
        print("테스트 6: Lazy 재순회")
        let (firstIterCount, secondIterCount) = measureLazyRepeatedIteration(array: testArray)
        check(firstIterCount == testArray.count, "첫 순회는 배열 크기(\(testArray.count))만큼 호출되어야 함 (실제: \(firstIterCount))")
        check(secondIterCount == testArray.count, "두 번째 순회도 배열 크기(\(testArray.count))만큼 호출되어야 함 (실제: \(secondIterCount))")
        check(firstIterCount == secondIterCount, "두 순회의 호출 횟수가 같아야 함 (캐시 없음)")
        print()
        
        // 테스트 7: Lazy 인덱스 접근 시 재평가
        print("테스트 7: Lazy 인덱스 접근 (3번)")
        let indexAccessCount = measureLazyIndexAccess(array: testArray, index: 2, accessCount: 3)
        check(indexAccessCount == 3, "인덱스에 3번 접근 시 3회 호출되어야 함 (실제: \(indexAccessCount))")
        print()
        
        // 테스트 8: 물질화 후 접근은 재평가 없음
        print("테스트 8: Array 물질화 후 접근")
        let (materializeCount, totalCount) = measureMaterializedAccess(array: testArray, index: 2, accessCount: 3)
        check(materializeCount == testArray.count, "물질화 시 배열 크기(\(testArray.count))만큼 호출되어야 함 (실제: \(materializeCount))")
        check(totalCount == materializeCount, "물질화 후 추가 접근은 호출 없어야 함 (실제: \(totalCount))")
        print()
        
        // 테스트 9: 빈 배열에서 first는 nil이고 0회 호출
        print("테스트 9: 빈 배열")
        let (emptyResult, emptyCount) = measureLazyEmptyArray()
        check(emptyResult == nil, "빈 배열의 first는 nil이어야 함")
        check(emptyCount == 0, "빈 배열은 0회 호출되어야 함 (실제: \(emptyCount))")
        print()
        
        // 테스트 10: 일치하는 원소가 없으면 전체 평가
        print("테스트 10: 일치 원소 없음")
        let (noMatchResult, noMatchCount) = measureLazyNoMatch(array: testArray)
        check(noMatchResult == nil, "일치하는 원소가 없으면 nil이어야 함")
        check(noMatchCount == testArray.count, "일치하는 원소가 없으면 전체(\(testArray.count))를 평가해야 함 (실제: \(noMatchCount))")
        print()
        
        // 테스트 11: 큰 배열에서 단락 평가 효과 확인
        print("테스트 11: 큰 배열 단락 평가")
        let bigArray = Array(1...100)
        let (bigResult, bigFilterCount, bigMapCount) = measureLazyShortCircuit(array: bigArray, target: 50)
        check(bigResult == 100, "결과는 100이어야 함 (실제: \(bigResult ?? -1))")
        check(bigFilterCount == 50, "filter는 50회 호출되어야 함 (실제: \(bigFilterCount))")
        check(bigMapCount == 1, "map은 1회만 호출되어야 함 (실제: \(bigMapCount))")
        check(bigFilterCount < bigArray.count, "단락 평가로 전체(\(bigArray.count))보다 적게 평가해야 함")
        print()
        
        // 결과 출력
        print("===================")
        print("통과: \(passedTests)")
        print("실패: \(failedTests)")
        print("===================")
        
        if failedTests > 0 {
            exit(1)
        }
    }
}
