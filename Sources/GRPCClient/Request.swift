import protocol SwiftProtobuf.Message
import struct GRPC.GRPCTimeout
import struct NIOHPACK.HPACKHeaders

/// Unary connection is possible.
public protocol UnaryRequest: Request {}
extension UnaryRequest {
    public var timeout: GRPCTimeout {
        .default
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
    associatedtype InputType: SwiftProtobuf.Message
    associatedtype OutputType: SwiftProtobuf.Message
    associatedtype Message

    /// Streaming Method
    var method: CallMethod { get }
    
    /// Streaming request
    var request: InputType { get }

    /// A timeout value. Default is infinite.
    var timeout: GRPCTimeout { get }

    /// Whether the call is cacheable. Default is false.
    var cacheable: Bool { get }

    /// Create a Request object for sending to server finally
    ///
    /// - Returns: Request object for sending to server
    func buildRequest() -> InputType

    /// Create a Request object for sending to server finally
    ///
    /// - Parameter message: object to be sent
    /// - Returns: Request object for sending to server
    func buildRequest(_ message: Message) -> InputType

    /// Called just before sending the request.
    ///
    /// - Parameter headers: HPACKHeaders to be sent
    /// - Returns: Metadata changed as necessary
    /// - Throws: Error when intercepting request
    func intercept(headers: HPACKHeaders) throws -> HPACKHeaders
}

public extension Request {
    var request: InputType {
        InputType()
    }

    var timeout: GRPCTimeout {
        .infinite
    }

    func intercept(headers: HPACKHeaders) throws -> HPACKHeaders {
        headers
    }

    func buildRequest() -> InputType {
        request
    }

    func buildRequest(_ message: Void) -> InputType {
        buildRequest()
    }

    var cacheable: Bool {
        false
    }
}
