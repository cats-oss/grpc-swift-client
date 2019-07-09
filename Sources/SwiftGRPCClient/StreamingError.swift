//
//  StreamingError.swift
//  BoringSSL
//
//  Created by Kyohei Ito on 2019/06/20.
//

import Foundation
import SwiftGRPC

public enum StreamingError: Error {
    case callCreationFailed
    case invalidMessageReceived
    case responseError(CallResult)
    case callError(CallError)
    case unknownError(Error)
    case noMessageReceived
    case notConnectedToInternet

    init(_ error: Error) {
        switch error {
        case let error as StreamingError:
            self = error

        case let error as CallError:
            self = .callError(error)

        case let error:
            self = .unknownError(error)
        }
    }
}
