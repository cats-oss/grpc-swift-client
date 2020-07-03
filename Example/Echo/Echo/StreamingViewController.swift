import UIKit
import GRPCClient

class StreamingViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!

    var style: CallStyle?

    var count = 0

    var unary: CancellableStreaming?
    lazy var clientStream = Session.shared.stream(with: EchoClientRequest())
    lazy var serverStream = Session.shared.stream(with: EchoServerRequest())
    lazy var bidiStream = Session.shared.stream(with: EchoBidirectionalRequest())

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

        title = "Streaming"

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
            unary = Session.shared.data(with: EchoUnaryRequest(text: "\(count)")) { [weak self] in
                self?.print($0)
            }

        case .serverStreaming:
            serverStream
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
            unary?.cancel { [weak self] in
                self?.print($0)
            }

        case .serverStreaming:
            serverStream.cancel() { [weak self] in
                self?.print($0)
            }

        case .clientStreaming:
            clientStream
                .sendEnd { [weak self] in
                    self?.print($0)
                }

        case .bidiStreaming:
            bidiStream
                .sendEnd { [weak self] in
                    self?.print($0)
                }

        }
    }

    @IBAction func cleanButtonDidTap(sender: UIButton) {
        textView.text = ""
    }
}
