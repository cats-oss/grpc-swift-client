import UIKit
import GRPC

enum CallStyle {
    case unary, serverStreaming, clientStreaming, bidiStreaming
}

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    let items: [[CallStyle]] = [
        [.unary, .serverStreaming, .clientStreaming, .bidiStreaming],
        [.unary, .serverStreaming, .clientStreaming, .bidiStreaming]
    ]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        cell.textLabel?.text = (indexPath.section == 0 ? "Streaming" : "Echo") + " \(items[indexPath.section][indexPath.row])"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            performSegue(withIdentifier: "Streaming", sender: nil)
        } else if indexPath.section == 1 {
            performSegue(withIdentifier: "Echo", sender: nil)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow {
            if let controller = segue.destination as? StreamingViewController {
                controller.style = items[indexPath.section][indexPath.row]
            } else if let controller = segue.destination as? EchoViewController {
                controller.style = items[indexPath.section][indexPath.row]
            }
        }
    }
}
