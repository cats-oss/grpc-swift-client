//
//  Session+Shared.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/08/24.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import SwiftGRPCClient

extension Session {
    static let shared = Session(address: "localhost:8082")
}
