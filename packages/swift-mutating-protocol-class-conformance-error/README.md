# mutating 요구사항 프로토콜을 class가 채택할 때의 컴파일 동작

프로토콜에 `mutating func`를 요구하면 struct와 enum은 이를 만족할 수 있다. class는 값을 바꾸는 메서드에 `mutating`을 붙일 수 없으므로 같은 프로토콜을 채택할 때 다른 결과가 나온다.

이 폴더의 `src/main.swift`에는 struct 채택 코드와 class 채택 코드가 함께 들어 있다. class 채택 부분의 주석을 풀면 컴파일러가 어떤 메시지를 내는지 확인할 수 있다.

직접 확인할 때는 class 쪽 `mutating`을 제거한 버전과 남긴 버전을 각각 컴파일해 본다. 에러 문구는 Swift 버전에 따라 조금 달라질 수 있다.
