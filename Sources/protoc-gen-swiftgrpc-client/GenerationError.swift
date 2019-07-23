//
//  GenerationError.swift
//  protoc-gen-swiftgrpc-client
//
//  Created by Kyohei Ito on 2019/07/23.
//

enum GenerationError: Error {
    /// Raised when parsing the parameter string and found an unknown key
    case unknownParameter(name: String)
    /// Raised when a parameter was giving an invalid value
    case invalidParameterValue(name: String, value: String)
    /// Raised to wrap another error but provide a context message.
    case wrappedError(message: String, error: Error)
}
