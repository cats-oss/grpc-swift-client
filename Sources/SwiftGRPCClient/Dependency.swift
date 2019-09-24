//
//  Dependency.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2018/05/04.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import SwiftGRPC

public protocol Dependency {
    /// It is possible to monitor all requests by injecting it when creating `Session`.
    /// Processing can be interrupted as necessary.
    ///
    /// - Parameter metadata: Metadata to be sent
    /// - Returns: Metadata changed as necessary
    /// - Throws: Error when intercepting request
    func intercept(metadata: Metadata) throws -> Metadata

    /// Reconnect when send or receive streaming if connection failed. Default is true.
    var shouldReconnectWhenRetryableStreamingFailed: Bool { get }
}

public extension Dependency {
    func intercept(metadata: Metadata) throws -> Metadata {
        return metadata
    }

    var shouldReconnectWhenRetryableStreamingFailed: Bool {
        return true
    }
}

public class StreamingDependency: Dependency {}
