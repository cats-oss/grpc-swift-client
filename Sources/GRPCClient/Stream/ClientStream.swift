import GRPC

public final class ClientStream<R: Request>: Stream<R>, Streaming, SendableStreaming {
    private lazy var callResult: Result<ClientStreamingCall<R.Request, R.Response>, StreamingError> = {
        do {
            return .success(try ClientStreamingCall<R.Request, R.Response>(
                connection: connection,
                path: request.method.path,
                callOptions: CallOptions(
                    customMetadata: request.intercept(headers: dependency.intercept(headers: headers)),
                    timeout: request.timeout,
                    cacheable: request.cacheable
                ),
                errorDelegate: configuration.errorDelegate
            ))
        }
        catch {
            return .failure(StreamingError.callCreationError(error))
        }
    }()

    public var call: Result<ClientStreamingCall<R.Request, R.Response>, StreamingError> {
        sync { callResult }
    }

    public func responseHandler(_ handler: @escaping (Result<R.Response, StreamingError>) -> Void) throws {
        try call.get().response.whenComplete { result in
            handler(result.mapError(StreamingError.init))
        }
    }

    @discardableResult
    public func sendEnd(completed: @escaping ((Result<R.Response, StreamingError>) -> Void)) -> Self {
        do {
            try responseHandler(completed)
            return sendEnd()
        }
        catch {
            completed(.failure(StreamingError(error)))
        }

        return self
    }
}
