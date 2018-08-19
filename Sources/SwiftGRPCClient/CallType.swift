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
    func start<R: Request>(_ request: R, completion: ((CallResult) -> Void)?) throws
    func sendMessage(data: Data, completion: ((Error?) -> Void)?) throws
    func receiveMessage(completion: @escaping (CallResult) -> Void) throws
    func closeAndReceiveMessage(completion: @escaping (CallResult) -> Void) throws
    func close(completion: (() -> Void)?) throws
}

extension Call: CallType {
    public func start<R: Request>(_ request: R, completion: ((CallResult) -> Void)?) throws {
        let metadata = try request.intercept(metadata: request.metadata.copy())
        switch request.style {
        case .unary, .serverStreaming:
            try start(request.style, metadata: metadata, message: request.serialized(), completion: completion)

        case .clientStreaming, .bidiStreaming:
            try start(request.style, metadata: metadata, message: nil, completion: completion)

        }
    }
}
