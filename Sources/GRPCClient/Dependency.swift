import NIOHPACK

public protocol Dependency {
    /// It is possible to monitor all requests by injecting it when creating `Session`.
    /// Processing can be interrupted as necessary.
    ///
    /// - Parameter headers: HPACKHeaders to be sent
    /// - Returns: Metadata changed as necessary
    /// - Throws: Error when intercepting request
    func intercept(headers: HPACKHeaders) throws -> HPACKHeaders
}

public extension Dependency {
    func intercept(headers: HPACKHeaders) throws -> HPACKHeaders {
        headers
    }
}

public class StreamingDependency: Dependency {
    public init() {}
}
