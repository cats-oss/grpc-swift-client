import protocol GRPC.ClientErrorDelegate
import struct Logging.Logger

final class SessionErrorDelegate: ClientErrorDelegate {
    /// error, file, line
    typealias ErrorHandler = (Error, StaticString, Int) -> Void

    let errorHandler: ErrorHandler

    init(handler: @escaping ErrorHandler) {
        errorHandler = handler
    }

    func didCatchError(_ error: Error, logger: Logger, file: StaticString, line: Int) {
        errorHandler(error, file, line)
    }
}
