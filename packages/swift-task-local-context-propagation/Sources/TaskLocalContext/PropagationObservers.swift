import Foundation

/// withValue 범위 안에서 값 읽기
public func readInsideWithValue() async -> String {
    return await RequestContext.$requestID.withValue("A") {
        currentContextLog()
    }
}

/// withValue 범위 밖에서 값 읽기
public func readOutsideWithValue() async -> String {
    await RequestContext.$requestID.withValue("A") {
        // withValue 범위 안
    }
    return currentContextLog()
}

/// async let으로 생성된 자식 태스크에서 값 읽기
public func readInAsyncLet() async -> String {
    return await RequestContext.$requestID.withValue("B") {
        async let child = currentContextLog()
        return await child
    }
}

/// Task { } 로 생성된 자식 태스크에서 값 읽기
public func readInStructuredTask() async -> String {
    return await RequestContext.$requestID.withValue("C") {
        await Task {
            currentContextLog()
        }.value
    }
}

/// Task.detached로 생성된 분리 태스크에서 값 읽기 (nil 반환 예상)
public func readInDetachedTask() async -> String {
    return await RequestContext.$requestID.withValue("D") {
        await Task.detached {
            currentContextLog()
        }.value
    }
}

/// withTaskGroup으로 생성된 자식 태스크에서 값 읽기
public func readInTaskGroup() async -> [String] {
    return await RequestContext.$requestID.withValue("E") {
        await withTaskGroup(of: String.self) { group in
            group.addTask {
                currentContextLog()
            }
            group.addTask {
                currentContextLog()
            }
            var results: [String] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}

/// 중첩 withValue에서 안쪽 값 읽기
public func readNestedWithValueInner() async -> String {
    return await RequestContext.$requestID.withValue("F") {
        await RequestContext.$requestID.withValue("G") {
            currentContextLog()
        }
    }
}

/// 중첩 withValue 종료 후 바깥 값 복원 확인
public func readNestedWithValueOuter() async -> String {
    return await RequestContext.$requestID.withValue("H") {
        await RequestContext.$requestID.withValue("I") {
            // 안쪽 범위
        }
        return currentContextLog()
    }
}

/// Task 생성 후 바깥 범위가 끝나도 이미 만든 Task는 생성 시점 값 유지
public func taskPreservesCreationContext() async -> String {
    let task = await RequestContext.$requestID.withValue("J") {
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            return currentContextLog()
        }
    }
    return await task.value
}
