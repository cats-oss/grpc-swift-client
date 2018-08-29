//
//  CallType.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2017/10/28.
//  Copyright © 2017年 CyberAgent, Inc. All rights reserved.
//

import Foundation
import SwiftGRPC

public protocol CallType {
    func cancel()
    func start<R: Request>(_ request: R, dependency: Dependency, metadata: Metadata, completion: ((CallResult) -> Void)?) throws
    func sendMessage(data: Data, completion: ((Error?) -> Void)?) throws
    func receiveMessage(completion: @escaping (CallResult) -> Void) throws
    func closeAndReceiveMessage(completion: @escaping (CallResult) -> Void) throws
    func close(completion: (() -> Void)?) throws
}

extension Call: CallType {
    public func start<R: Request>(_ request: R, dependency: Dependency, metadata: Metadata, completion: ((CallResult) -> Void)?) throws {
        var metadata = try dependency.intercept(metadata: metadata.copy())
        metadata = try request.intercept(metadata: metadata)
        switch request.style {
        case .unary, .serverStreaming:
            try start(request.style, metadata: metadata, message: request.serialized(), completion: completion)

        case .clientStreaming, .bidiStreaming:
            try start(request.style, metadata: metadata, message: nil, completion: completion)

        }
    }
}
