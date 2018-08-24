//
//  StreamingViewController.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/01/23.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import UIKit
import SwiftGRPC
import SwiftGRPCClient

class StreamingViewController: UIViewController {
    var style: CallStyle?

    var count = 0

    var unaryStream: SwiftGRPCClient.Stream<EchoUnaryRequest>?
    var clientStream = Session.shared.stream(with: EchoClientRequest())
    var serverStream: SwiftGRPCClient.Stream<EchoServerRequest>?
    var bidiStream = Session.shared.stream(with: EchoBidirectionalRequest())

    deinit {
        unaryStream?.cancel()
        clientStream.cancel()
        serverStream?.cancel()
        bidiStream.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if style == .bidiStreaming {
            bidiStream
                .receive {
                    print($0)
                }
        }
    }

    @IBAction func startButtonDidTap(sender: UIButton) {
        guard let style = style else { return }

        count += 1

        switch style {
        case .unary:
            unaryStream = Session.shared.stream(with: EchoUnaryRequest(text: "send message"))
                .data {
                    print($0)
                }

        case .serverStreaming:
            serverStream = Session.shared.stream(with: EchoServerRequest())
                .receive {
                    print($0)
                }

        case .clientStreaming:
            clientStream
                .send("\(count)") { result in
                    print(result)
                }

        case .bidiStreaming:
            bidiStream
                .send("\(count)") {
                    print($0)
                }

        }
    }

    @IBAction func stopButtonDidTap(sender: UIButton) {
        guard let style = style else { return }

        switch style {
        case .unary:
            unaryStream?.cancel()

        case .serverStreaming:
            serverStream?.cancel()

        case .clientStreaming:
            clientStream
                .closeAndReceive {
                    print($0)
                }

        case .bidiStreaming:
            bidiStream
                .close { [weak self] in
                    print($0)
                    self?.bidiStream
                        .receive {
                            print($0)
                        }
                }

        }
    }
}
