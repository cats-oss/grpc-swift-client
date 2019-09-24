//
//  Stream.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2017/10/26.
//  Copyright © 2017年 CyberAgent, Inc. All rights reserved.
//

import Foundation
import SwiftGRPC

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

        guard (type.isReceiveing && type.isRetryable) || networkMonitor?.isReachable ?? false else {
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

    private func refresh() {
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

        guard type.isRetryable && networkMonitor?.isReachable ?? false else {
            return false
        }

        let isRetryable = retryCount >= 1
        guard isRetryable else { return false }
        retryCount -= 1

        queue.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let me = self else { return }

            if me.networkMonitor?.isReachable ?? false {
                me.refresh()

                if type.isReceiveing {
                    me.start(for: type, completion: completion)
                }
            }
        }

        return true
    }

    private func monitoringNetowrk(for type: MessageType, completion: @escaping (Result<CallResult?, StreamingError>) -> Void) {
        switch type {
        case .send(true):
            if networkMonitor?.stateHandler == nil {
                networkMonitor?.stateHandler = { [weak self] state in
                    if state.isReachable {
                        self?.resetRetryCount()
                        self?.refresh()
                    }
                }
            }

        case .receive(true):
            networkMonitor?.stateHandler = { [weak self] state in
                if state.isReachable {
                    self?.resetRetryCount()
                    self?.refresh()

                    if type.isRetryable {
                        self?.start(for: type, completion: completion)
                    }
                }
            }

        case .data, .close, .send, .receive:
            break
        }
    }
}
