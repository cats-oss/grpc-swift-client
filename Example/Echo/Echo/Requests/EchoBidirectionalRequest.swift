//
//  EchoBidirectionalRequest.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/01/19.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation

struct EchoBidirectionalRequest: Echo_EchoUpdateRequest {
    func buildRequest(_ message: String) -> InputType {
        var request = InputType()
        request.text = message
        return request
    }
}
