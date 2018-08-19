//
//  GeneratorOptions.swift
//  protoc-gen-swiftgrpc-client
//
//  Created by Kyohei Ito on 2018/08/09.
//

import Foundation

final class GeneratorOptions {
    enum Visibility: String {
        case `internal` = "Internal"
        case `public` = "Public"

        var sourceSnippet: String {
            switch self {
            case .internal:
                return ""
            case .public:
                return "public "
            }
        }
    }

    let visibility: Visibility

    init(parameter: String?) throws {
        var visibility = Visibility.internal
        try parseParameter(string: parameter).forEach { pair in
            switch pair.key {
            case "Visibility":
                if let value = Visibility(rawValue: pair.value) {
                    visibility = value
                } else {
                    throw GenerationError.invalidParameterValue(name: pair.key, value: pair.value)
                }

            default:
                throw GenerationError.unknownParameter(name: pair.key)
            }
        }

        self.visibility = visibility
    }
}

