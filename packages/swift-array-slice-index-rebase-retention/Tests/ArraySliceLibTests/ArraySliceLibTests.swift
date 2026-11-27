import Testing
import Foundation
@testable import ArraySliceLib

@Suite("ArraySlice 인덱스 및 버퍼 수명 테스트")
struct ArraySliceLibTests {
    
    @Test("슬라이스 startIndex는 원본 기준")
    func testSliceStartIndexIsOriginalBased() {
        let array = [10, 20, 30, 40, 50]
        let slice = array[2..<5]
        let metadata = extractSliceMetadata(slice)
        
        #expect(metadata.startIndex == 2)
        #expect(metadata.endIndex == 5)
        #expect(metadata.count == 3)
    }
    
    @Test("빈 슬라이스 startIndex")
    func testEmptySliceStartIndex() {
        let array = [10, 20, 30]
        let slice = array[2..<2]
        let metadata = extractSliceMetadata(slice)
        
        #expect(metadata.startIndex == 2)
        #expect(metadata.count == 0)
    }
    
    @Test("전체 범위 슬라이스 startIndex는 0")
    func testFullRangeSliceStartIndex() {
        let array = [10, 20, 30, 40]
        let slice = array[0..<array.count]
        let metadata = extractSliceMetadata(slice)
        
        #expect(metadata.startIndex == 0)
        #expect(metadata.count == 4)
    }
    
    @Test("0 기반 접근은 잘못된 원소를 읽음")
    func testZeroBasedAccessReadsWrongElement() {
        let array = [100, 200, 300, 400, 500, 600]
        let slice = array[2..<5]
        
        let result = accessSliceUsingZeroBasedIndex(slice, at: 2)
        
        switch result {
        case .success(let value):
            #expect(value == 300)
        case .failure:
            Issue.record("2 접근은 성공해야 함 (슬라이스 첫 원소)")
        }
    }
    
    @Test("0 기반 접근이 범위 밖일 때 실패")
    func testZeroBasedAccessOutOfBounds() {
        let array = [100, 200, 300, 400]
        let slice = array[3..<4]
        
        let result = accessSliceUsingZeroBasedIndex(slice, at: 0)
        
        switch result {
        case .success:
            Issue.record("범위 밖 접근은 실패해야 함")
        case .failure(let error):
            #expect(error == .invalidZeroBasedAccess)
        }
    }
    
    @Test("startIndex 기반 접근은 올바른 원소를 읽음")
    func testStartIndexBasedAccessReadsCorrectElement() {
        let array = [100, 200, 300, 400]
        let slice = array[2..<4]
        
        let result = accessSliceUsingStartIndex(slice, offsetBy: 0)
        
        switch result {
        case .success(let value):
            #expect(value == 300)
        case .failure:
            Issue.record("올바른 접근은 성공해야 함")
        }
    }
    
    @Test("startIndex 기반 접근 offsetBy 1")
    func testStartIndexBasedAccessWithOffset1() {
        let array = [100, 200, 300, 400]
        let slice = array[1..<3]
        
        let result = accessSliceUsingStartIndex(slice, offsetBy: 1)
        
        switch result {
        case .success(let value):
            #expect(value == 300)
        case .failure:
            Issue.record("offsetBy 1은 성공해야 함")
        }
    }
    
    @Test("startIndex 기반 접근이 범위 밖일 때 실패")
    func testStartIndexBasedAccessOutOfBounds() {
        let array = [100, 200, 300]
        let slice = array[1..<2]
        
        let result = accessSliceUsingStartIndex(slice, offsetBy: 5)
        
        switch result {
        case .success:
            Issue.record("범위 밖 접근은 실패해야 함")
        case .failure(let error):
            #expect(error == .indexOutOfBounds)
        }
    }
    
    @Test("0 기반 루프는 잘못된 합계를 계산")
    func testZeroBasedLoopCalculatesWrongSum() {
        let array = [10, 20, 30, 40, 50, 60]
        let slice = array[0..<3]
        
        let result = sumSliceUsingZeroBasedLoop(slice)
        
        switch result {
        case .success(let sum):
            #expect(sum == 60)
        case .failure:
            Issue.record("0 기반 루프는 성공해야 함")
        }
    }
    
    @Test("indices 루프는 올바른 합계를 계산")
    func testIndicesLoopCalculatesCorrectSum() {
        let array = [10, 20, 30, 40, 50]
        let slice = array[2..<5]
        
        let sum = sumSliceUsingIndicesLoop(slice)
        
        #expect(sum == 120)
    }
    
    @Test("enumerated는 올바른 합계를 계산")
    func testEnumeratedCalculatesCorrectSum() {
        let array = [10, 20, 30, 40, 50]
        let slice = array[2..<5]
        
        let sum = sumSliceUsingEnumerated(slice)
        
        #expect(sum == 120)
    }
    
    @Test("빈 슬라이스 indices 루프는 0")
    func testEmptySliceIndicesLoopReturnsZero() {
        let array = [10, 20, 30]
        let slice = array[2..<2]
        
        let sum = sumSliceUsingIndicesLoop(slice)
        
        #expect(sum == 0)
    }
    
    @Test("Array(slice) 재기반 후 startIndex는 0")
    func testRebasedArrayStartIndexIsZero() {
        let array = [10, 20, 30, 40]
        let slice = array[1..<3]
        
        let comparison = compareSliceWithRebasedArray(slice)
        
        #expect(comparison.originalStartIndex == 1)
        #expect(comparison.rebasedStartIndex == 0)
        #expect(comparison.elementsEqual)
    }
    
    @Test("재기반 배열 count는 슬라이스와 동일")
    func testRebasedArrayCountMatchesSlice() {
        let array = [10, 20, 30, 40, 50]
        let slice = array[2..<5]
        
        let comparison = compareSliceWithRebasedArray(slice)
        
        #expect(comparison.originalCount == 3)
        #expect(comparison.rebasedCount == 3)
    }
    
    @Test("슬라이스의 슬라이스는 원본 인덱스 유지")
    func testNestedSlicePreservesOriginalIndex() {
        let array = [100, 200, 300, 400, 500]
        let slice1 = array[1..<4]
        let slice2 = slice1[2..<3]
        
        let metadata = extractSliceMetadata(slice2)
        
        #expect(metadata.startIndex == 2)
        #expect(metadata.count == 1)
    }
    
    @Test("copy-on-write: 슬라이스 수정 시 원본 불변")
    func testCopyOnWritePreservesOriginal() {
        let observation = observeCopyOnWriteBehavior()
        
        #expect(observation.originalFirstElement == 20)
        #expect(observation.sliceFirstElementBeforeMutation == 20)
        #expect(observation.sliceFirstElementAfterMutation == 999)
        #expect(observation.originalUnchanged)
    }
    
    @Test("removeFirst 후 startIndex 증가")
    func testRemoveFirstShiftsStartIndex() {
        let observation = observeStartIndexShift()
        
        #expect(observation.initialStartIndex == 2)
        #expect(observation.afterRemoveFirstStartIndex == 3)
    }
    
    @Test("dropFirst 후 startIndex 증가")
    func testDropFirstShiftsStartIndex() {
        let observation = observeStartIndexShift()
        
        #expect(observation.initialStartIndex == 2)
        #expect(observation.afterDropFirstStartIndex == 3)
    }
    
    @Test("슬라이스는 원본 버퍼 전체를 유지")
    func testSliceRetainsEntireBuffer() {
        let observation = observeSliceRetention(totalElements: 100, sliceRange: 10..<15)
        
        #expect(observation.totalElements == 100)
        #expect(observation.sliceRange == 10..<15)
        #expect(observation.deinitCount == 0)
    }
    
    @Test("슬라이스는 작은 범위도 전체 버퍼 유지")
    func testSmallSliceRetainsEntireBuffer() {
        let observation = observeSliceRetention(totalElements: 1000, sliceRange: 5..<10)
        
        #expect(observation.totalElements == 1000)
        #expect(observation.deinitCount == 0)
    }
    
    @Test("재기반 배열은 독립 버퍼를 가짐")
    func testRebasedArrayHasIndependentBuffer() {
        let observation = observeRebasedArrayRetention(totalElements: 100, sliceRange: 10..<15)
        
        #expect(observation.totalElements == 100)
        #expect(observation.sliceRange == 10..<15)
        #expect(observation.deinitCount >= 85)
    }
    
    @Test("재기반 배열은 슬라이스 밖 원소를 해제")
    func testRebasedArrayReleasesOutsideElements() {
        let observation = observeRebasedArrayRetention(totalElements: 50, sliceRange: 10..<12)
        
        #expect(observation.deinitCount >= 48)
    }
    
    @Test("슬라이스 prefix도 원본 인덱스 유지")
    func testSlicePrefixPreservesOriginalIndex() {
        let array = [10, 20, 30, 40, 50]
        let slice = array[2..<5]
        let prefixSlice = slice.prefix(2)
        
        let metadata = extractSliceMetadata(prefixSlice)
        
        #expect(metadata.startIndex == 2)
        #expect(metadata.count == 2)
    }
    
    @Test("슬라이스 suffix도 원본 인덱스 유지")
    func testSliceSuffixPreservesOriginalIndex() {
        let array = [10, 20, 30, 40, 50]
        let slice = array[2..<5]
        let suffixSlice = slice.suffix(2)
        
        let metadata = extractSliceMetadata(suffixSlice)
        
        #expect(metadata.startIndex == 3)
        #expect(metadata.count == 2)
    }
    
    @Test("슬라이스 범위 검사: 음수 offset 거부")
    func testNegativeOffsetRejected() {
        let array = [10, 20, 30]
        let slice = array[1..<3]
        
        let result = accessSliceUsingStartIndex(slice, offsetBy: -1)
        
        switch result {
        case .success:
            Issue.record("음수 offset은 실패해야 함")
        case .failure(let error):
            #expect(error == .indexOutOfBounds)
        }
    }
    
    @Test("단일 원소 슬라이스 메타데이터")
    func testSingleElementSliceMetadata() {
        let array = [100, 200, 300]
        let slice = array[1..<2]
        
        let metadata = extractSliceMetadata(slice)
        
        #expect(metadata.startIndex == 1)
        #expect(metadata.endIndex == 2)
        #expect(metadata.count == 1)
    }
    
    @Test("단일 원소 슬라이스 올바른 접근")
    func testSingleElementSliceCorrectAccess() {
        let array = [100, 200, 300]
        let slice = array[1..<2]
        
        let result = accessSliceUsingStartIndex(slice, offsetBy: 0)
        
        switch result {
        case .success(let value):
            #expect(value == 200)
        case .failure:
            Issue.record("단일 원소 접근은 성공해야 함")
        }
    }
}
