//
//  ChannelType.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2018/02/02.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation
import SwiftGRPC

public protocol ChannelType: class {
    var timeout: TimeInterval { get set }

    func makeCall(_ method: CallMethod) -> CallType
}

extension Channel: ChannelType {
    public func makeCall(_ method: CallMethod) -> CallType {
        return makeCall(method.path, host: method.host)
    }
}
