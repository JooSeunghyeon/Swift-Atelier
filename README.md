# Swift Atelier

문법을 확인하려고 짜 본 코드다. 왜 적었는지는 각 폴더 README에 둔다.

## 목록

- [swift-optional-chaining-lookup](packages/swift-optional-chaining-lookup/README.md): 옵셔널 체이닝으로 중첩된 딕셔너리 값을 안전하게 꺼내는 예제
- [swift-generic-equatable-where-error](packages/swift-generic-equatable-where-error/README.md): Equatable where 절이 걸린 제네릭 함수에 제약을 만족하지 않는 타입을 넘겼을 때 나오는 컴파일 에러 메시지를 직접 확인한다.
- [swift-mutating-protocol-class-conformance-error](packages/swift-mutating-protocol-class-conformance-error/README.md): mutating 요구사항 프로토콜을 class가 채택할 때 mutating 키워드가 무시되는지, 컴파일 에러로 나오는지 확인한다.
- [swift-force-unwrap-nil-crash-location](packages/swift-force-unwrap-nil-crash-location/README.md): Swift 옵셔널 강제 해제(!)에서 nil을 만났을 때 나오는 Fatal error 메시지의 파일명과 줄 번호를 직접 확인한다.
- [swift-lazy-sequence-repeated-evaluation-count](packages/swift-lazy-sequence-repeated-evaluation-count/README.md): Swift lazy 시퀀스/컬렉션에서 변환 클로저가 언제, 몇 번 호출되는지를 호출 횟수 카운터로 측정해 eager map과 비교한다.
- [swift-async-let-sibling-cancellation-on-throw](packages/swift-async-let-sibling-cancellation-on-throw/README.md): async let 형제 태스크 중 하나가 실패할 때 await 순서가 에러 관찰 시점을 결정하고, 미대기 자식이 암묵적으로 취소되는 동작을 확인한다.
- [swift-task-local-context-propagation](packages/swift-task-local-context-propagation/README.md): Swift TaskLocal 값이 자식·Task{}에는 전파되고 Task.detached·저장된 콜백에서는 끊기는 지점과 명시 캡처 설계를 비교하는 예제
- [swift-enum-raw-value-persistence](packages/swift-enum-raw-value-persistence/README.md): Swift enum rawValue 영속성 호환 테스트: 저장된 Int rawValue가 있는 상태에서 enum에 case를 중간에 끼워 넣을 때 암묵적 Int rawValue는 뒤 case들의 값이 밀려 옛 데이터가 조용히 다른 case로 해석되는 지점과, 명시 Int rawValue·String rawValue·unknown 보존 래퍼 설계를 비교하는 예제
