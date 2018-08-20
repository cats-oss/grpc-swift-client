//
//  Dependency.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2018/05/04.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import SwiftGRPC

public protocol Dependency {
    func intercept(metadata: Metadata) throws -> Metadata
}

public extension Dependency {
    func intercept(metadata: Metadata) throws -> Metadata {
        return metadata
    }
}
