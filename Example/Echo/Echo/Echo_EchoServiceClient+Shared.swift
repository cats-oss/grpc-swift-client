import GRPC
import NIO

extension Echo_EchoClient {
    static let shared = Echo_EchoClient(
        channel: ClientConnection.insecure(
            group: PlatformSupport.makeEventLoopGroup(loopCount: System.coreCount)
        ).connect(host: "localhost", port: 8082)
    )
}
