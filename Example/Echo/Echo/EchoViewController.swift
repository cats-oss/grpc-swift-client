import UIKit
import GRPC

class EchoViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!

    var style: CallStyle?

    var count = 0

    var unary: UnaryCall<Echo_EchoRequest, Echo_EchoResponse>?
    lazy var clientStream = Echo_EchoClient.shared.collect()
    var serverStream: ServerStreamingCall<Echo_EchoRequest, Echo_EchoResponse>?
    lazy var bidiStream = Echo_EchoClient.shared.update { [weak self] in
        self?.print($0)
    }

    func print<T>(_ value: T) {
        if Thread.isMainThread {
            textView.text = "\(value)\n" + textView.text
        } else {
            DispatchQueue.main.sync {
                textView.text = "\(value)\n" + textView.text
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Echo"

        if style == .clientStreaming {
            clientStream.response.whenComplete { [weak self] in
                self?.print($0)
            }
        } else if style == .serverStreaming {
            serverStream = Echo_EchoClient.shared.expand(.with { $0.text = "server streaming request" }) { [weak self] in
                self?.print($0)
            }
        }
    }

    @IBAction func startButtonDidTap(sender: UIButton) {
        guard let style = style else { return }

        count += 1

        switch style {
        case .unary:
            unary = Echo_EchoClient.shared.get(.with { $0.text = "\(count)" })
            unary?.response.whenComplete { [weak self] in
                self?.print($0)
            }

        case .serverStreaming:
            break

        case .clientStreaming:
            clientStream.sendMessage(.with { $0.text = "\(count)" }).whenComplete { [weak self] in
                self?.print($0)
            }

        case .bidiStreaming:
            bidiStream.sendMessage(.with { $0.text = "\(count)" }).whenComplete { [weak self] in
                self?.print($0)
            }

        }
    }

    @IBAction func stopButtonDidTap(sender: UIButton) {
        guard let style = style else { return }

        switch style {
        case .unary:
            unary?.cancel().whenComplete { [weak self] in
                self?.print($0)
            }

        case .serverStreaming:
            serverStream?.cancel().whenComplete { [weak self] in
                self?.print($0)
            }

        case .clientStreaming:
            clientStream.sendEnd().whenComplete { [weak self] in
                self?.print($0)
            }

        case .bidiStreaming:
            bidiStream.sendEnd().whenComplete { [weak self] in
                self?.print($0)
            }

        }
    }

    @IBAction func cleanButtonDidTap(sender: UIButton) {
        textView.text = ""
    }
}
