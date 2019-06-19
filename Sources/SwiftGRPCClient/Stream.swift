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

    var call: Result<CallType, StreamingError> { get }
    var request: Request { get }
    var dependency: Dependency { get }
    var isCanceled: Bool { get }

    /// Start connection to server. Does not have to call this because it is called internally.
    ///
    /// - Parameter completion: closure called when started connection
    func start(_ completion: @escaping (Result<CallResult?, StreamingError>) -> Void)

    /// Abort connection to server
    func cancel()

    /// Discard internally held `Call` objects.
    func refresh()
}

open class Stream<R: Request>: Streaming {
    public typealias Request = R
    public typealias Message = R.Message

    private let channel: ChannelType
    private(set) public var call: Result<CallType, StreamingError>
    public let request: Request
    public let dependency: Dependency
    private let metadata: Metadata
    private(set) public var isCanceled = false
    private let task = CompletionTask<Result<CallResult?, StreamingError>>()

    public required init(channel: ChannelType, request: Request, dependency: Dependency, metadata: Metadata) {
        self.channel = channel
        self.request = request
        do {
            self.call = .success(try channel.makeCall(request.method, timeout: request.timeout))
        } catch {
            self.call = .failure(.callCreationFailed)
        }
        self.dependency = dependency
        self.metadata = metadata
    }

    public func start(_ completion: @escaping (Result<CallResult?, StreamingError>) -> Void) {
        guard task.next(completion) else {
            return
        }

        do {
            switch request.style {
            case .unary:
                try call.get().start(request, dependency: dependency, metadata: metadata) { response in
                    if response.statusCode == .ok {
                        self.task.complete(.success(response))
                    } else {
                        self.task.complete(.failure(.responseError(response)))
                    }
                }

            case .serverStreaming, .clientStreaming, .bidiStreaming:
                try call.get().start(request, dependency: dependency, metadata: metadata, completion: nil)
                task.complete(.success(nil))

            }
        } catch {
            task.complete(.failure(StreamingError(error)))
        }
    }

    open func cancel() {
        isCanceled = true
        try? call.get().cancel()
    }

    open func refresh() {
        do {
            call = .success(try channel.makeCall(request.method, timeout: request.timeout))
        } catch {
            call = .failure(.callCreationFailed)
        }
        task.cancel()
        isCanceled = false
    }
}

extension Streaming where Request: UnaryRequest {
    /// For Unary connection
    ///
    /// - Parameter completion: closure called when completed connection
    /// - Returns: Streaming object
    @discardableResult
    public func data(_ completion: @escaping (Result<Request.OutputType, StreamingError>) -> Void) -> Self {
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
                        completion(.failure(.responseError(result)))
                    } else {
                        completion(.failure(.invalidMessageReceived))
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
    public func send(_ message: Message, completion: ((Result<Void, StreamingError>) -> Void)? = nil) -> Self {
        start { [weak self] result in
            guard let me = self else {
                return
            }

            if case .failure(let error) = result {
                completion?(.failure(error))
                return
            }

            do {
                try me.call.get().sendMessage(data: me.request.serialized(message)) { error in
                    // completion?(operationGroup.success ? nil : CallError.unknown)
                    if let error = error {
                        completion?(.failure(StreamingError(error)))
                    } else {
                        completion?(.success(()))
                    }
                }
            } catch {
                completion?(.failure(StreamingError(error)))
            }
        }
        return self
    }
}

extension Streaming where Request: ReceiveRequest {
    private func retry(_ completion: @escaping (Result<CallResult, StreamingError>) -> Void) {
        refresh()
        start { [weak self] result in
            if case .failure(let error) = result {
                return completion(.failure(error))
            }

            do {
                try self?.call.get().receiveMessage { callResult in
                    // retry when result data is nil and result is not failure
                    if callResult.resultData == nil && callResult.success && self?.isCanceled == false {
                        self?.retry(completion)
                    } else {
                        completion(.success(callResult))
                    }
                }
            } catch {
                completion(.failure(StreamingError(error)))
            }
        }
    }

    /// For receive message from server
    ///
    /// - Parameter completion: closure called when receive data from server
    /// - Returns: Streaming object
    @discardableResult
    public func receive(_ completion: @escaping (Result<Request.OutputType?, StreamingError>) -> Void) -> Self {
        start { [weak self] result in
            if case .failure(let error) = result {
                return completion(.failure(error))
            }

            func onCompleted(_ result: Result<CallResult, StreamingError>) {
                switch result {
                case .success(let callResult):
                    guard let data = callResult.resultData else {
                        if callResult.success {
                            completion(.success(nil))
                        } else {
                            completion(.failure(.responseError(callResult)))
                        }
                        return
                    }

                    if let parsedData = try? self?.request.parse(data: data) {
                        completion(.success(parsedData))
                        receive()
                    } else {
                        completion(.failure(.invalidMessageReceived))
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
            }

            func receive() {
                do {
                    try self?.call.get().receiveMessage { callResult in
                        // retry when result data is nil and request is retryable
                        if callResult.resultData == nil && self?.request.isRetryable == true && self?.isCanceled == false {
                            self?.retry(onCompleted)
                        } else {
                            onCompleted(.success(callResult))
                        }
                    }
                } catch {
                    onCompleted(.failure(StreamingError(error)))
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
        start { [weak self] result in
            guard let me = self else {
                return
            }

            if case .failure(let error) = result {
                completion?(.failure(error))
                return
            }

            do {
                try me.call.get().close {
                    me.cancel()
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
        start { [weak self] result in
            guard let me = self else {
                return
            }

            if case .failure(let error) = result {
                return completion(.failure(error))
            }

            do {
                try me.call.get().closeAndReceiveMessage { callResult in
                    me.cancel()
                    guard let data = callResult.resultData else {
                        return completion(.failure(.responseError(callResult)))
                    }
                    if let parsedData = try? me.request.parse(data: data) {
                        completion(.success(parsedData))
                    } else {
                        completion(.failure(.invalidMessageReceived))
                    }
                }
            } catch {
                completion(.failure(StreamingError(error)))
            }
        }
    }
}
