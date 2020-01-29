import Foundation

public protocol CallMethod {
    static var service: String { get }
    var path: String { get }
}

public extension CallMethod where Self: RawRepresentable, RawValue == String {
    var path: String {
        "/\(Self.service)/\(rawValue)"
    }
}
