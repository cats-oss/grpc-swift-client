//
//  EchoUnaryRequest.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/08/24.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation
import SwiftGRPC

class EchoProvider: Echo_EchoProvider {
    func timestamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }

    func get(request: Echo_EchoRequest, session _: Echo_EchoGetSession) throws -> Echo_EchoResponse {
        var response = Echo_EchoResponse()
        response.text = "[\(timestamp())] get: " + request.text
        return response
    }

    func expand(request: Echo_EchoRequest, session: Echo_EchoExpandSession) throws -> ServerStatus? {
        while true {
            var error: Error?
            var response = Echo_EchoResponse()
            response.text = "[\(timestamp())] expand: \(request.text)"
            let sem = DispatchSemaphore(value: 0)
            try session.send(response) {
                error = $0
                sem.signal()
            }

            _ = sem.wait(timeout: DispatchTime.distantFuture)
            if let error = error {
                print("expand error: \(error)")
                break
            }

            sleep(1)
        }

        return .ok
    }

    func collect(session: Echo_EchoCollectSession) throws -> Echo_EchoResponse? {
        var parts: [String] = []
        while true {
            do {
                guard let request = try session.receive() else { break }
                parts.append(request.text)
            } catch {
                print("collect error: \(error)")
                break
            }
        }

        var response = Echo_EchoResponse()
        response.text = "[\(timestamp())] collect: " + parts.joined(separator: " ")
        return response
    }

    func update(session: Echo_EchoUpdateSession) throws -> ServerStatus? {
        while true {
            do {
                guard let request = try session.receive() else { break }
                var response = Echo_EchoResponse()
                response.text = "[\(timestamp())] update: \(request.text)"
                try session.send(response) {
                    if let error = $0 {
                        print("update error: \(error)")
                    }
                }
            } catch {
                print("update error: \(error)")
                break
            }
        }

        return .ok
    }
}
