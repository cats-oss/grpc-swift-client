import protocol GRPC.GRPCPayload

public protocol Payload: GRPCPayload {
    init()
}
