let config: [String: [String: Any]] = [
    "server": [
        "network": ["port": 8080],
        "timeout": 30
    ],
    "client": [
        "retry": ["limit": 3]
    ]
]

func lookupPort(in config: [String: [String: Any]], section: String) -> Int {
    // 각 단계가 nil이면 체이닝 전체가 nil이 된다
    if let port = (config[section]?["network"] as? [String: Any])?["port"] as? Int {
        return port
    }
    return 80
}

print(lookupPort(in: config, section: "server"))
print(lookupPort(in: config, section: "client"))
print(lookupPort(in: config, section: "missing"))
