//
//  Session.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2017/10/26.
//  Copyright © 2017年 CyberAgent, Inc. All rights reserved.
//

import Foundation
import SwiftGRPC

public protocol SessionType {
    func stream<R: Request>(with request: R) -> Stream<R>
}

open class Session: ServiceClientBase, SessionType {
    public var dependency: Dependency = StreamingDependency()

    /// Create a Stream
    ///
    /// - Parameter request: object conforming to Request protocol
    /// - Returns: object for server streaming
    open func stream<R: Request>(with request: R) -> Stream<R> {
        return Stream(channel: channel, request: request, dependency: dependency)
    }
}
