import GRPC
import NIO

public protocol SendableCall: CancellableCall {
    associatedtype Message

    func sendMessage(_ message: Message) -> EventLoopFuture<Void>
    func sendMessage(_ message: Message, promise: EventLoopPromise<Void>?)
    func sendMessages<S: Sequence>(_ messages: S) -> EventLoopFuture<Void> where S.Element == Message
    func sendMessages<S: Sequence>(_ messages: S, promise: EventLoopPromise<Void>?) where S.Element == Message
    func sendEnd() -> EventLoopFuture<Void>
    func sendEnd(promise: EventLoopPromise<Void>?)
}

extension ClientStreamingCall: SendableCall {}
extension BidirectionalStreamingCall: SendableCall {}
