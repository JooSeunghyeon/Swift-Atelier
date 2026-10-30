protocol Counter {
    mutating func increment()
    var value: Int { get }
}

struct StructCounter: Counter {
    private(set) var value: Int = 0

    mutating func increment() {
        value += 1
    }
}

// class 채택: 아래 주석을 풀어 컴파일러 메시지를 확인한다.
// final class ClassCounter: Counter {
//     var value: Int = 0
//
//     mutating func increment() {  // 여기서 에러가 난다
//         value += 1
//     }
// }

var s = StructCounter()
s.increment()
print("struct value:", s.value)

let c = StructCounter()
// c.increment()  // let 인스턴스는 mutating 호출이 막힌다
