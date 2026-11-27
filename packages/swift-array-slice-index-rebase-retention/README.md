# Swift ArraySlice 인덱스 재기반 및 버퍼 수명

## 목적

Swift의 `ArraySlice`는 원본 배열과 인덱스를 공유하고 버퍼도 공유한다. 이로 인해 두 가지 문제가 발생한다:

1. 인덱스 문제: 슬라이스의 `startIndex`는 0이 아니라 원본 배열 기준이다. 0부터라고 가정한 코드는 잘못된 원소를 읽거나 런타임 에러를 발생시킨다.
2. 수명 문제: 큰 배열에서 작은 슬라이스를 떼어 보관하면 원본 버퍼 전체가 메모리에 남는다.

이 패키지는 위 문제를 직접 관찰하고, 안전한 접근 방식과 재기반(rebase) 설계를 비교한다.

## 문제 상황

### 1. 인덱스 공유

```swift
let array = [100, 200, 300, 400, 500]
let slice = array[2..<5]  // [300, 400, 500]

// 잘못된 접근
slice[0]  // 범위 밖 접근 (슬라이스 indices는 2, 3, 4)

// 올바른 접근
slice[slice.startIndex]  // 300을 읽음 (array[2])
```

슬라이스의 `startIndex`는 2이고 indices는 2, 3, 4이므로 `slice[0]`은 범위 밖 접근으로 런타임 트랩이 발생한다. 슬라이스가 더 넓어서 0을 포함하면 `slice[0]`은 원본 배열의 0번 인덱스를 읽어 잘못된 원소를 반환한다.

### 2. 버퍼 공유

```swift
var largeArray = (0..<1000).map { TrackedElement(id: $0) }
let smallSlice = largeArray[10..<15]  // 5개 원소
largeArray = []  // 변수는 비웠지만

// smallSlice가 살아있는 한 1000개 원소 전체가 메모리에 남음
```

슬라이스는 원본 버퍼를 참조하므로, 슬라이스 밖 995개 원소도 해제되지 않는다.

## 해결 방법 비교

| 방법 | 인덱스 안전성 | 버퍼 독립성 | 비용 | 비고 |
|------|---------------|-------------|------|------|
| **A. 0 기반 접근** | ❌ 위험 | - | 없음 | 잘못된 원소 읽기, 런타임 트랩 |
| **B. startIndex/indices 사용** | ✅ 안전 | ❌ 버퍼 공유 | 없음 | 올바른 원소 접근, 버퍼는 여전히 공유 |
| **C. Array(slice) 재기반** | ✅ 안전 | ✅ 독립 버퍼 | O(n) 복사 | 0부터 시작, 독립 버퍼 |

## 구조

### 라이브러리 타깃: ArraySliceLib

**IndexOperations.swift**
- `accessSliceUsingZeroBasedIndex`: 0 기반 접근 시도 (실패 설계 A, 안전하게 에러 반환)
- `accessSliceUsingStartIndex`: startIndex + offsetBy로 접근 (설계 B)
- `sumSliceUsingZeroBasedLoop`: 0 기반 루프 (실패 설계 A)
- `sumSliceUsingIndicesLoop`: indices 기반 루프 (설계 B)
- `sumSliceUsingEnumerated`: enumerated 순회 (설계 B)
- `extractSliceMetadata`: startIndex, endIndex, count 추출

**LifetimeTracking.swift**
- `DeinitCounter`: 스레드 안전한 deinit 카운터
- `TrackedElement`: deinit 시 카운터 증가하는 클래스
- `observeSliceRetention`: 슬라이스가 원본 버퍼 전체를 유지하는지 관찰
- `observeRebasedArrayRetention`: Array(slice) 복사가 독립 버퍼를 만드는지 관찰

**SliceRebase.swift**
- `compareSliceWithRebasedArray`: 슬라이스와 재기반 배열 비교
- `observeCopyOnWriteBehavior`: 슬라이스 수정 시 copy-on-write 확인
- `observeStartIndexShift`: removeFirst/dropFirst 후 startIndex 변화

### 실행 타깃: ArraySliceDemo

모든 시나리오를 결정적으로 출력:
1. ArraySlice 인덱스 기본 동작 (startIndex != 0)
2. 잘못된 0 기반 접근 (실패 설계 A)
3. 올바른 startIndex 기반 접근 (설계 B)
4. 0 기반 루프 순회 (실패 설계 A)
5. indices 기반 루프 순회 (설계 B)
6. enumerated 순회 (설계 B)
7. Array(slice) 재기반 (설계 C)
8. 빈 슬라이스 (경계 케이스 D)
9. 전체 범위 슬라이스 (경계 케이스 D)
10. 슬라이스의 슬라이스 (경계 케이스 D)
11. copy-on-write 동작 (경계 케이스 D)
12. removeFirst/dropFirst 후 startIndex 변화 (경계 케이스 D)
13. 슬라이스 버퍼 수명 (슬라이스 보유 시)
14. 재기반 배열 수명 (독립 버퍼)
15. 범위 밖 인덱스 안전 처리 (경계 케이스 D)

### 테스트 타깃: ArraySliceLibTests

총 27개 테스트 (`@Test`, `import Testing`, `#expect`):
- 인덱스 메타데이터 확인 (빈 슬라이스, 전체 범위, 단일 원소 등)
- 0 기반 접근 vs startIndex 기반 접근 비교
- 루프 순회 방식 비교 (0 기반, indices, enumerated)
- 재기반 배열 startIndex 및 count 확인
- 슬라이스의 슬라이스 인덱스 확인
- copy-on-write 동작 확인
- removeFirst/dropFirst 후 startIndex 변화
- 버퍼 수명 관찰 (슬라이스 vs 재기반 배열)
- prefix/suffix 인덱스 확인
- 범위 검사 (음수 offset, 범위 밖 접근)

## 실행 방법

### 테스트 실행

```bash
cd packages/swift-array-slice-index-rebase-retention
swift test
```

### Demo 실행

```bash
cd packages/swift-array-slice-index-rebase-retention
swift run ArraySliceDemo
```

## 테스트 결과

**환경:** Swift 6.0.3 (Linux Ubuntu 24.04, x86_64)

```
✔ Test run with 27 tests passed after 0.001 seconds.
```

모든 테스트 통과 확인:
- 인덱스 메타데이터 테스트 (5개)
- 0 기반 vs startIndex 기반 접근 (5개)
- 루프 순회 방식 (3개)
- 재기반 배열 비교 (2개)
- 슬라이스의 슬라이스 (1개)
- copy-on-write 및 startIndex 변화 (3개)
- 버퍼 수명 관찰 (4개)
- prefix/suffix 및 범위 검사 (4개)

## Demo 실제 출력

**환경:** Swift 6.0.3 (Linux Ubuntu 24.04, x86_64)

```
=== Swift ArraySlice 인덱스 재기반 및 버퍼 수명 테스트 ===

1. ArraySlice 인덱스 기본 동작
원본 배열: [100, 200, 300, 400, 500]
슬라이스: array[2..<5]
슬라이스 startIndex: 2
슬라이스 endIndex: 5
슬라이스 count: 3

2. 잘못된 0 기반 인덱스 접근 (실패 설계 A)
slice[0] 접근 시도: failure(ArraySliceLib.SliceIndexError.invalidZeroBasedAccess)
에러: invalidZeroBasedAccess

3. 올바른 startIndex 기반 접근 (설계 B)
slice.index(startIndex, offsetBy: 0) 접근:
값: 300

4. 0 기반 루프 순회 (실패 설계 A)
for i in 0..<slice.count로 합계:
에러: invalidZeroBasedAccess

5. indices 기반 루프 순회 (설계 B)
for index in slice.indices로 합계: 1200

6. enumerated 순회 (설계 B)
slice.enumerated()로 합계: 1200

7. Array(slice) 재기반 (설계 C)
원본 슬라이스 startIndex: 2
재기반 배열 startIndex: 0
원소 동일: true
재기반 배열 count: 3

8. 빈 슬라이스 (경계 케이스 D)
빈 슬라이스: array[3..<3]
startIndex: 3
count: 0

9. 전체 범위 슬라이스 (경계 케이스 D)
전체 슬라이스: array[0..<array.count]
startIndex: 0
count: 5

10. 슬라이스의 슬라이스 (경계 케이스 D)
slice1: array[1..<4], startIndex=1
slice2: slice1[2..<3], startIndex=2

11. copy-on-write 동작 (경계 케이스 D)
원본 배열 첫 원소(인덱스 1): 20
슬라이스 변경 전: 20
슬라이스 변경 후: 999
원본 배열 불변: true

12. removeFirst/dropFirst 후 startIndex 변화 (경계 케이스 D)
초기 startIndex: 2
removeFirst 후 startIndex: 3
dropFirst 후 startIndex: 3

13. 슬라이스 버퍼 수명 (슬라이스 보유 시)
전체 원소 수: 100
슬라이스 범위: 10..<15
원본 배열 해제 후 deinit 횟수: 0

14. 재기반 배열 수명 (독립 버퍼)
전체 원소 수: 100
슬라이스 범위: 10..<15
원본 배열 해제 후 deinit 횟수: 95

15. 범위 밖 인덱스 안전 처리 (경계 케이스 D)
offsetBy: 10 (범위 밖) 접근:
에러: indexOutOfBounds

ALL_CHECKS_PASSED
```

## 설계 비교 요약

### A. 0 기반 접근 (실패 설계)

❌ **위험**: 슬라이스의 startIndex가 0이 아닐 때, `slice[0]`은 범위 밖 접근으로 런타임 트랩을 발생시키거나, 슬라이스가 0을 포함하는 경우 원본 배열의 0번 인덱스를 읽어 잘못된 원소를 반환한다.

```swift
let slice = array[2..<5]  // indices: 2, 3, 4
slice[0]  // 런타임 트랩 (0은 슬라이스 범위 밖)

let slice2 = array[0..<3]  // indices: 0, 1, 2
slice2[0]  // array[0]을 읽음 (우연히 올바른 원소이지만 위험)
```

**실제 결과 (Demo에서 slice = array[2..<5]):**
- 0 기반 접근 `slice[0]`: invalidZeroBasedAccess 에러
- 0 기반 루프: invalidZeroBasedAccess 에러 (인덱스 0이 범위 밖)
- indices 루프: 합계 1200 (슬라이스의 [2, 3, 4] 읽음)

### B. startIndex/indices 기반 접근 (안전)

✅ **안전**: 슬라이스의 실제 인덱스 범위를 사용한다.

```swift
// 방법 1: startIndex + offsetBy
let first = slice[slice.index(slice.startIndex, offsetBy: 0)]

// 방법 2: indices 순회
for index in slice.indices {
    let element = slice[index]
}

// 방법 3: enumerated (인덱스 무시)
for (_, element) in slice.enumerated() {
    // element 사용
}
```

**단점**: 버퍼는 여전히 공유되므로 메모리 문제는 해결되지 않는다.

### C. Array(slice) 재기반 (독립 버퍼)

✅ **안전 + 독립**: 슬라이스를 `Array(slice)`로 복사하면 startIndex가 0이 되고 독립 버퍼를 갖는다.

```swift
let slice = array[10..<15]  // startIndex = 10
let rebased = Array(slice)  // startIndex = 0
```

**실제 결과:**
- 슬라이스 보유 시: 100개 중 5개만 사용하지만 deinit 0회 (전체 버퍼 유지)
- 재기반 배열 보유 시: deinit 95회 (슬라이스 밖 원소 해제)

**비용**: O(n) 복사 (n = 슬라이스 원소 수)

**사용 사례:**
- 작은 슬라이스를 장기 보관
- 큰 배열에서 일부만 필요한 경우
- 메모리 효율이 중요한 경우

### D. 경계 케이스

**빈 슬라이스**
- startIndex는 범위 시작점 유지 (예: `array[3..<3]`의 startIndex는 3)
- count는 0

**전체 범위 슬라이스**
- `array[0..<array.count]`의 startIndex는 0
- 재기반 필요 없음

**슬라이스의 슬라이스**
- 인덱스는 계속 원본 배열 기준
- `slice1[2..<3]`의 startIndex는 2 (slice1의 startIndex가 아님)

**copy-on-write**
- 슬라이스 수정 시 원본 배열은 변경되지 않음
- 슬라이스가 독립 버퍼를 갖게 됨

**removeFirst/dropFirst**
- 둘 다 startIndex를 증가시킴
- removeFirst는 in-place 수정, dropFirst는 새 슬라이스 반환

**prefix/suffix**
- 반환된 슬라이스도 원본 인덱스 유지
- `slice.prefix(2)`의 startIndex는 slice의 startIndex와 같음

## 권장 사항

### 인덱스 접근

1. **절대 하지 말 것**: 슬라이스를 0 기반으로 가정하지 않는다.
   ```swift
   // ❌ 잘못됨
   for i in 0..<slice.count {
       let element = slice[i]  // 위험
   }
   ```

2. **해야 할 것**: indices, enumerated, startIndex + offsetBy 사용
   ```swift
   // ✅ 올바름
   for index in slice.indices {
       let element = slice[index]
   }
   
   // ✅ 올바름
   for (offset, element) in slice.enumerated() {
       // offset은 0부터, element는 슬라이스 원소
   }
   
   // ✅ 올바름
   let first = slice[slice.index(slice.startIndex, offsetBy: 0)]
   ```

### 버퍼 관리

1. **단기 사용**: 슬라이스를 그대로 사용해도 된다.
   ```swift
   let slice = array[10..<20]
   process(slice)  // 함수 종료 후 slice 해제
   ```

2. **장기 보관**: Array(slice)로 재기반한다.
   ```swift
   class Cache {
       var items: [Item] = []  // ✅
       // var items: ArraySlice<Item> = []  // ❌ 버퍼 공유
       
       func store(_ slice: ArraySlice<Item>) {
           items = Array(slice)  // 독립 버퍼
       }
   }
   ```

3. **비용 고려**: 재기반은 O(n) 복사이므로, 큰 슬라이스는 필요할 때만 재기반한다.

## 한계

### Swift 버전 의존성

- Swift 6.0 이상 필요
- 이전 버전에서는 Sendable 관련 경고 발생 가능

### ARC 최적화 영향

- deinit 시점은 ARC 최적화에 영향받음
- `withExtendedLifetime`으로 수명을 명시적으로 관리
- 실제 deinit 횟수는 환경에 따라 달라질 수 있음

### 측정하지 않은 것

- 시간 복잡도 측정 (벤치마크 없음)
- reserveCapacity/용량 증가 (별도 패키지에서 다룸)
- Substring/String 슬라이스 (별도 패키지에서 다룸)
- 커스텀 copy-on-write 구현 (별도 패키지에서 다룸)

## 결론

ArraySlice는 성능을 위해 인덱스와 버퍼를 공유하지만, 이로 인해 주의가 필요하다:

1. **인덱스**: 슬라이스의 startIndex는 0이 아니다. indices, enumerated, startIndex + offsetBy를 사용한다.
2. **버퍼**: 슬라이스는 원본 버퍼 전체를 유지한다. 장기 보관 시 Array(slice)로 재기반한다.
3. **트레이드오프**: 재기반은 O(n) 복사 비용이 있지만, 메모리 효율과 인덱스 단순화를 얻는다.
