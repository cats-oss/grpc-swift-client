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

    var call: CallType { get }
    var request: Request { get }
    var dependency: Dependency { get }

    /// Start connection to server. Does not have to call this because it is called internally.
    ///
    /// - Parameter completion: closure called when started connection
    func start(_ completion: @escaping (Result<CallResult?>) -> Void)

    /// Abort connection to server
    func cancel()

    /// Discard internally held `Call` objects.
    func refresh()
}

open class Stream<R: Request>: Streaming {
    public typealias Request = R
    public typealias Message = R.Message

    private let channel: ChannelType
    private(set) public var call: CallType
    public let request: Request
    public let dependency: Dependency
    private let task = CompletionTask<Result<CallResult?>>()

    public required init(channel: ChannelType, request: Request, dependency: Dependency) {
        self.channel = channel
        self.request = request
        self.call = channel.makeCall(request.method, timeout: request.timeout)
        self.dependency = dependency
    }

    public func start(_ completion: @escaping (Result<CallResult?>) -> Void) {
        guard task.next(completion) else {
            return
        }

        do {
            switch request.style {
            case .unary:
                try call.start(request, dependency: dependency) { response in
                    if response.statusCode == .ok {
                        self.task.complete(.success(response))
                    } else {
                        self.task.complete(.failure(RPCError.callError(response)))
                    }
                }

            case .serverStreaming, .clientStreaming, .bidiStreaming:
                try call.start(request, dependency: dependency, completion: nil)
                task.complete(.success(nil))

            }
        } catch {
            task.complete(.failure(error))
        }
    }

    open func cancel() {
        call.cancel()
    }

    open func refresh() {
        call = channel.makeCall(request.method, timeout: request.timeout)
        task.cancel()
    }
}

extension Streaming where Request: UnaryRequest {
    /// For Unary connection
    ///
    /// - Parameter completion: closure called when completed connection
    /// - Returns: Streaming object
    @discardableResult
    public func data(_ completion: @escaping (Result<Request.OutputType>) -> Void) -> Self {
        start { [weak self] result in
            switch result {
            case .success(let result):
                guard let me = self else {
                    return
                }

                if let data = result?.resultData, let parsedData = try? me.request.parse(data: data) {
                    completion(.success(parsedData))
                } else {
                    if let result = result {
                        completion(.failure(RPCError.callError(result)))
                    } else {
                        completion(.failure(RPCError.invalidMessageReceived))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
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
    public func send(_ message: Message, completion: ((Result<Void>) -> Void)? = nil) -> Self {
        start { [weak self] result in
            guard let me = self else {
                return
            }

            if case .failure(let error) = result {
                completion?(.failure(error))
                return
            }

            do {
                try me.call.sendMessage(data: me.request.serialized(message)) { error in
                    // completion?(operationGroup.success ? nil : CallError.unknown)
                    if let error = error {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(()))
                    }
                }
            } catch {
                completion?(.failure(error))
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
    public func receive(_ completion: @escaping (Result<Request.OutputType?>) -> Void) -> Self {
        start { [weak self] result in
            guard let me = self else {
                return
            }

            if case .failure(let error) = result {
                return completion(.failure(error))
            }

            func receive(call: CallType, request: Request) {
                do {
                    try call.receiveMessage { callResult in
                        guard let data = callResult.resultData else {
                            if callResult.success {
                                completion(.success(nil))
                            } else {
                                completion(.failure(RPCError.callError(callResult)))
                            }
                            return
                        }

                        if let parsedData = try? request.parse(data: data) {
                            completion(.success(parsedData))
                            receive(call: call, request: request)
                        } else {
                            completion(.failure(RPCError.invalidMessageReceived))
                        }
                    }
                } catch {
                    completion(.failure(error))
                }
            }

            receive(call: me.call, request: me.request)
        }
        return self
    }
}

extension Streaming where Request: CloseRequest {
    /// For closing streaming
    ///
    /// - Parameter completion: closure called when completed connection
    public func close(_ completion: @escaping (Result<Void>) -> Void) {
        start { [weak self] result in
            guard let me = self else {
                return
            }

            if case .failure(let error) = result {
                return completion(.failure(error))
            }

            do {
                try me.call.close {
                    me.refresh()
                    completion(.success(()))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension Streaming where Request: CloseAndReciveRequest {
    /// For closing streaming and receive data from server
    ///
    /// - Parameter completion: closure called when receive data from server
    public func closeAndReceive(_ completion: @escaping (Result<Request.OutputType>) -> Void) {
        start { [weak self] result in
            guard let me = self else {
                return
            }

            if case .failure(let error) = result {
                return completion(.failure(error))
            }

            do {
                try me.call.closeAndReceiveMessage { callResult in
                    guard let data = callResult.resultData else {
                        return completion(.failure(RPCError.callError(callResult)))
                    }
                    if let parsedData = try? me.request.parse(data: data) {
                        me.refresh()
                        completion(.success(parsedData))
                    } else {
                        completion(.failure(RPCError.invalidMessageReceived))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}
