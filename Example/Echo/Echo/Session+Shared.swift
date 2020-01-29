import GRPCClient

extension Session {
    static let shared = Session(host: "localhost", port: 8082, tls: nil)
}
