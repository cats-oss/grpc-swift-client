//
//  ServiceGenerator.swift
//  protoc-gen-swiftgrpc-client
//
//  Created by Kyohei Ito on 2018/08/09.
//

import SwiftProtobufPluginLibrary

final class ServiceGenerator {
    private let service: ServiceDescriptor
    private let generatorOptions: GeneratorOptions
    private let namer: SwiftProtobufNamer
    private let visibility: String
    private let packageServiceName: String
    private let servicePath: String

    init(service: ServiceDescriptor, generatorOptions: GeneratorOptions, namer: SwiftProtobufNamer) {
        self.service = service
        self.generatorOptions = generatorOptions
        self.namer = namer
        visibility = generatorOptions.visibility.sourceSnippet

        if !service.file.package.isEmpty {
            packageServiceName = namer.typePrefix(forFile: service.file) + service.name
            servicePath = service.file.package + "." + service.name
        } else {
            packageServiceName = service.name
            servicePath = service.name
        }
    }
}

extension ServiceGenerator {
    func generateService(printer p: inout CodePrinter) {
        p.println("// MARK: - \(service.name) Request Method")
        p.printScope("enum \(packageServiceName)Method: String, CallMethod") { p in
            service.methods.forEach {
                MethodGenerator(method: $0, generatorOptions: generatorOptions, namer: namer).generateMethodCase(printer: &p)
            }
            p.println()
            p.println("static let service = \"\(servicePath)\"")
        }

        p.println()
        service.methods.forEach {
            MethodGenerator(method: $0, generatorOptions: generatorOptions, namer: namer).generateMethodProtocol(printer: &p)
            p.println()
        }
    }
}
