# Swift Atelier

문법을 확인하려고 짜 본 코드다. 왜 적었는지는 각 폴더 README에 둔다.

## 목록

- [swift-optional-chaining-lookup](packages/swift-optional-chaining-lookup/README.md): 옵셔널 체이닝으로 중첩된 딕셔너리 값을 안전하게 꺼내는 예제
- [swift-generic-equatable-where-error](packages/swift-generic-equatable-where-error/README.md): Equatable where 절이 걸린 제네릭 함수에 제약을 만족하지 않는 타입을 넘겼을 때 나오는 컴파일 에러 메시지를 직접 확인한다.
- [swift-mutating-protocol-class-conformance-error](packages/swift-mutating-protocol-class-conformance-error/README.md): mutating 요구사항 프로토콜을 class가 채택할 때 mutating 키워드가 무시되는지, 컴파일 에러로 나오는지 확인한다.
- [swift-force-unwrap-nil-crash-location](packages/swift-force-unwrap-nil-crash-location/README.md): Swift 옵셔널 강제 해제(!)에서 nil을 만났을 때 나오는 Fatal error 메시지의 파일명과 줄 번호를 직접 확인한다.
- [swift-lazy-sequence-repeated-evaluation-count](packages/swift-lazy-sequence-repeated-evaluation-count/README.md): Swift lazy 시퀀스/컬렉션에서 변환 클로저가 언제, 몇 번 호출되는지를 호출 횟수 카운터로 측정해 eager map과 비교한다.
