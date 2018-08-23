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

open class Session: SessionType {
    private class StreamingDependency: Dependency {}

    private let channel: ChannelType
    private let dependency: Dependency

    /// A timeout value in seconds
    public var timeout: TimeInterval {
        get {
            return channel.timeout
        } set {
            channel.timeout = newValue
        }
    }

    /// Initializes a gRPC Session
    ///
    /// - Parameters:
    ///   - address: the address of the server to be called
    ///   - dependency: object conforming to Dependency protocol
    public convenience init(address: String, dependency: Dependency? = nil) {
        self.init(channel: Channel(address: address, secure: false), dependency: dependency ?? StreamingDependency())
    }

    /// Initializes a gRPC Session
    ///
    /// - Parameters:
    ///   - address: the address of the server to be called
    ///   - certificates: a PEM representation of certificates to use
    ///   - dependency: object conforming to Dependency protocol
    public convenience init(address: String, certificates: String, dependency: Dependency? = nil) {
        self.init(channel: Channel(address: address, certificates: certificates), dependency: dependency ?? StreamingDependency())
    }

    init(channel: ChannelType, dependency: Dependency) {
        self.channel = channel
        self.dependency = dependency
    }

    /// Create a Stream
    ///
    /// - Parameter request: object conforming to Request protocol
    /// - Returns: object for server streaming
    open func stream<R: Request>(with request: R) -> Stream<R> {
        return Stream(channel: channel, request: request, dependency: dependency)
    }
}
