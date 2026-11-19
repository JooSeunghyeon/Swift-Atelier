import Foundation
import TaskLocalContext

@inline(never)
func processString(_ str: String) -> Int {
    return str.count
}

@main
struct TaskLocalBenchmark {
    static func main() async {
        print("=== TaskLocal 성능 비교 벤치마크 ===\n")
        
        let iterations = 100_000
        
        await benchmarkTaskLocalReads(iterations: iterations)
        await benchmarkExplicitParameterPassing(iterations: iterations)
        await benchmarkWithValueBinding(iterations: iterations)
    }
    
    static func benchmarkTaskLocalReads(iterations: Int) async {
        let clock = ContinuousClock()
        
        var warmup = 0
        RequestContext.$requestID.withValue("benchmark-id") {
            for _ in 0..<100 {
                if let id = RequestContext.requestID {
                    warmup += processString(id)
                }
            }
        }
        _ = warmup
        
        var durations: [Duration] = []
        for _ in 0..<5 {
            var sum = 0
            let duration = clock.measure {
                RequestContext.$requestID.withValue("benchmark-id") {
                    for _ in 0..<iterations {
                        if let id = RequestContext.requestID {
                            sum += processString(id)
                        }
                    }
                }
            }
            durations.append(duration)
            _ = sum
        }
        
        durations.sort()
        let median = durations[durations.count / 2]
        
        print("TaskLocal 읽기 (\(iterations)회, 중앙값)")
        print("  소요 시간: \(median)")
        print("  평균: \(median / Double(iterations))\n")
    }
    
    static func benchmarkExplicitParameterPassing(iterations: Int) async {
        let clock = ContinuousClock()
        
        var warmup = 0
        let requestID = "benchmark-id"
        for _ in 0..<100 {
            warmup += processString(requestID)
        }
        _ = warmup
        
        var durations: [Duration] = []
        for _ in 0..<5 {
            var sum = 0
            let duration = clock.measure {
                for _ in 0..<iterations {
                    sum += processString(requestID)
                }
            }
            durations.append(duration)
            _ = sum
        }
        
        durations.sort()
        let median = durations[durations.count / 2]
        
        print("명시 파라미터 전달 (\(iterations)회, 중앙값)")
        print("  소요 시간: \(median)")
        print("  평균: \(median / Double(iterations))\n")
    }
    
    static func benchmarkWithValueBinding(iterations: Int) async {
        let clock = ContinuousClock()
        
        var warmup = 0
        for _ in 0..<100 {
            RequestContext.$requestID.withValue("benchmark-id") {
                if let id = RequestContext.requestID {
                    warmup += processString(id)
                }
            }
        }
        _ = warmup
        
        var durations: [Duration] = []
        for _ in 0..<5 {
            var sum = 0
            let duration = clock.measure {
                for _ in 0..<iterations {
                    RequestContext.$requestID.withValue("benchmark-id") {
                        if let id = RequestContext.requestID {
                            sum += processString(id)
                        }
                    }
                }
            }
            durations.append(duration)
            _ = sum
        }
        
        durations.sort()
        let median = durations[durations.count / 2]
        
        print("withValue 바인딩 반복 (\(iterations)회, 중앙값)")
        print("  소요 시간: \(median)")
        print("  평균: \(median / Double(iterations))\n")
    }
}
