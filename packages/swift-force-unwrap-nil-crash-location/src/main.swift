struct Profile {
    let name: String
    var address: Address?
}

struct Address {
    let city: String
}

func lookupScore(_ table: [String: Int], key: String) -> Int? {
    return table[key]
}

func findProfile(_ id: Int, in store: [Int: Profile]) -> Profile? {
    return store[id]
}

let scores: [String: Int] = ["alice": 90]
let profiles: [Int: Profile] = [
    1: Profile(name: "alice", address: Address(city: "Seoul")),
    2: Profile(name: "bob", address: nil)
]

// 경로 1: 딕셔너리 subscript 결과를 강제 해제
func crashByDictionary() {
    let score = scores["bob"]!
    print("score: \(score)")
}

// 경로 2: 중첩 프로퍼티의 옵셔널을 강제 해제
func crashByNestedProperty() {
    let city = profiles[2]!.address!.city
    print("city: \(city)")
}

// 경로 3: 함수 반환값의 옵셔널을 강제 해제
func crashByReturnValue() {
    let profile = findProfile(99, in: profiles)!
    print("name: \(profile.name)")
}

// 실행할 경로를 하나만 살린다
crashByDictionary()
// crashByNestedProperty()
// crashByReturnValue()
