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
    @IBOutlet weak var textView: UITextView!

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

    func print<T>(_ value: T) {
        DispatchQueue.main.async {
            self.textView.text = "\(value)\n" + self.textView.text
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if style == .bidiStreaming {
            bidiStream
                .receive { [weak self] in
                    self?.print($0)
                }
        }
    }

    @IBAction func startButtonDidTap(sender: UIButton) {
        guard let style = style else { return }

        count += 1

        switch style {
        case .unary:
            unaryStream = Session.shared.stream(with: EchoUnaryRequest(text: "send message"))
                .data { [weak self] in
                    self?.print($0)
                }

        case .serverStreaming:
            serverStream = Session.shared.stream(with: EchoServerRequest())
                .receive { [weak self] in
                    self?.print($0)
                }

        case .clientStreaming:
            clientStream
                .send("\(count)") { [weak self] in
                    self?.print($0)
                }

        case .bidiStreaming:
            bidiStream
                .send("\(count)") { [weak self] in
                    self?.print($0)
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
                .closeAndReceive { [weak self] in
                    self?.print($0)
                }

        case .bidiStreaming:
            bidiStream
                .close { [weak self] in
                    self?.print($0)
                }

        }
    }
}
