//
//  MethodGenerator.swift
//  protoc-gen-swiftgrpc-client
//
//  Created by Kyohei Ito on 2018/08/09.
//

import SwiftProtobufPluginLibrary

final class MethodGenerator {
    private let method: MethodDescriptor
    private let namer: SwiftProtobufNamer
    private let visibility: String
    private let packageServiceName: String
    private let packageServiceMethodName: String

    init(method: MethodDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer) {
        self.method = method
        self.namer = namer
        visibility = generatorOptions.visibility.sourceSnippet

        if !method.file.package.isEmpty {
            packageServiceName = namer.typePrefix(forFile: method.service.file) + method.service.name
            packageServiceMethodName = packageServiceName + method.name
        } else {
            packageServiceName = method.service.name + method.name
            packageServiceMethodName = method.service.name + method.name
        }
    }

    var methodInputName: String {
        return namer.fullName(message: method.inputType)
    }

    var methodOutputName: String {
        return namer.fullName(message: method.outputType)
    }
}

extension MethodGenerator {
    func generateMethodCase(printer p: inout CodePrinter) {
        p.println("case \(method.name.lowercased()) = \"\(method.name)\"")
    }

    func generateMethodProtocol(printer p: inout CodePrinter) {
        let request = packageServiceMethodName + "Request"
        let _request = "_" + request

        p.println("// MARK: - \(packageServiceName) \(method.name) Request")
        p.printScope("\(visibility)protocol \(_request)") { p in
            p.println("typealias InputType = \(methodInputName)")
            p.println("typealias OutputType = \(methodOutputName)")
        }

        p.println()
        p.println("\(visibility)protocol \(request): \(_request), \(method.streamingType().className)Request {}")

        p.println()
        p.printScope("\(visibility)extension \(request)") { p in
            p.printScope("var method: CallMethod") { p in
                p.println("return \(packageServiceName)Method.\(method.name.lowercased())")
            }
        }
    }
}

private extension MethodDescriptor {
    enum StreamingType: String {
        case unaryStreaming
        case clientStreaming
        case serverStreaming
        case bidirectionalStreaming

        var className: String {
            let name = rawValue
            return name.prefix(1).uppercased() + name.dropFirst()
        }
    }

    func streamingType() -> StreamingType {
        if proto.clientStreaming {
            if proto.serverStreaming {
                return .bidirectionalStreaming
            } else {
                return .clientStreaming
            }
        } else {
            if proto.serverStreaming {
                return .serverStreaming
            } else {
                return .unaryStreaming
            }
        }
    }

}
