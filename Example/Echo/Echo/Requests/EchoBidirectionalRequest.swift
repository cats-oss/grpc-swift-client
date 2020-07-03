//
//  EchoBidirectionalRequest.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/01/19.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation

struct EchoBidirectionalRequest: Echo_EchoUpdateRequest {
    var request = Echo_EchoRequest()

    func buildRequest(_ message: String) -> Request {
        var request = self.request
        request.text = message
        return request
    }
}
