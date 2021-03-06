import protocol SwiftProtobuf.Message
import struct GRPC.TimeLimit
import struct NIOHPACK.HPACKHeaders

/// Unary connection is possible.
public protocol UnaryRequest: Request {}
extension UnaryRequest {
    public var timeLimit: TimeLimit {
        .timeout(.minutes(1))
    }
}

public protocol SendRequest: Request {}
public protocol ReceiveRequest: Request {}

/// It is possible to receive data continuously from the server.
public protocol ServerStreamingRequest: ReceiveRequest {}

/// It is possible to send data continuously to the server. Data can be received only once when connection is completed.
public protocol ClientStreamingRequest: SendRequest {}

/// It is possible to send and receive data bi-directionally with the server.
public protocol BidirectionalStreamingRequest: ReceiveRequest, SendRequest {}

public protocol Request {
    associatedtype Request
    associatedtype Response
    associatedtype Message

    /// Streaming Method
    var method: CallMethod { get }
    
    /// Streaming request
    var request: Request { get }

    /// A timeLimit value. Default is infinite.
    var timeLimit: TimeLimit { get }

    /// Whether the call is cacheable. Default is false.
    var cacheable: Bool { get }

    /// Create a Request object for sending to server finally
    ///
    /// - Returns: Request object for sending to server
    func buildRequest() -> Request

    /// Create a Request object for sending to server finally
    ///
    /// - Parameter message: object to be sent
    /// - Returns: Request object for sending to server
    func buildRequest(_ message: Message) -> Request

    /// Called just before sending the request.
    ///
    /// - Parameter headers: HPACKHeaders to be sent
    /// - Returns: Metadata changed as necessary
    /// - Throws: Error when intercepting request
    func intercept(headers: HPACKHeaders) throws -> HPACKHeaders
}

public extension Request {
    var timeLimit: TimeLimit {
        .none
    }

    func intercept(headers: HPACKHeaders) throws -> HPACKHeaders {
        headers
    }

    func buildRequest() -> Request {
        request
    }

    func buildRequest(_ message: Void) -> Request {
        buildRequest()
    }

    var cacheable: Bool {
        false
    }
}

public extension Request where Request: SwiftProtobuf.Message {
    var request: Request {
        Request()
    }
}
