//
//  EchoUnaryRequest.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/01/19.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation

struct EchoUnaryRequest: Echo_EchoGetRequest {
    var request = Echo_EchoRequest()

    init(text: String) {
        request.text = text
    }
}
