//
//  CallMethod.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2018/03/29.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation

public protocol CallMethod {
    static var service: String { get }
    var host: String { get }
    var path: String { get }
}

public extension CallMethod where Self: RawRepresentable {
    var host: String {
        return ""
    }

    var path: String {
        return "/\(Self.service)/\(rawValue)"
    }
}
