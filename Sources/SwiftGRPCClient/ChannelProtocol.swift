//
//  ChannelProtocol.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2018/02/02.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation
import SwiftGRPC

public protocol ChannelProtocol: class {
    var timeout: TimeInterval { get set }

    func makeCall(_ method: CallMethod, timeout: TimeInterval?) throws -> CallProtocol
}

extension Channel: ChannelProtocol {
    public func makeCall(_ method: CallMethod, timeout: TimeInterval?) throws -> CallProtocol {
        return try makeCall(method.path, host: method.host, timeout: timeout)
    }
}
