import GRPC
import SwiftProtobuf

public final class ClientStream<R: Request>: Stream<R>, Streaming, SendableStreaming where R.Request: Message, R.Response: Message {
    private lazy var callResult: Result<ClientStreamingCall<R.Request, R.Response>, StreamingError> = {
        do {
            return .success(try connection.makeClientStreamingCall(
                path: request.method.path,
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
        sendEnd { [weak self] (result: Result<Void, StreamingError>) in
            do {
                _ = try result.get()
                guard let me = self else {
                    throw GRPCStatus(code: .internalError, message: "Stream already has deallocated.")
                }

                try me.responseHandler(completed)
            }
            catch {
                completed(.failure(StreamingError(error)))
            }
        }
    }
}
