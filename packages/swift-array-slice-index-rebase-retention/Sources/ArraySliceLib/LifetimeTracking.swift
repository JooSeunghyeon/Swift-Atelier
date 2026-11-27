import Foundation

public final class DeinitCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Int = 0
    
    public init() {}
    
    public func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }
    
    public func get() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
    
    public func reset() {
        lock.lock()
        value = 0
        lock.unlock()
    }
}

public final class TrackedElement: @unchecked Sendable {
    public let id: Int
    private let counter: DeinitCounter
    
    public init(id: Int, counter: DeinitCounter) {
        self.id = id
        self.counter = counter
    }
    
    deinit {
        counter.increment()
    }
}

public struct LifetimeObservation: Equatable, Sendable {
    public let totalElements: Int
    public let sliceRange: Range<Int>
    public let deinitCount: Int
    public let deinitCountAfterRelease: Int
    
    public init(totalElements: Int, sliceRange: Range<Int>, deinitCount: Int, deinitCountAfterRelease: Int) {
        self.totalElements = totalElements
        self.sliceRange = sliceRange
        self.deinitCount = deinitCount
        self.deinitCountAfterRelease = deinitCountAfterRelease
    }
}

public func observeSliceRetention(totalElements: Int, sliceRange: Range<Int>) -> LifetimeObservation {
    let counter = DeinitCounter()
    counter.reset()
    
    var slice: ArraySlice<TrackedElement>?
    
    do {
        let array = (0..<totalElements).map { TrackedElement(id: $0, counter: counter) }
        slice = array[sliceRange]
        withExtendedLifetime(array) {}
    }
    
    let deinitCountAfterArrayDropped = counter.get()
    
    withExtendedLifetime(slice) {}
    slice = nil
    
    let deinitCountAfterRelease = counter.get()
    
    return LifetimeObservation(
        totalElements: totalElements,
        sliceRange: sliceRange,
        deinitCount: deinitCountAfterArrayDropped,
        deinitCountAfterRelease: deinitCountAfterRelease
    )
}

public func observeRebasedArrayRetention(totalElements: Int, sliceRange: Range<Int>) -> LifetimeObservation {
    let counter = DeinitCounter()
    counter.reset()
    
    var rebasedArray: [TrackedElement]?
    
    do {
        let array = (0..<totalElements).map { TrackedElement(id: $0, counter: counter) }
        let slice = array[sliceRange]
        rebasedArray = Array(slice)
        withExtendedLifetime(array) {}
    }
    
    let deinitCountAfterArrayDropped = counter.get()
    
    withExtendedLifetime(rebasedArray) {}
    rebasedArray = nil
    
    let deinitCountAfterRelease = counter.get()
    
    return LifetimeObservation(
        totalElements: totalElements,
        sliceRange: sliceRange,
        deinitCount: deinitCountAfterArrayDropped,
        deinitCountAfterRelease: deinitCountAfterRelease
    )
}
