import GRPC

public final class ServerStream<R: Request>: Stream<R>, Streaming, ReceivableStreaming {
    private var handlers: [(Result<R.OutputType, StreamingError>) -> Void] = []
    private lazy var callResult: Result<ServerStreamingCall<R.InputType, R.OutputType>, StreamingError> = {
        do {
            return .success(try ServerStreamingCall<R.InputType, R.OutputType>(
                connection: connection,
                path: request.method.path,
                request: request.buildRequest(),
                callOptions: CallOptions(
                    customMetadata: request.intercept(headers: dependency.intercept(headers: headers)),
                    timeout: request.timeout,
                    cacheable: request.cacheable
                ),
                errorDelegate: configuration.errorDelegate
            ) { [weak self] response in
                self?.sync {
                    self?.handlers.forEach { handler in
                        self?.queue.async {
                            handler(.success(response))
                        }
                    }
                }
            })
        }
        catch {
            return .failure(StreamingError.callCreationError(error))
        }
    }()

    public var call: Result<ServerStreamingCall<R.InputType, R.OutputType>, StreamingError> {
        sync { callResult }
    }

    public func responseHandler(_ handler: @escaping (Result<R.OutputType, StreamingError>) -> Void) throws {
        sync { handlers.append(handler) }
    }
}
