import GRPC
import NIO

public protocol CancellableCall {
    func cancel() -> EventLoopFuture<Void>
    func cancel(promise: EventLoopPromise<Void>?)
}

extension UnaryCall: CancellableCall {}
