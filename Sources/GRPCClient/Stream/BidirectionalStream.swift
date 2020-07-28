import GRPC
import SwiftProtobuf

public final class BidirectionalStream<R: Request>: Stream<R>, Streaming, SendableStreaming, ReceivableStreaming where R.Request: Message, R.Response: Message {
    private var handlers: [(Result<R.Response, StreamingError>) -> Void] = []
    private lazy var callResult: Result<BidirectionalStreamingCall<R.Request, R.Response>, StreamingError> = {
        do {
            return .success(try connection.makeBidirectionalStreamingCall(
                path: request.method.path,
                callOptions: CallOptions(
                    customMetadata: request.intercept(headers: dependency.intercept(headers: headers)),
                    timeLimit: request.timeLimit,
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

    public var call: Result<BidirectionalStreamingCall<R.Request, R.Response>, StreamingError> {
        sync { callResult }
    }

    public func responseHandler(_ handler: @escaping (Result<R.Response, StreamingError>) -> Void) throws {
        sync { handlers.append(handler) }
    }
}
