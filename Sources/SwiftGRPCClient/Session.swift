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
    public var timeout: TimeInterval {
        get {
            return channel.timeout
        } set {
            channel.timeout = newValue
        }
    }

    public convenience init(address: String, dependency: Dependency? = nil) {
        self.init(channel: Channel(address: address, secure: false), dependency: dependency ?? StreamingDependency())
    }

    public convenience init(address: String, certificates: String, dependency: Dependency? = nil) {
        self.init(channel: Channel(address: address, certificates: certificates), dependency: dependency ?? StreamingDependency())
    }

    init(channel: ChannelType, dependency: Dependency) {
        self.channel = channel
        self.dependency = dependency
    }

    open func stream<R: Request>(with request: R) -> Stream<R> {
        return Stream(channel: channel, request: request, dependency: dependency)
    }
}
