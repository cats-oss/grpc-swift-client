import GRPC

public protocol SendableStreaming: CancellableStreaming {
    associatedtype Message

    @discardableResult
    func send(_ message: Message, compression: Compression) -> Self
    @discardableResult
    func send(_ message: Message, compression: Compression, completed: ((Result<Void, StreamingError>) -> Void)?) -> Self
    @discardableResult
    func send(_ messages: [Message], compression: Compression) -> Self
    @discardableResult
    func send(_ messages: [Message], compression: Compression, completed: ((Result<Void, StreamingError>) -> Void)?) -> Self
    @discardableResult
    func sendEnd() -> Self
    @discardableResult
    func sendEnd(completed: ((Result<Void, StreamingError>) -> Void)?) -> Self
}

public extension SendableStreaming where Self: Streaming, Call: SendableCall, Call.Message == R.Request {
    @discardableResult
    func send(_ message: R.Message, compression: Compression = .deferToCallDefault) -> Self {
        send(message, compression: compression, completed: nil)
    }

    @discardableResult
    func send(_ message: R.Message, compression: Compression = .deferToCallDefault, completed: ((Result<Void, StreamingError>) -> Void)?) -> Self {
        do {
            try call.get().sendMessage(request.buildRequest(message), compression: compression).whenComplete { result in
                completed?(result.mapError(StreamingError.init))
            }
        }
        catch {
            completed?(.failure(StreamingError(error)))
        }

        return self
    }

    @discardableResult
    func send(_ messages: [R.Message], compression: Compression = .deferToCallDefault) -> Self {
        send(messages, compression: compression, completed: nil)
    }

    @discardableResult
    func send(_ messages: [R.Message], compression: Compression = .deferToCallDefault, completed: ((Result<Void, StreamingError>) -> Void)?) -> Self {
        do {
            try call.get().sendMessages(messages.map(request.buildRequest), compression: compression).whenComplete { result in
                completed?(result.mapError(StreamingError.init))
            }
        }
        catch {
            completed?(.failure(StreamingError(error)))
        }

        return self
    }

    @discardableResult
    func sendEnd() -> Self {
        sendEnd(completed: nil)
    }

    @discardableResult
    func sendEnd(completed: ((Result<Void, StreamingError>) -> Void)?) -> Self {
        do {
            try call.get().sendEnd().whenComplete { result in
                completed?(result.mapError(StreamingError.init))
            }
        }
        catch {
            completed?(.failure(StreamingError(error)))
        }

        return self
    }
}
