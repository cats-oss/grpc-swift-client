//
//  Stream.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2017/10/26.
//  Copyright © 2017年 CyberAgent, Inc. All rights reserved.
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
    /// - Parameter completion: closure called when started connection
    func start(for type: MessageType, completion: @escaping (Result<CallResult?, StreamingError>) -> Void)

    /// Abort connection to server
    func cancel()

    /// Discard internally held `Call` objects.
    func refresh()
}

open class Stream<R: Request>: Streaming {
    public typealias Request = R
    public typealias Message = R.Message

    private let channel: ChannelProtocol
    private(set) public var call: Result<CallProtocol, StreamingError>
    public let request: Request
    public let dependency: Dependency
    private let metadata: Metadata
    private let task = CompletionTask<Result<CallResult?, StreamingError>>()
    private let lock = NSLock()
    private let networkMonitor = NetworkMonitor()
    private let queue: DispatchQueue
    private var retryCount = 5

    public required init(
        channel: ChannelProtocol,
        request: Request,
        dependency: Dependency,
        metadata: Metadata,
        queue: DispatchQueue = DispatchQueue(label: "SwiftGRPCClient.Stream.restartQueue")
        ) {
        self.channel = channel
        self.request = request
        do {
            self.call = .success(try channel.makeCall(request.method, timeout: request.timeout))
        } catch {
            self.call = .failure(.callCreationFailed)
        }
        self.dependency = dependency
        self.metadata = metadata
        self.queue = queue
    }

    public func start(for type: MessageType, completion: @escaping (Result<CallResult?, StreamingError>) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        monitoringNetowrk(for: type, completion: completion)

        guard type == .receive || networkMonitor?.isReachable ?? false else {
            return completion(.failure(.notConnectedToInternet))
        }

        guard task.next(completion) else {
            return
        }

        do {
            switch request.style {
            case .unary:
                try call.get().start(request, dependency: dependency, metadata: metadata) { response in
                    // Capture self until complete.
                    self.task.complete(
                        response.statusCode == .ok ? .success(response) : .failure(.responseError(response))
                    )
                }

            case .serverStreaming, .clientStreaming, .bidiStreaming:
                try call.get().start(request, dependency: dependency, metadata: metadata) { [weak self] response in
                    guard let me = self else { return }

                    switch response.statusCode {
                    case .unavailable where !me.restart(for: type, completion: completion),
                         .unauthenticated,
                         .permissionDenied,
                         .unimplemented,
                         .deadlineExceeded:
                        completion(.failure(.responseError(response)))

                    default:
                        break
                    }
                }

                task.complete(.success(nil))
            }
        } catch {
            task.complete(.failure(StreamingError(error)))
        }
    }

    open func cancel() {
        try? call.get().cancel()
    }

    open func refresh() {
        lock.lock()
        defer { lock.unlock() }

        cancel()
        task.cancel()
        do {
            call = .success(try channel.makeCall(request.method, timeout: request.timeout))
        } catch {
            call = .failure(.callCreationFailed)
        }
    }

    private func resetRetryCount() {
        lock.lock()
        defer { lock.unlock() }

        retryCount = 5
    }

    private func restart(for type: MessageType, completion: @escaping (Result<CallResult?, StreamingError>) -> Void) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let isRetryable = retryCount >= 1
        guard isRetryable else { return false }
        retryCount -= 1

        guard type == .send || type == .receive else {
            return false
        }

        queue.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let me = self else { return }

            let isReachable = me.networkMonitor?.isReachable ?? false
            me.refreshIfReachedToNetwork(isReachable)

            if type == .receive && isReachable {
                me.start(for: type, completion: completion)
            }
        }

        return true
    }

    private func refreshIfReachedToNetwork(_ isReachable: Bool) {
        if isReachable {
            refresh()
        } else {
            cancel()
        }
    }

    private func monitoringNetowrk(for type: MessageType, completion: @escaping (Result<CallResult?, StreamingError>) -> Void) {
        switch type {
        case .data, .close:
            break

        case .send:
            if networkMonitor?.stateHandler == nil {
                networkMonitor?.stateHandler = { [weak self] state in
                    self?.resetRetryCount()
                    self?.refreshIfReachedToNetwork(state.isReachable)
                }
            }

        case .receive:
            networkMonitor?.stateHandler = { [weak self] state in
                self?.resetRetryCount()
                self?.refreshIfReachedToNetwork(state.isReachable)
                if state.isReachable {
                    self?.start(for: type, completion: completion)
                }
            }
        }
    }
}

extension Streaming where Request: UnaryRequest {
    /// For Unary connection
    ///
    /// - Parameter completion: closure called when completed connection
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
    ///   - message: object sending to server
    ///   - completion: closure called when message sending is completed
    /// - Returns: Streaming object
    @discardableResult
    public func send(_ message: Message, completion: ((Result<Void, StreamingError>) -> Void)? = nil) -> Self {
        start(for: .send) { [weak self] result in
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
    /// - Parameter completion: closure called when receive data from server
    /// - Returns: Streaming object
    @discardableResult
    public func receive(_ completion: @escaping (Result<Request.OutputType, StreamingError>) -> Void) -> Self {
        start(for: .receive) { [weak self] result in
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
    /// - Parameter completion: closure called when completed connection
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
    /// - Parameter completion: closure called when receive data from server
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
