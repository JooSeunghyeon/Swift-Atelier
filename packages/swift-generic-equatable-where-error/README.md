# Swift 제네릭 where 절 Equatable 제약 위반 확인

제네릭 함수 `contains(_:in:)`에 `where T: Equatable`을 걸어 두고, Equatable을 채택하지 않은 타입을 넘기면 어떤 컴파일 에러가 나는지 본다.

`src/main.swift`에서 `// 위반 호출` 아래 두 줄의 주석을 풀고 빌드하면 에러 메시지를 직접 확인할 수 있다. 제약을 지킨 호출은 주석 처리 없이 그대로 두었다.

에러 문구는 Swift 버전과 Xcode 버전에 따라 달라질 수 있으므로, 본인 환경에서 빌드한 결과를 기준으로 본다.
