import GRPC

final class Unary<R: Request>: Stream<R>, Streaming, CancellableStreaming {
    private lazy var callResult: Result<UnaryCall<R.InputType, R.OutputType>, StreamingError> = {
        do {
            return .success(try UnaryCall<R.InputType, R.OutputType>(
                connection: connection,
                path: request.method.path,
                request: request.buildRequest(),
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

    public var call: Result<UnaryCall<R.InputType, R.OutputType>, StreamingError> {
        sync { callResult }
    }

    public func responseHandler(_ handler: @escaping (Result<R.OutputType, StreamingError>) -> Void) throws {
        try call.get().response.whenComplete { result in
            handler(result.mapError(StreamingError.init))
        }
    }

    @discardableResult
    public func data(_ completed: @escaping (Result<R.OutputType, StreamingError>) -> Void) -> Self {
        do {
            try responseHandler(completed)
        }
        catch {
            completed(.failure(StreamingError(error)))
        }

        return self
    }
}
