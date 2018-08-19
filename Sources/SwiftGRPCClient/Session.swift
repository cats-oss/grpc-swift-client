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

public final class Session: SessionType {
    private let channel: ChannelType
    var timeout: TimeInterval {
        get {
            return channel.timeout
        } set {
            channel.timeout = newValue
        }
    }

    public convenience init(address: String) {
        self.init(channel: Channel(address: address, secure: false))
    }

    public convenience init(address: String, certificates: String) {
        self.init(channel: Channel(address: address, certificates: certificates))
    }

    init(channel: ChannelType) {
        self.channel = channel
    }

    public func stream<R: Request>(with request: R) -> Stream<R> {
        return Stream(channel: channel, request: request, dependency: StreamingDependency())
    }
}
