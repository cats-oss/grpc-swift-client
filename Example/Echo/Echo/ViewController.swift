//
//  ViewController.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/08/24.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import UIKit
import SwiftGRPC

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    let items: [CallStyle] = [.unary, .serverStreaming, .clientStreaming, .bidiStreaming]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        cell.textLabel?.text = "\(items[indexPath.row])"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "Streaming", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow, let controller = segue.destination as? StreamingViewController {
            controller.style = items[indexPath.row]
        }
    }
}
