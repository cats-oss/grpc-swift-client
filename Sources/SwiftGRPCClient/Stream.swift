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
    var messageQueue: MessageQueue<Message> { get }

    func start(_ completion: @escaping (Result<CallResult?>) -> Void)
    func cancel()
    func refresh()
}

open class Stream<R: Request>: Streaming {
    public typealias Request = R

    private let channel: ChannelType
    private(set) public var call: CallType
    public let request: Request
    public let dependency: Dependency
    public let messageQueue = MessageQueue<Request.Message>()
    private let task = CompletionTask<Result<CallResult?>>()

    public required init(channel: ChannelType, request: Request, dependency: Dependency) {
        self.channel = channel
        self.request = request
        self.call = channel.makeCall(request.method)
        self.dependency = dependency
    }

    public func start(_ completion: @escaping (Result<CallResult?>) -> Void) {
        guard task.next(completion) else {
            return
        }

        do {
            switch request.style {
            case .unary:
                try call.start(request) { response in
                    if response.statusCode == .ok {
                        self.task.complete(.success(response))
                    } else {
                        self.task.complete(.failure(RPCError.callError(response)))
                    }
                }

            case .serverStreaming, .clientStreaming, .bidiStreaming:
                try call.start(request, completion: nil)
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
        call = channel.makeCall(request.method)
        task.cancel()
    }
}

extension Streaming where Request: UnaryRequest {
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
    private func retry(_ message: Message, completion: @escaping (Error?) -> Void) {
        refresh()
        start { [weak self] result in
            guard let me = self else {
                return
            }

            if case .failure(let error) = result {
                return completion(error)
            }

            do {
                try me.call.sendMessage(data: me.request.serialized(message), completion: completion)
            } catch {
                completion(error)
            }
        }
    }

    @discardableResult
    public func send(_ message: Message, completion: @escaping (Result<Void>) -> Void) -> Self {
        start { [weak self] result in
            guard let me = self else {
                return
            }

            if case .failure(let error) = result {
                return completion(.failure(error))
            }

            func sendRecursive(_ message: Message, completion: @escaping (Result<Void>) -> Void) {
                func onCompleted(_ error: Error? = nil) {
                    // completion?(operationGroup.success ? nil : CallError.unknown)
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                    me.messageQueue.popFirst().map(sendRecursive)
                }

                do {
                    try me.call.sendMessage(data: me.request.serialized(message)) { error in
                        if error == nil {
                            onCompleted()
                        } else {
                            me.retry(message, completion: onCompleted)
                        }
                    }
                } catch {
                    me.retry(message, completion: onCompleted)
                }
            }

            me.messageQueue.next((message, completion)).map(sendRecursive)
        }
        return self
    }
}

extension Streaming where Request: ReceiveRequest {
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
                    completion(.success(()))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension Streaming where Request: CloseAndReciveRequest {
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
