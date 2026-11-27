import Foundation

public enum SliceIndexError: Error, Equatable, Sendable {
    case indexOutOfBounds
    case invalidZeroBasedAccess
}

public func accessSliceUsingZeroBasedIndex<T>(_ slice: ArraySlice<T>, at zeroBasedIndex: Int) -> Result<T, SliceIndexError> {
    guard slice.indices.contains(zeroBasedIndex) else {
        return .failure(.invalidZeroBasedAccess)
    }
    return .success(slice[zeroBasedIndex])
}

public func accessSliceUsingStartIndex<T>(_ slice: ArraySlice<T>, offsetBy offset: Int) -> Result<T, SliceIndexError> {
    guard offset >= 0, offset < slice.count else {
        return .failure(.indexOutOfBounds)
    }
    let targetIndex = slice.index(slice.startIndex, offsetBy: offset)
    return .success(slice[targetIndex])
}

public func sumSliceUsingZeroBasedLoop(_ slice: ArraySlice<Int>) -> Result<Int, SliceIndexError> {
    var sum = 0
    for i in 0..<slice.count {
        guard slice.indices.contains(i) else {
            return .failure(.invalidZeroBasedAccess)
        }
        sum += slice[i]
    }
    return .success(sum)
}

public func sumSliceUsingIndicesLoop(_ slice: ArraySlice<Int>) -> Int {
    var sum = 0
    for index in slice.indices {
        sum += slice[index]
    }
    return sum
}

public func sumSliceUsingEnumerated(_ slice: ArraySlice<Int>) -> Int {
    var sum = 0
    for (_, value) in slice.enumerated() {
        sum += value
    }
    return sum
}

public struct SliceMetadata: Equatable, Sendable {
    public let startIndex: Int
    public let endIndex: Int
    public let count: Int
    
    public init(startIndex: Int, endIndex: Int, count: Int) {
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.count = count
    }
}

public func extractSliceMetadata<T>(_ slice: ArraySlice<T>) -> SliceMetadata {
    SliceMetadata(
        startIndex: slice.startIndex,
        endIndex: slice.endIndex,
        count: slice.count
    )
}
