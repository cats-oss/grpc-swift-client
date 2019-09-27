public struct ReconnectionPolicy: RawRepresentable {
    public var rawValue: Int8

    public init(rawValue: Int8) {
        self.rawValue = rawValue
    }

    static let undefined = ReconnectionPolicy(rawValue: 1 << 0)
    public static let `continue` = ReconnectionPolicy(rawValue: 1 << 1)
    public static let reconnect = ReconnectionPolicy(rawValue: 1 << 2)
}
