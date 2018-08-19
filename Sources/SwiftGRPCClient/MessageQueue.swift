//
//  MessageQueue.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/06/10.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation

public final class MessageQueue<Message> {
    typealias Element = (Message, (Result<Void>) -> Void)
    private let lock = NSLock()
    private var queue: ContiguousArray<Element> = []

    func next(_ element: Element) -> Element? {
        lock.lock(); defer { lock.unlock() }
        queue.append(element)
        return queue.count <= 1 ? element : nil
    }

    func popFirst() -> Element? {
        lock.lock(); defer { lock.unlock() }
        if queue.count > 0 {
            queue.removeFirst()
            return queue.first
        } else {
            return nil
        }
    }
}
