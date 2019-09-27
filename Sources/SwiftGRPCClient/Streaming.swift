//
//  Streaming.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2019/07/10.
//  Copyright © 2019 CyberAgent, Inc. All rights reserved.
//

import Foundation
import SwiftGRPC

public protocol Streaming: class {
    associatedtype Request
    associatedtype Message

    var call: Result<CallProtocol, StreamingError> { get }
    var request: Request { get }
    var dependency: Dependency { get }

    /// Start connection to server. Does not have to call this because it is called internally.
    ///
    /// - Parameter completion: closure called when started connection.
    func start(for type: MessageType, completion: @escaping (Result<CallResult?, StreamingError>) -> Void)

    /// Abort connection to server.
    func cancel()
}

extension Streaming where Request: UnaryRequest {
    /// For Unary connection
    ///
    /// - Parameter completion: closure called when completed connection.
    /// - Returns: Streaming object
    @discardableResult
    public func data(_ completion: @escaping (Result<Request.OutputType, StreamingError>) -> Void) -> Self {
        start(for: .data) { [weak self] result in
            do {
                guard let data = try result.get()?.resultData else {
                    throw StreamingError.noMessageReceived
                }
                guard let parsedData = try? self?.request.parse(data: data) else {
                    throw StreamingError.invalidMessageReceived
                }

                completion(.success(parsedData))
            }
            catch {
                completion(.failure(StreamingError(error)))
            }
        }
        return self
    }
}

extension Streaming where Request: SendRequest, Message == Request.Message {
    /// For send message to server
    ///
    /// - Parameters:
    ///   - message: object sending to server.
    ///   - completion: closure called when message sending is completed.
    /// - Returns: Streaming object
    @discardableResult
    public func send(_ message: Message, completion: ((Result<Void, StreamingError>) -> Void)? = nil) -> Self {
        let reconnectionPolicy = request.reconnectionPolicyWhenChangingNetwork.isUndefined
            ? dependency.reconnectionPolicyWhenChangingNetwork
            : request.reconnectionPolicyWhenChangingNetwork
        start(for: .send(shouldReconnect: reconnectionPolicy.shouldReconnect)) { [weak self] result in
            guard let me = self else {
                return
            }

            do {
                // check start error
                _ = try result.get()
                try me.call.get().sendMessage(data: me.request.serialized(message)) { error in
                    // completion?(operationGroup.success ? nil : CallError.unknown)
                    completion?(error.map { .failure(StreamingError($0)) } ?? .success(()))
                }
            } catch {
                completion?(.failure(StreamingError(error)))
            }
        }
        return self
    }
}

extension Streaming where Request: ReceiveRequest {
    /// For receive message from server
    ///
    /// - Parameter completion: closure called when receive data from server.
    /// - Returns: Streaming object
    @discardableResult
    public func receive(_ completion: @escaping (Result<Request.OutputType, StreamingError>) -> Void) -> Self {
        let reconnectionPolicy = request.reconnectionPolicyWhenChangingNetwork.isUndefined
            ? dependency.reconnectionPolicyWhenChangingNetwork
            : request.reconnectionPolicyWhenChangingNetwork
        start(for: .receive(shouldReconnect: reconnectionPolicy.shouldReconnect)) { [weak self] result in
            func receive() {
                do {
                    // check start error
                    _ = try result.get()
                    try self?.call.get().receiveMessage { result in
                        do {
                            guard let data = result.resultData else {
                                return
                            }
                            guard let parsedData = try? self?.request.parse(data: data) else {
                                throw StreamingError.invalidMessageReceived
                            }

                            completion(.success(parsedData))
                            receive()
                        }
                        catch {
                            completion(.failure(StreamingError(error)))
                        }
                    }
                } catch {
                    completion(.failure(StreamingError(error)))
                }
            }

            receive()
        }
        return self
    }
}

extension Streaming where Request: CloseRequest {
    /// For closing streaming
    ///
    /// - Parameter completion: closure called when completed connection.
    public func close(_ completion: ((Result<Void, StreamingError>) -> Void)? = nil) {
        start(for: .close) { [weak self] result in
            do {
                // check start error
                _ = try result.get()
                try self?.call.get().close {
                    self?.cancel()
                    completion?(.success(()))
                }
            } catch {
                completion?(.failure(StreamingError(error)))
            }
        }
    }
}

extension Streaming where Request: CloseAndReciveRequest {
    /// For closing streaming and receive data from server
    ///
    /// - Parameter completion: closure called when receive data from server.
    public func closeAndReceive(_ completion: @escaping (Result<Request.OutputType, StreamingError>) -> Void) {
        start(for: .close) { [weak self] result in
            do {
                // check start error
                _ = try result.get()
                try self?.call.get().closeAndReceiveMessage { result in
                    self?.cancel()
                    do {
                        guard let data = result.resultData else {
                            throw StreamingError.responseError(result)
                        }
                        guard let parsedData = try? self?.request.parse(data: data) else {
                            throw StreamingError.invalidMessageReceived
                        }

                        completion(.success(parsedData))
                    }
                    catch {
                        completion(.failure(StreamingError(error)))
                    }
                }
            } catch {
                completion(.failure(StreamingError(error)))
            }
        }
    }
}

private extension ReconnectionPolicy {
    var isUndefined: Bool {
        return self == .undefined
    }

    var shouldReconnect: Bool {
        return self == .reconnect
    }
}
