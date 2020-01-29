import GRPC
import NIO

extension Echo_EchoServiceClient {
    static let shared = Echo_EchoServiceClient(
        connection: ClientConnection(
            configuration: .init(
                target: .hostAndPort("localhost", 8082),
                eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
            )
        )
    )
}
