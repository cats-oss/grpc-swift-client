import GRPC

public final class ServerStream<R: Request>: Stream<R>, Streaming, ReceivableStreaming {
    private var handlers: [(Result<R.Response, StreamingError>) -> Void] = []
    private lazy var callResult: Result<ServerStreamingCall<R.Request, R.Response>, StreamingError> = {
        do {
            return .success(try connection.makeServerStreamingCall(
                path: request.method.path,
                request: request.buildRequest(),
                callOptions: CallOptions(
                    customMetadata: request.intercept(headers: dependency.intercept(headers: headers)),
                    timeout: request.timeout,
                    cacheable: request.cacheable
                )
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

    public var call: Result<ServerStreamingCall<R.Request, R.Response>, StreamingError> {
        sync { callResult }
    }

    public func responseHandler(_ handler: @escaping (Result<R.Response, StreamingError>) -> Void) throws {
        sync { handlers.append(handler) }
    }
}
