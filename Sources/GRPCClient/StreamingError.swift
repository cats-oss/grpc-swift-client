import struct GRPC.GRPCStatus

public enum StreamingError: Error {
    case callCreationError(Error)
    case responseError(GRPCStatus)
    case unknownError(Error)

    init(_ error: Error) {
        switch error {
        case let error as StreamingError:
            self = error

        case let error as GRPCStatus:
            self = .responseError(error)

        case let error:
            self = .unknownError(error)
        }
    }
}
