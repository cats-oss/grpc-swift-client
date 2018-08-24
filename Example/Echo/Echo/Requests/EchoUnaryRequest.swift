//
//  EchoUnaryRequest.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/01/19.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation

struct EchoUnaryRequest: Echo_EchoGetRequest {
    var text = ""

    func buildRequest() -> Echo_EchoRequest {
        var request = Echo_EchoRequest()
        request.text = text
        return request
    }
}
