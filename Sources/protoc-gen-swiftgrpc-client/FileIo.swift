//
//  FileIo.swift
//  protoc-gen-swiftgrpc-client
//
//  Created by Kyohei Ito on 2018/08/09.
//

import Foundation

// The I/O code below is derived from Apple's swift-protobuf project.
// https://github.com/apple/swift-protobuf
// BEGIN swift-protobuf derivation

class Stderr {
    static func print(_ s: String) {
        let out = "\(CommandLine.programName): \(s)\n"
        if let data = out.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}

func readFileData(filename: String) throws -> Data {
    let url = URL(fileURLWithPath: filename)
    return try Data(contentsOf: url)
}
