import Foundation

public struct SliceComparisonResult: Equatable, Sendable {
    public let originalStartIndex: Int
    public let originalCount: Int
    public let rebasedStartIndex: Int
    public let rebasedCount: Int
    public let elementsEqual: Bool
    public let firstElementMatches: Bool?
    
    public init(originalStartIndex: Int, originalCount: Int, rebasedStartIndex: Int, rebasedCount: Int, elementsEqual: Bool, firstElementMatches: Bool?) {
        self.originalStartIndex = originalStartIndex
        self.originalCount = originalCount
        self.rebasedStartIndex = rebasedStartIndex
        self.rebasedCount = rebasedCount
        self.elementsEqual = elementsEqual
        self.firstElementMatches = firstElementMatches
    }
}

public func compareSliceWithRebasedArray<T: Equatable>(_ slice: ArraySlice<T>) -> SliceComparisonResult {
    let rebased = Array(slice)
    let elementsEqual = slice.elementsEqual(rebased)
    let firstElementMatches: Bool?
    
    if slice.isEmpty {
        firstElementMatches = nil
    } else {
        firstElementMatches = (slice[slice.startIndex] == rebased[rebased.startIndex])
    }
    
    return SliceComparisonResult(
        originalStartIndex: slice.startIndex,
        originalCount: slice.count,
        rebasedStartIndex: rebased.startIndex,
        rebasedCount: rebased.count,
        elementsEqual: elementsEqual,
        firstElementMatches: firstElementMatches
    )
}

public struct CopyOnWriteObservation: Equatable, Sendable {
    public let originalFirstElement: Int
    public let sliceFirstElementBeforeMutation: Int
    public let sliceFirstElementAfterMutation: Int
    public let originalUnchanged: Bool
    
    public init(originalFirstElement: Int, sliceFirstElementBeforeMutation: Int, sliceFirstElementAfterMutation: Int, originalUnchanged: Bool) {
        self.originalFirstElement = originalFirstElement
        self.sliceFirstElementBeforeMutation = sliceFirstElementBeforeMutation
        self.sliceFirstElementAfterMutation = sliceFirstElementAfterMutation
        self.originalUnchanged = originalUnchanged
    }
}

public func observeCopyOnWriteBehavior() -> CopyOnWriteObservation {
    let original = [10, 20, 30, 40, 50]
    var slice = original[1..<4]
    
    let sliceFirstBefore = slice[slice.startIndex]
    slice[slice.startIndex] = 999
    let sliceFirstAfter = slice[slice.startIndex]
    
    let originalUnchanged = (original[1] == 20)
    
    return CopyOnWriteObservation(
        originalFirstElement: original[1],
        sliceFirstElementBeforeMutation: sliceFirstBefore,
        sliceFirstElementAfterMutation: sliceFirstAfter,
        originalUnchanged: originalUnchanged
    )
}

public struct StartIndexShiftObservation: Equatable, Sendable {
    public let initialStartIndex: Int
    public let afterRemoveFirstStartIndex: Int
    public let afterDropFirstStartIndex: Int
    
    public init(initialStartIndex: Int, afterRemoveFirstStartIndex: Int, afterDropFirstStartIndex: Int) {
        self.initialStartIndex = initialStartIndex
        self.afterRemoveFirstStartIndex = afterRemoveFirstStartIndex
        self.afterDropFirstStartIndex = afterDropFirstStartIndex
    }
}

public func observeStartIndexShift() -> StartIndexShiftObservation {
    let arr = [10, 20, 30, 40, 50]
    var slice1 = arr[2..<5]
    let initial1 = slice1.startIndex
    slice1.removeFirst()
    let afterRemove = slice1.startIndex
    
    let slice2 = arr[2..<5]
    let slice3 = slice2.dropFirst()
    let afterDrop = slice3.startIndex
    
    return StartIndexShiftObservation(
        initialStartIndex: initial1,
        afterRemoveFirstStartIndex: afterRemove,
        afterDropFirstStartIndex: afterDrop
    )
}
