import GRPC
import NIO
import NIOHPACK
import SwiftProtobuf

public protocol SessionProtocol {
    var dependency: Dependency { get }
    var headers: HPACKHeaders { get }
    var connection: ClientConnection { get }
}

extension SessionProtocol {
    /// Request data
    ///
    /// - Parameter request: object conforming to UnaryRequest protocol
    /// - Returns: object for Cancel
    @discardableResult
    public func data<R: UnaryRequest>(with request: R, completionHandler: @escaping (Result<R.Response, StreamingError>) -> Void) -> CancellableStreaming where R.Request: Message, R.Response: Message {
        Unary(request: request, headers: headers, connection: connection, dependency: dependency)
            .data(completionHandler)
    }

    /// Create a ServerStream
    ///
    /// - Parameter request: object conforming to ServerStreamingRequest protocol
    /// - Returns: object for server streaming
    public func stream<R: ServerStreamingRequest>(with request: R) -> ServerStream<R> {
        ServerStream(request: request, headers: headers, connection: connection, dependency: dependency)
    }

    /// Create a ClientStream
    ///
    /// - Parameter request: object conforming to ClientStreamingRequest protocol
    /// - Returns: object for client streaming
    public func stream<R: ClientStreamingRequest>(with request: R) -> ClientStream<R> {
        ClientStream(request: request, headers: headers, connection: connection, dependency: dependency)
    }

    /// Create a BidirectionalStream
    ///
    /// - Parameter request: object conforming to BidirectionalStreamingRequest protocol
    /// - Returns: object for bi-directional streaming
    public func stream<R: BidirectionalStreamingRequest>(with request: R) -> BidirectionalStream<R> {
        BidirectionalStream(request: request, headers: headers, connection: connection, dependency: dependency)
    }
}

open class Session: SessionProtocol {
    private let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: System.coreCount)
    public let dependency: Dependency
    public let headers: HPACKHeaders
    public let connection: ClientConnection

    deinit {
        try? connection.close().wait()
        try? eventLoopGroup.syncShutdownGracefully()
    }

    public init(
        host: String,
        port: Int,
        isTLSRequired: Bool = true,
        headers: HPACKHeaders = HPACKHeaders(),
        dependency: Dependency = StreamingDependency()
    ) {
        self.headers = headers
        let builder = isTLSRequired
            ? ClientConnection.secure(group: eventLoopGroup)
            : ClientConnection.insecure(group: eventLoopGroup)

        self.connection = builder
            .withErrorDelegate(SessionErrorDelegate { error, file, line in
                dependency.didCatchError(error, file: file, line: line)
            })
            .connect(host: host, port: port)

        self.dependency = dependency
    }
}
