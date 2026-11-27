import Foundation
import ArraySliceLib

final class FailureTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    
    func setFailure() {
        lock.lock()
        value = true
        lock.unlock()
    }
    
    func hasFailure() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

let failureTracker = FailureTracker()

func checkCondition(_ condition: Bool, _ message: String) {
    if !condition {
        print("❌ FAILURE: \(message)")
        failureTracker.setFailure()
    }
}

print("=== Swift ArraySlice 인덱스 재기반 및 버퍼 수명 테스트 ===\n")

print("1. ArraySlice 인덱스 기본 동작")
let array = [100, 200, 300, 400, 500]
let slice = array[2..<5]
let metadata = extractSliceMetadata(slice)
print("원본 배열: \(array)")
print("슬라이스: array[2..<5]")
print("슬라이스 startIndex: \(metadata.startIndex)")
print("슬라이스 endIndex: \(metadata.endIndex)")
print("슬라이스 count: \(metadata.count)")
checkCondition(metadata.startIndex == 2, "startIndex should be 2")
checkCondition(metadata.endIndex == 5, "endIndex should be 5")
checkCondition(metadata.count == 3, "count should be 3")
print()

print("2. 잘못된 0 기반 인덱스 접근 (실패 설계 A)")
let zeroAccessResult = accessSliceUsingZeroBasedIndex(slice, at: 0)
print("slice[0] 접근 시도: \(zeroAccessResult)")
switch zeroAccessResult {
case .success(let value):
    print("값: \(value) (원본 배열의 인덱스 0 원소)")
    checkCondition(value == 100, "zero-based access should read wrong element")
case .failure(let error):
    print("에러: \(error)")
}
print()

print("3. 올바른 startIndex 기반 접근 (설계 B)")
let correctAccessResult = accessSliceUsingStartIndex(slice, offsetBy: 0)
print("slice.index(startIndex, offsetBy: 0) 접근:")
switch correctAccessResult {
case .success(let value):
    print("값: \(value)")
    checkCondition(value == 300, "correct access should read element at index 2")
case .failure(let error):
    print("에러: \(error)")
    failureTracker.setFailure()
}
print()

print("4. 0 기반 루프 순회 (실패 설계 A)")
let zeroLoopResult = sumSliceUsingZeroBasedLoop(slice)
print("for i in 0..<slice.count로 합계:")
switch zeroLoopResult {
case .success(let sum):
    print("합계: \(sum)")
    checkCondition(sum == 600, "zero-based loop should read wrong elements")
case .failure(let error):
    print("에러: \(error)")
}
print()

print("5. indices 기반 루프 순회 (설계 B)")
let indicesLoopSum = sumSliceUsingIndicesLoop(slice)
print("for index in slice.indices로 합계: \(indicesLoopSum)")
checkCondition(indicesLoopSum == 1200, "indices-based loop should sum correctly")
print()

print("6. enumerated 순회 (설계 B)")
let enumeratedSum = sumSliceUsingEnumerated(slice)
print("slice.enumerated()로 합계: \(enumeratedSum)")
checkCondition(enumeratedSum == 1200, "enumerated should sum correctly")
print()

print("7. Array(slice) 재기반 (설계 C)")
let comparison = compareSliceWithRebasedArray(slice)
print("원본 슬라이스 startIndex: \(comparison.originalStartIndex)")
print("재기반 배열 startIndex: \(comparison.rebasedStartIndex)")
print("원소 동일: \(comparison.elementsEqual)")
print("재기반 배열 count: \(comparison.rebasedCount)")
checkCondition(comparison.originalStartIndex == 2, "slice startIndex should be 2")
checkCondition(comparison.rebasedStartIndex == 0, "rebased startIndex should be 0")
checkCondition(comparison.elementsEqual, "elements should be equal")
checkCondition(comparison.rebasedCount == 3, "rebased count should be 3")
print()

print("8. 빈 슬라이스 (경계 케이스 D)")
let emptySlice = array[3..<3]
let emptyMetadata = extractSliceMetadata(emptySlice)
print("빈 슬라이스: array[3..<3]")
print("startIndex: \(emptyMetadata.startIndex)")
print("count: \(emptyMetadata.count)")
checkCondition(emptyMetadata.startIndex == 3, "empty slice startIndex should be 3")
checkCondition(emptyMetadata.count == 0, "empty slice count should be 0")
print()

print("9. 전체 범위 슬라이스 (경계 케이스 D)")
let fullSlice = array[0..<array.count]
let fullMetadata = extractSliceMetadata(fullSlice)
print("전체 슬라이스: array[0..<array.count]")
print("startIndex: \(fullMetadata.startIndex)")
print("count: \(fullMetadata.count)")
checkCondition(fullMetadata.startIndex == 0, "full slice startIndex should be 0")
checkCondition(fullMetadata.count == 5, "full slice count should be 5")
print()

print("10. 슬라이스의 슬라이스 (경계 케이스 D)")
let slice1 = array[1..<4]
let slice2 = slice1[2..<3]
let slice2Metadata = extractSliceMetadata(slice2)
print("slice1: array[1..<4], startIndex=\(slice1.startIndex)")
print("slice2: slice1[2..<3], startIndex=\(slice2Metadata.startIndex)")
checkCondition(slice2Metadata.startIndex == 2, "nested slice should preserve original index")
print()

print("11. copy-on-write 동작 (경계 케이스 D)")
let cowObservation = observeCopyOnWriteBehavior()
print("원본 배열 첫 원소(인덱스 1): \(cowObservation.originalFirstElement)")
print("슬라이스 변경 전: \(cowObservation.sliceFirstElementBeforeMutation)")
print("슬라이스 변경 후: \(cowObservation.sliceFirstElementAfterMutation)")
print("원본 배열 불변: \(cowObservation.originalUnchanged)")
checkCondition(cowObservation.originalFirstElement == 20, "original should be unchanged")
checkCondition(cowObservation.sliceFirstElementBeforeMutation == 20, "slice before should be 20")
checkCondition(cowObservation.sliceFirstElementAfterMutation == 999, "slice after should be 999")
checkCondition(cowObservation.originalUnchanged, "original should be unchanged by slice mutation")
print()

print("12. removeFirst/dropFirst 후 startIndex 변화 (경계 케이스 D)")
let shiftObservation = observeStartIndexShift()
print("초기 startIndex: \(shiftObservation.initialStartIndex)")
print("removeFirst 후 startIndex: \(shiftObservation.afterRemoveFirstStartIndex)")
print("dropFirst 후 startIndex: \(shiftObservation.afterDropFirstStartIndex)")
checkCondition(shiftObservation.initialStartIndex == 2, "initial startIndex should be 2")
checkCondition(shiftObservation.afterRemoveFirstStartIndex == 3, "after removeFirst startIndex should be 3")
checkCondition(shiftObservation.afterDropFirstStartIndex == 3, "after dropFirst startIndex should be 3")
print()

print("13. 슬라이스 버퍼 수명 (슬라이스 보유 시)")
let sliceRetention = observeSliceRetention(totalElements: 100, sliceRange: 10..<15)
print("전체 원소 수: \(sliceRetention.totalElements)")
print("슬라이스 범위: \(sliceRetention.sliceRange)")
print("원본 배열 해제 후 deinit 횟수: \(sliceRetention.deinitCount)")
checkCondition(sliceRetention.deinitCount == 0, "slice should retain entire buffer, no deinit expected")
print()

print("14. 재기반 배열 수명 (독립 버퍼)")
let rebasedRetention = observeRebasedArrayRetention(totalElements: 100, sliceRange: 10..<15)
print("전체 원소 수: \(rebasedRetention.totalElements)")
print("슬라이스 범위: \(rebasedRetention.sliceRange)")
print("원본 배열 해제 후 deinit 횟수: \(rebasedRetention.deinitCount)")
checkCondition(rebasedRetention.deinitCount >= 85, "rebased array should allow original buffer to release outside elements")
print()

print("15. 범위 밖 인덱스 안전 처리 (경계 케이스 D)")
let outOfBoundsResult = accessSliceUsingStartIndex(slice, offsetBy: 10)
print("offsetBy: 10 (범위 밖) 접근:")
switch outOfBoundsResult {
case .success(let value):
    print("값: \(value)")
    failureTracker.setFailure()
case .failure(let error):
    print("에러: \(error)")
    checkCondition(error == .indexOutOfBounds, "should return indexOutOfBounds error")
}
print()

if failureTracker.hasFailure() {
    print("일부 검사 실패")
    exit(1)
} else {
    print("ALL_CHECKS_PASSED")
}
