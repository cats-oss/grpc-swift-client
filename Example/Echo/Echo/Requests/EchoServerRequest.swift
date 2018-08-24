//
//  EchoServerRequest.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/01/19.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation

struct EchoServerRequest: Echo_EchoExpandRequest {
  var text = "server streaming request"

  func buildRequest() -> InputType {
      var request = InputType()
      request.text = text
      return request
  }
}
