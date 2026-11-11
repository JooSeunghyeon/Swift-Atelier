/// 클로저 호출 횟수를 추적하는 카운터
final class CallCounter {
    private var count: Int = 0
    
    func increment() {
        count += 1
    }
    
    func getCount() -> Int {
        return count
    }
    
    func reset() {
        count = 0
    }
}

/// Eager map 평가 횟수를 측정한다
func measureEagerMap(array: [Int]) -> (result: [Int], callCount: Int) {
    let counter = CallCounter()
    let result = array.map { value -> Int in
        counter.increment()
        return value * 2
    }
    return (result, counter.getCount())
}

/// Lazy map 생성 시 평가 횟수를 측정한다 (순회 없이)
func measureLazyMapCreation(array: [Int]) -> Int {
    let counter = CallCounter()
    let _ = array.lazy.map { value -> Int in
        counter.increment()
        return value * 2
    }
    return counter.getCount()
}

/// Lazy map을 순회할 때 평가 횟수를 측정한다
func measureLazyMapIteration(array: [Int]) -> (result: [Int], callCount: Int) {
    let counter = CallCounter()
    let lazyMapped = array.lazy.map { value -> Int in
        counter.increment()
        return value * 2
    }
    let result = Array(lazyMapped)
    return (result, counter.getCount())
}

/// Lazy filter().map().first 단락 평가를 측정한다
func measureLazyShortCircuit(array: [Int], target: Int) -> (result: Int?, filterCount: Int, mapCount: Int) {
    let filterCounter = CallCounter()
    let mapCounter = CallCounter()
    
    let result = array.lazy
        .filter { value -> Bool in
            filterCounter.increment()
            return value >= target
        }
        .map { value -> Int in
            mapCounter.increment()
            return value * 2
        }
        .first
    
    return (result, filterCounter.getCount(), mapCounter.getCount())
}

/// 같은 lazy 시퀀스를 두 번 순회할 때 재평가를 측정한다
func measureLazyRepeatedIteration(array: [Int]) -> (firstCallCount: Int, secondCallCount: Int) {
    let counter = CallCounter()
    let lazyMapped = array.lazy.map { value -> Int in
        counter.increment()
        return value * 2
    }
    
    counter.reset()
    let _ = Array(lazyMapped)
    let firstCount = counter.getCount()
    
    counter.reset()
    let _ = Array(lazyMapped)
    let secondCount = counter.getCount()
    
    return (firstCount, secondCount)
}

/// Lazy 컬렉션의 인덱스 접근 재평가를 측정한다
func measureLazyIndexAccess(array: [Int], index: Int, accessCount: Int) -> Int {
    let counter = CallCounter()
    let lazyMapped = array.lazy.map { value -> Int in
        counter.increment()
        return value * 2
    }
    
    for _ in 0..<accessCount {
        let _ = lazyMapped[index]
    }
    
    return counter.getCount()
}

/// Array로 물질화한 후 접근 시 재평가가 없음을 측정한다
func measureMaterializedAccess(array: [Int], index: Int, accessCount: Int) -> (materializeCallCount: Int, totalCallCount: Int) {
    let counter = CallCounter()
    let lazyMapped = array.lazy.map { value -> Int in
        counter.increment()
        return value * 2
    }
    
    let materialized = Array(lazyMapped)
    let materializeCount = counter.getCount()
    
    for _ in 0..<accessCount {
        let _ = materialized[index]
    }
    
    return (materializeCount, counter.getCount())
}

/// 빈 배열에서 lazy.filter().first 호출 시 평가 횟수를 측정한다
func measureLazyEmptyArray() -> (result: Int?, callCount: Int) {
    let counter = CallCounter()
    let result = [Int]().lazy
        .filter { value -> Bool in
            counter.increment()
            return true
        }
        .first
    
    return (result, counter.getCount())
}

/// 일치하는 원소가 없을 때 lazy.filter().first가 전체를 평가하는지 측정한다
func measureLazyNoMatch(array: [Int]) -> (result: Int?, callCount: Int) {
    let counter = CallCounter()
    let result = array.lazy
        .filter { value -> Bool in
            counter.increment()
            return value > 1000
        }
        .first
    
    return (result, counter.getCount())
}
