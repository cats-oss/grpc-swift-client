import GRPC
import NIO

public protocol SendableCall: CancellableCall {
    associatedtype Message

    func sendMessage(_ message: Message, compression: Compression) -> EventLoopFuture<Void>
    func sendMessage(_ message: Message, compression: Compression, promise: EventLoopPromise<Void>?)
    func sendMessages<S: Sequence>(_ messages: S, compression: Compression) -> EventLoopFuture<Void> where S.Element == Message
    func sendMessages<S: Sequence>(_ messages: S, compression: Compression, promise: EventLoopPromise<Void>?) where S.Element == Message
    func sendEnd() -> EventLoopFuture<Void>
    func sendEnd(promise: EventLoopPromise<Void>?)
}

extension ClientStreamingCall: SendableCall {}
extension BidirectionalStreamingCall: SendableCall {}
