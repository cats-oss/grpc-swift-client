import NIOHPACK

public protocol Dependency {
    /// It is possible to monitor all requests by injecting it when creating `Session`.
    /// Processing can be interrupted as necessary.
    ///
    /// - Parameter headers: HPACKHeaders to be sent
    /// - Returns: Metadata changed as necessary
    /// - Throws: Error when intercepting request
    func intercept(headers: HPACKHeaders) throws -> HPACKHeaders

    /// Called when the client catches an error.
    ///
    /// - Parameters:
    ///   - error: The error which was caught.
    ///   - file: The file where the error was raised.
    ///   - line: The line within the file where the error was raised.
    func didCatchError(_ error: Error, file: StaticString, line: Int)
}

public extension Dependency {
    func intercept(headers: HPACKHeaders) throws -> HPACKHeaders {
        headers
    }

    func didCatchError(_ error: Error, file: StaticString, line: Int) {}
}

public class StreamingDependency: Dependency {
    public init() {}
}
