public protocol CancellableStreaming: AnyObject {
    func cancel()
    func cancel(completed: ((Result<Void, StreamingError>) -> Void)?)
}

public extension CancellableStreaming where Self: Streaming, Self.Call: CancellableCall {
    func cancel() {
        cancel(completed: nil)
    }

    func cancel(completed: ((Result<Void, StreamingError>) -> Void)?) {
        do {
            try call.get().cancel().whenComplete { result in
                completed?(result.mapError(StreamingError.init))
            }
        }
        catch {
            completed?(.failure(StreamingError(error)))
        }
    }
}
