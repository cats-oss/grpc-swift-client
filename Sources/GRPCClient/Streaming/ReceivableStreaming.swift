public protocol ReceivableStreaming: CancellableStreaming {
    associatedtype Response

    func receive(_ handler: @escaping (Result<Response, StreamingError>) -> Void) -> Self
}

public extension ReceivableStreaming where Self: Streaming, Call: ReceivableCall {
    @discardableResult
    func receive(_ handler: @escaping (Result<R.OutputType, StreamingError>) -> Void) -> Self {
        do {
            try responseHandler(handler)
            try call.get().statusHandler { status in
                if status.code != .ok {
                    handler(.failure(StreamingError(status)))
                }
            }
        }
        catch {
            handler(.failure(StreamingError(error)))
        }

        return self
    }
}
