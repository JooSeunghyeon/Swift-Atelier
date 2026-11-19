import Foundation
import TaskLocalContext

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
        
        let duration = await clock.measure {
            await RequestContext.$requestID.withValue("benchmark-id") {
                for _ in 0..<iterations {
                    _ = RequestContext.requestID
                }
            }
        }
        
        print("TaskLocal 읽기 (\(iterations)회)")
        print("  소요 시간: \(duration)")
        print("  평균: \(duration / Double(iterations))\n")
    }
    
    static func benchmarkExplicitParameterPassing(iterations: Int) async {
        let clock = ContinuousClock()
        
        let duration = clock.measure {
            let requestID = "benchmark-id"
            for _ in 0..<iterations {
                _ = requestID
            }
        }
        
        print("명시 파라미터 전달 (\(iterations)회)")
        print("  소요 시간: \(duration)")
        print("  평균: \(duration / Double(iterations))\n")
    }
    
    static func benchmarkWithValueBinding(iterations: Int) async {
        let clock = ContinuousClock()
        
        let duration = await clock.measure {
            for _ in 0..<iterations {
                await RequestContext.$requestID.withValue("benchmark-id") {
                    _ = RequestContext.requestID
                }
            }
        }
        
        print("withValue 바인딩 반복 (\(iterations)회)")
        print("  소요 시간: \(duration)")
        print("  평균: \(duration / Double(iterations))\n")
    }
}
