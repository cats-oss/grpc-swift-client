import GRPC
import NIO

public protocol CancellableCall {
    var eventLoop: EventLoop { get }

    func cancel() -> EventLoopFuture<Void>
    func cancel(promise: EventLoopPromise<Void>?)
}

extension CancellableCall {
    public func cancel() -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        self.cancel(promise: promise)
        return promise.futureResult
    }
}

extension UnaryCall: CancellableCall {}
