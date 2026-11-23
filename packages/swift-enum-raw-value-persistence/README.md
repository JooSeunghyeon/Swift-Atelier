# Swift enum rawValue 영속성 호환

## 목적

Swift enum의 rawValue를 데이터베이스나 JSON으로 저장할 때, 나중에 enum에 새 case를 "중간에" 추가하면 암묵적(implicit) Int rawValue는 기존 저장된 값의 의미가 조용히 바뀌는 문제를 직접 관찰하고, 명시적(explicit) Int rawValue, String rawValue, 그리고 알 수 없는 값도 보존하는 래퍼 설계를 비교한다.

## 문제 상황

### 암묵적 Int rawValue의 위험

```swift
// 스키마 v1
enum Priority: Int {
    case low      // rawValue = 0
    case medium   // rawValue = 1 (암묵적)
    case high     // rawValue = 2 (암묵적)
}
```

데이터베이스에 `priority = 1` (medium)을 저장했다가, 나중에 `critical`을 중간에 추가하면:

```swift
// 스키마 v2 - critical을 중간에 삽입
enum Priority: Int {
    case low      // rawValue = 0
    case critical // rawValue = 1 (새로 삽입! 암묵적)
    case medium   // rawValue = 2 (밀림)
    case high     // rawValue = 3 (밀림)
}
```

저장된 `1`은 이제 `critical`로 해석되지만, 원래는 `medium`이었다. 컴파일 에러도 런타임 경고도 없이 조용히 의미가 바뀐다.

## 해결 방법 비교

| 방법 | 중간 삽입 안전성 | unknown 값 처리 | 비고 |
|------|------------------|-----------------|------|
| **암묵적 Int** | ❌ 위험 | enum init 실패 | 새 case가 중간에 들어가면 기존 값 의미 변경 |
| **명시적 Int** | ✅ 안전 | enum init 실패 | 선언 순서와 raw 값 순서를 독립적으로 관리 |
| **String** | ✅ 안전 | enum init 실패 | 가장 안정적, 저장 공간 약간 증가 |
| **StoredPriority 래퍼** | ✅ 안전 | ✅ 보존 | unknown 값도 round-trip 보장, 디코딩 실패 없음 |

## 구조

### 라이브러리 타깃: RawValuePersistence

**ImplicitVersions.swift**
- `ImplicitV1`: low, medium, high (rawValue 0, 1, 2)
- `ImplicitV2`: low, **critical**, medium, high (rawValue 0, 1, 2, 3 - 중간 삽입으로 밀림)
- `analyzeImplicitMigrationDrift`: v1 저장값을 v2로 해석 시 의미가 바뀐 항목 보고

**ExplicitVersions.swift**
- `ExplicitV1`: low=0, medium=1, high=2 (명시적)
- `ExplicitV2`: low=0, **critical=3**, medium=1, high=2 (선언 순서 ≠ raw 값 순서)
- `analyzeExplicitMigrationDrift`: 드리프트 분석 (명시적이므로 드리프트 없음)

**StringVersions.swift**
- `StringV1`, `StringV2`: 문자열 rawValue (항상 안정적)
- `analyzeStringMigrationDrift`: 드리프트 분석

**StoredPriority.swift**
- `struct StoredPriority: RawRepresentable, Codable, Equatable, Sendable`
- `rawValue: Int`를 그대로 보관
- `var known: ExplicitV2?`로 알려진 case 해석
- 알 수 없는 값(99, -1, Int.max)도 디코딩 실패 없이 보존

**JSONHelpers.swift**
- JSON 인코딩/디코딩 헬퍼
- `compareAllCasesWithSortedRawValues()`: allCases 순서 vs raw 값 정렬 순서 비교

### 실행 타깃: RawValueDemo

모든 시나리오를 결정적으로 출력 (시간, 랜덤, 주소 없음):
1. 암묵적 rawValue 비교
2. 암묵적 마이그레이션 드리프트
3. 명시적 rawValue 비교
4. 명시적 마이그레이션 (드리프트 없음)
5. 문자열 rawValue 비교
6. 문자열 마이그레이션 (드리프트 없음)
7. allCases 순서 vs 정렬 순서
8. StoredPriority unknown 보존
9. JSON 디코딩 비교 (enum 실패 vs 래퍼 성공)
10. StoredPriority round-trip

### 테스트 타깃: RawValuePersistenceTests

총 34개 테스트 (`@Test`, `import Testing`, `#expect`):
- ImplicitV1/V2 rawValue 확인
- raw 1(medium)이 V2에서 critical로 해석됨
- raw 3이 V1에서 nil, V2에서 high
- 마이그레이션 드리프트 분석 (암묵적: 2건, 명시적: 0건, 문자열: 0건)
- 빈 배열은 빈 결과
- ExplicitV1 저장값 0/1/2가 V2에서도 같은 이름
- allCases 순서 ≠ raw 정렬 순서
- rawValue 음수/Int.max/99 → init nil
- JSON {"priority":99} enum 디코딩 → DecodingError
- StoredPriority 99/-1/Int.max 보존 round-trip
- StoredPriority.known nil 케이스
- JSON 키 누락 → DecodingError
- 중복 raw 입력 독립 처리
- Equatable, init from ExplicitV2

## 실행 방법

### 테스트 실행

```bash
cd packages/swift-enum-raw-value-persistence
swift test
```

### Demo 실행

```bash
cd packages/swift-enum-raw-value-persistence
swift run RawValueDemo
```

## 테스트 결과

**환경:** Swift 6.4.3 (Linux Ubuntu 24.04, x86_64)

```
✔ Test run with 34 tests in 1 suite passed after 0.002 seconds.
```

모든 테스트 통과 확인:
- ImplicitV1/V2 rawValue 및 드리프트 (8개)
- ExplicitV1/V2 rawValue 및 안정성 (7개)
- StringV1/V2 rawValue 및 안정성 (5개)
- 경계값 테스트 (3개)
- StoredPriority 동작 (7개)
- JSON 디코딩 에러 (2개)
- 추가 경계 케이스 (2개)

## Demo 실제 출력

**환경:** Swift 6.4.3 (Linux Ubuntu 24.04, x86_64)

```
=== Swift enum rawValue 영속성 호환 테스트 ===

1. 암묵적 Int rawValue (중간 삽입 시 밀림)
ImplicitV1.allCases.map(\.rawValue): [0, 1, 2]
ImplicitV2.allCases.map(\.rawValue): [0, 1, 2, 3]

2. 암묵적 rawValue 마이그레이션 드리프트
v1 저장값 [0, 1, 2]를 v2로 해석:
  raw 1: v1=medium → v2=critical
  raw 2: v1=high → v2=medium

3. 명시적 Int rawValue (안정적)
ExplicitV1 rawValues: low=0, medium=1, high=2
ExplicitV2.allCases.map(\.rawValue): [0, 3, 1, 2]

4. 명시적 rawValue 마이그레이션 (드리프트 없음)
v1 저장값 [0, 1, 2]를 v2로 해석:
  드리프트 없음 (모든 값이 같은 의미 유지)

5. 문자열 rawValue (항상 안정적)
StringV1 rawValues: low="low", medium="medium", high="high"
StringV2.allCases.map(\.rawValue): ["low", "critical", "medium", "high"]

6. 문자열 rawValue 마이그레이션 (드리프트 없음)
v1 저장값 ["low", "medium", "high"]를 v2로 해석:
  드리프트 없음 (모든 값이 같은 의미 유지)

7. ExplicitV2 allCases 순서 vs rawValue 정렬 순서
allCases 순서: [0, 3, 1, 2]
정렬된 순서: [0, 1, 2, 3]
순서가 다름: true

8. StoredPriority unknown 보존 설계
StoredPriority(rawValue: 99): known=unknown, rawValue=99
StoredPriority(rawValue: -1): known=unknown, rawValue=-1
StoredPriority(rawValue: 9223372036854775807): known=unknown, rawValue=9223372036854775807
StoredPriority(rawValue: 0): known=low, rawValue=0
StoredPriority(rawValue: 1): known=medium, rawValue=1
StoredPriority(rawValue: 2): known=high, rawValue=2
StoredPriority(rawValue: 3): known=critical, rawValue=3

9. JSON 디코딩 (enum vs StoredPriority)
JSON: {"priority":99}
ExplicitV2 디코딩: 실패 (DecodingError)
StoredPriority 디코딩: 성공 (rawValue=99, known=nil)

10. StoredPriority JSON round-trip
raw 99: 원본=99, 복원=99, 일치=true
raw -1: 원본=-1, 복원=-1, 일치=true
raw 0: 원본=0, 복원=0, 일치=true
raw 3: 원본=3, 복원=3, 일치=true

=== 테스트 완료 ===
```

## 설계 비교 요약

### 1. 암묵적 Int rawValue (ImplicitV1/V2)

❌ **위험**: 중간에 case를 추가하면 뒤 case들의 rawValue가 자동으로 밀려서 기존 저장값의 의미가 바뀐다.

```swift
// v1에서 저장한 1(medium)이 v2에서는 critical로 해석됨
```

### 2. 명시적 Int rawValue (ExplicitV1/V2)

✅ **안전**: 각 case에 고정된 rawValue를 명시하면 선언 순서를 바꿔도 저장값 의미가 유지된다.

```swift
enum ExplicitV2: Int {
    case low = 0
    case critical = 3  // 새로 추가, 큰 값 사용
    case medium = 1    // 기존 값 유지
    case high = 2      // 기존 값 유지
}
```

**단점**: enum 정의에서 init?(rawValue:)이 nil을 반환할 수 있으므로, 알 수 없는 값(예: 서버에서 받은 미래 버전 값)을 처리하려면 옵셔널 처리 필요.

### 3. String rawValue (StringV1/V2)

✅ **가장 안정적**: 문자열은 순서와 무관하므로 중간 삽입에도 안전하다.

**단점**: 저장 공간이 Int보다 크고, 오타 가능성.

### 4. StoredPriority 래퍼

✅ **unknown 보존**: `RawRepresentable` + `Codable`로 rawValue를 그대로 저장하고, `known` 프로퍼티로 enum 해석 시도.

```swift
struct StoredPriority: RawRepresentable, Codable, Equatable, Sendable {
    let rawValue: Int
    var known: ExplicitV2? { ExplicitV2(rawValue: rawValue) }
}
```

**장점**:
- 알 수 없는 rawValue(99, -1, Int.max)도 디코딩 실패 없이 보존
- JSON round-trip 보장
- enum을 직접 디코딩하면 `DecodingError.dataCorrupted`가 나지만, 래퍼는 성공

**사용 사례**:
- 서버가 클라이언트보다 최신 enum 값을 보낼 때
- 레거시 데이터에 현재 enum에 없는 값이 있을 때
- 디코딩 실패로 전체 객체가 버려지는 것을 방지

## 결론

**영속 데이터에 enum rawValue를 저장할 때 권장 사항:**

1. **암묵적 Int rawValue 금지**: 중간 삽입 시 조용한 의미 변경
2. **명시적 Int rawValue 사용**: 각 case에 고정 값 명시, 새 case는 기존 범위 밖 값 사용
3. **String rawValue 고려**: 가장 안정적, 저장 공간과 타입 안전성 트레이드오프
4. **unknown 보존 래퍼**: 버전 호환성이 중요하거나, 알 수 없는 값을 조용히 보존해야 할 때 `RawRepresentable` + `Codable` 래퍼 사용

**절대 하지 말아야 할 것:**
- 암묵적 Int rawValue로 영속 데이터 저장
- enum 정의 순서에 의존하여 rawValue 가정
- 기존 case의 rawValue 변경

**해야 할 것:**
- 각 case에 명시적 rawValue 할당
- 새 case 추가 시 기존 rawValue와 겹치지 않는 값 사용
- 마이그레이션 테스트 작성 (이 패키지의 drift 분석 함수 참고)
