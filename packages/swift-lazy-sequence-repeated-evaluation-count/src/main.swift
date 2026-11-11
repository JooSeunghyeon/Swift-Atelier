print("=== Swift lazy 시퀀스 평가 횟수 측정 ===\n")

let testArray = [1, 2, 3, 4, 5]

// 1. Eager map: 생성 시점에 전체 평가
print("1. Eager map 평가")
let (eagerResult, eagerCount) = measureEagerMap(array: testArray)
print("   배열: \(testArray)")
print("   결과: \(eagerResult)")
print("   클로저 호출 횟수: \(eagerCount)")
print()

// 2. Lazy map: 생성만으로는 평가 없음
print("2. Lazy map 생성 (순회 없이)")
let lazyCreationCount = measureLazyMapCreation(array: testArray)
print("   배열: \(testArray)")
print("   클로저 호출 횟수: \(lazyCreationCount)")
print()

// 3. Lazy map 순회: 순회할 때 평가
print("3. Lazy map 순회 (Array로 변환)")
let (lazyResult, lazyIterationCount) = measureLazyMapIteration(array: testArray)
print("   배열: \(testArray)")
print("   결과: \(lazyResult)")
print("   클로저 호출 횟수: \(lazyIterationCount)")
print()

// 4. Lazy 단락 평가: first는 첫 일치까지만 평가
print("4. Lazy filter().map().first 단락 평가")
let (shortCircuitResult, filterCount, mapCount) = measureLazyShortCircuit(array: testArray, target: 3)
print("   배열: \(testArray), target >= 3")
print("   결과: \(shortCircuitResult ?? -1)")
print("   filter 클로저 호출 횟수: \(filterCount)")
print("   map 클로저 호출 횟수: \(mapCount)")
print()

// 5. Lazy 재순회: 같은 lazy 시퀀스를 두 번 순회하면 재평가
print("5. 같은 lazy 시퀀스를 두 번 순회")
let (firstIterCount, secondIterCount) = measureLazyRepeatedIteration(array: testArray)
print("   배열: \(testArray)")
print("   첫 번째 순회 호출 횟수: \(firstIterCount)")
print("   두 번째 순회 호출 횟수: \(secondIterCount)")
print()

// 6. Lazy 인덱스 접근: 접근마다 재평가
print("6. Lazy 컬렉션 인덱스 접근 (3번 접근)")
let indexAccessCount = measureLazyIndexAccess(array: testArray, index: 2, accessCount: 3)
print("   배열: \(testArray), index: 2")
print("   총 클로저 호출 횟수: \(indexAccessCount)")
print()

// 7. 물질화된 배열: 접근해도 재평가 없음
print("7. Array로 물질화 후 인덱스 접근 (3번 접근)")
let (materializeCount, totalAccessCount) = measureMaterializedAccess(array: testArray, index: 2, accessCount: 3)
print("   배열: \(testArray), index: 2")
print("   물질화 시 클로저 호출 횟수: \(materializeCount)")
print("   이후 3번 접근 후 총 호출 횟수: \(totalAccessCount)")
print()

// 8. 빈 배열에서 first
print("8. 빈 배열에서 lazy.filter().first")
let (emptyResult, emptyCount) = measureLazyEmptyArray()
print("   배열: []")
print("   결과: \(emptyResult?.description ?? "nil")")
print("   클로저 호출 횟수: \(emptyCount)")
print()

// 9. 일치하는 원소가 없을 때 전체 평가
print("9. 일치하는 원소가 없을 때 lazy.filter().first")
let (noMatchResult, noMatchCount) = measureLazyNoMatch(array: testArray)
print("   배열: \(testArray), filter > 1000")
print("   결과: \(noMatchResult?.description ?? "nil")")
print("   클로저 호출 횟수 (전체 평가됨): \(noMatchCount)")
print()

print("=== 결론 ===")
print("- Eager map은 생성 시점에 모든 원소를 평가한다")
print("- Lazy map은 생성만으로는 평가하지 않고, 실제 접근 시에만 평가한다")
print("- Lazy는 단락 평가를 지원하여 first 같은 연산은 필요한 만큼만 평가한다")
print("- Lazy 시퀀스는 결과를 캐시하지 않아 재접근 시 재평가된다 (주의!)")
print("- 반복 사용할 결과는 Array(...)로 물질화하여 재평가 비용을 피해야 한다")
