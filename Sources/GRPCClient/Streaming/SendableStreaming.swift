public protocol SendableStreaming: CancellableStreaming {
    associatedtype Message

    func send(_ message: Message) -> Self
    func send(_ message: Message, completed: ((Result<Void, StreamingError>) -> Void)?) -> Self
    func send(_ messages: [Message]) -> Self
    func send(_ messages: [Message], completed: ((Result<Void, StreamingError>) -> Void)?) -> Self
    func sendEnd() -> Self
    func sendEnd(completed: ((Result<Void, StreamingError>) -> Void)?) -> Self
}

public extension SendableStreaming where Self: Streaming, Call: SendableCall, Call.Message == R.Request {
    @discardableResult
    func send(_ message: R.Message) -> Self {
        send(message, completed: nil)
    }

    @discardableResult
    func send(_ message: R.Message, completed: ((Result<Void, StreamingError>) -> Void)?) -> Self {
        do {
            try call.get().sendMessage(request.buildRequest(message)).whenComplete { result in
                completed?(result.mapError(StreamingError.init))
            }
        }
        catch {
            completed?(.failure(StreamingError(error)))
        }

        return self
    }

    @discardableResult
    func send(_ messages: [R.Message]) -> Self {
        send(messages, completed: nil)
    }

    @discardableResult
    func send(_ messages: [R.Message], completed: ((Result<Void, StreamingError>) -> Void)?) -> Self {
        do {
            try call.get().sendMessages(messages.map(request.buildRequest)).whenComplete { result in
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
