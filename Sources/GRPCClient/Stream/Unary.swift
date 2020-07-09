import GRPC

final class Unary<R: Request>: Stream<R>, Streaming, CancellableStreaming {
    private lazy var callResult: Result<UnaryCall<R.Request, R.Response>, StreamingError> = {
        do {
            return .success(try connection.makeUnaryCall(
                path: request.method.path,
                request: request.buildRequest(),
                callOptions: CallOptions(
                    customMetadata: request.intercept(headers: dependency.intercept(headers: headers)),
                    timeLimit: request.timeLimit,
                    cacheable: request.cacheable
                )
            ))
        }
        catch {
            return .failure(StreamingError.callCreationError(error))
        }
    }()

    public var call: Result<UnaryCall<R.Request, R.Response>, StreamingError> {
        sync { callResult }
    }

    public func responseHandler(_ handler: @escaping (Result<R.Response, StreamingError>) -> Void) throws {
        try call.get().response.whenComplete { result in
            handler(result.mapError(StreamingError.init))
        }
    }

    @discardableResult
    public func data(_ completed: @escaping (Result<R.Response, StreamingError>) -> Void) -> Self {
        do {
            try responseHandler(completed)
        }
        catch {
            completed(.failure(StreamingError(error)))
        }

        return self
    }
}
