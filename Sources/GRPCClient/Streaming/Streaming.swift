public protocol Streaming: AnyObject {
    associatedtype R: Request
    associatedtype Call

    var request: R { get }
    var call: Result<Call, StreamingError> { get }

    func responseHandler(_ handler: @escaping (Result<R.OutputType, StreamingError>) -> Void) throws
}
