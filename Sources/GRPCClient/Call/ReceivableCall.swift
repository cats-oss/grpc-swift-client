import GRPC
import NIO

public protocol ReceivableCall: CancellableCall {
    var status: EventLoopFuture<GRPCStatus> { get }
}

public extension ReceivableCall {
    func statusHandler(_ handler: @escaping (GRPCStatus) -> Void) {
        status.recover { _ in .processingError }.whenSuccess(handler)
    }
}

extension ServerStreamingCall: ReceivableCall {}
extension BidirectionalStreamingCall: ReceivableCall {}
