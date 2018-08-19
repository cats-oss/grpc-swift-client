//
//  Result.swift
//  Echo
//
//  Created by Kyohei Ito on 2018/08/20.
//  Copyright © 2018年 CyberAgent, Inc. All rights reserved.
//

public enum Result<T> {
    case success(T)
    case failure(Error)

    var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }

    var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}
