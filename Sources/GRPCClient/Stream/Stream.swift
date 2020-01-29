import Foundation
import GRPC
import NIOHPACK

open class Stream<R: Request> {
    public typealias Request = R

    public let request: Request
    let headers: HPACKHeaders
    let connection: ClientConnection
    let configuration: ClientConnection.Configuration
    let dependency: Dependency
    let queue: DispatchQueue
    private var lock = os_unfair_lock()

    public init(
        request: Request,
        headers: HPACKHeaders,
        connection: ClientConnection,
        configuration: ClientConnection.Configuration,
        dependency: Dependency,
        queue: DispatchQueue = DispatchQueue(label: "GRPCClient.Stream.receiveQueue")
    ) {
        self.connection = connection
        self.configuration = configuration
        self.request = request
        self.dependency = dependency
        self.headers = headers
        self.queue = queue
    }

    @discardableResult
    func sync<Result>(_ action: () throws -> Result) rethrows -> Result {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return try action()
    }
}
