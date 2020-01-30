import GRPC
import NIO
import NIOHPACK

public protocol SessionProtocol {
    var dependency: Dependency { get }
    var headers: HPACKHeaders { get }
    var connection: ClientConnection { get }
    var configuration: ClientConnection.Configuration { get }
}

extension SessionProtocol {
    /// Request data
    ///
    /// - Parameter request: object conforming to UnaryRequest protocol
    /// - Returns: object for Cancel
    @discardableResult
    public func data<R: UnaryRequest>(with request: R, completionHandler: @escaping (Result<R.Response, StreamingError>) -> Void) -> CancellableStreaming {
        Unary(request: request, headers: headers, connection: connection, configuration: configuration, dependency: dependency)
            .data(completionHandler)
    }

    /// Create a ServerStream
    ///
    /// - Parameter request: object conforming to ServerStreamingRequest protocol
    /// - Returns: object for server streaming
    public func stream<R: ServerStreamingRequest>(with request: R) -> ServerStream<R> {
        ServerStream(request: request, headers: headers, connection: connection, configuration: configuration, dependency: dependency)
    }

    /// Create a ClientStream
    ///
    /// - Parameter request: object conforming to ClientStreamingRequest protocol
    /// - Returns: object for client streaming
    public func stream<R: ClientStreamingRequest>(with request: R) -> ClientStream<R> {
        ClientStream(request: request, headers: headers, connection: connection, configuration: configuration, dependency: dependency)
    }

    /// Create a BidirectionalStream
    ///
    /// - Parameter request: object conforming to BidirectionalStreamingRequest protocol
    /// - Returns: object for bi-directional streaming
    public func stream<R: BidirectionalStreamingRequest>(with request: R) -> BidirectionalStream<R> {
        BidirectionalStream(request: request, headers: headers, connection: connection, configuration: configuration, dependency: dependency)
    }
}

open class Session: SessionProtocol {
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    public var dependency: Dependency
    public var headers: HPACKHeaders
    public var connection: ClientConnection
    public var configuration: ClientConnection.Configuration

    deinit {
        try? connection.close().wait()
        try? eventLoopGroup.syncShutdownGracefully()
    }

    public init(
        host: String,
        port: Int,
        tls: ClientConnection.Configuration.TLS? = ClientConnection.Configuration.TLS(),
        connectionBackoff: ConnectionBackoff? = ConnectionBackoff(),
        headers: HPACKHeaders = HPACKHeaders(),
        dependency: Dependency = StreamingDependency()
    ) {
        self.headers = headers
        self.configuration = ClientConnection.Configuration(
            target: .hostAndPort(host, port),
            eventLoopGroup: eventLoopGroup,
            tls: tls,
            connectionBackoff: connectionBackoff
        )
        self.connection = ClientConnection(configuration: configuration)

        self.dependency = dependency
    }
}
