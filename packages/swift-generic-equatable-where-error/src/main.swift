// 제네릭 함수: T가 Equatable일 때만 사용 가능
func contains<T>(_ value: T, in items: [T]) -> Bool where T: Equatable {
    for item in items {
        if item == value {
            return true
        }
    }
    return false
}

// Equatable을 채택하지 않은 구조체
struct Point {
    let x: Int
    let y: Int
}

// 제약을 만족하는 호출: Int는 Equatable
let numbers = [1, 2, 3]
print(contains(2, in: numbers))

// 제약을 만족하는 호출: String도 Equatable
let names = ["a", "b"]
print(contains("b", in: names))

// 위반 호출: Point는 Equatable이 아니므로 컴파일 에러가 나야 한다.
// 아래 두 줄의 주석을 풀고 빌드해서 에러 메시지를 확인한다.
// let points = [Point(x: 1, y: 2)]
// print(contains(Point(x: 1, y: 2), in: points))
