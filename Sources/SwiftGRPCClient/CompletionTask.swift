//
//  CompletionTask.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/03/07.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

import Foundation

final class CompletionTask<Result> {
    private let lock = NSLock()
    private var observers: ContiguousArray<(Result) -> Void>? = []
    private var result: Result?

    func next(_ closure: @escaping (Result) -> Void) -> Bool {
        let token: (result: Result?, isEmpty: Bool) = _next(closure)
        if let result = token.result {
            closure(result)
            return false
        }
        return token.isEmpty
    }

    private func _next(_ closure: @escaping (Result) -> Void) -> (Result?, Bool) {
        lock.lock(); defer { lock.unlock() }
        let isEmpty = (observers?.count == 0)
        observers?.append(closure)
        return (result, isEmpty)
    }

    func complete(_ result: Result) {
        _complete(result)?.forEach { $0(result) }
    }

    private func _complete(_ result: Result) -> ContiguousArray<(Result) -> Void>? {
        lock.lock(); defer { lock.unlock() }
        self.result = result
        let copy = observers
        observers = nil
        return copy
    }

    func cancel() {
        lock.lock(); defer { lock.unlock() }
        result = nil
        observers = []
    }
}
