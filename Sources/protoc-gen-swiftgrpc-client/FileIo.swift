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

#if os(Linux)
  import Glibc
#else
  import Darwin.C
#endif

// Alias clib's write() so Stdout.write(bytes:) can call it.
private let _write = write

private func printToFd(_ s: String, fd: Int32, appendNewLine: Bool = true) {
  // Write UTF-8 bytes
  let bytes: [UInt8] = [UInt8](s.utf8)
  bytes.withUnsafeBufferPointer { (bp: UnsafeBufferPointer<UInt8>) -> () in
    write(fd, bp.baseAddress, bp.count)
  }
  if appendNewLine {
    // Write trailing newline
    [UInt8(10)].withUnsafeBufferPointer { (bp: UnsafeBufferPointer<UInt8>) -> () in
      write(fd, bp.baseAddress, bp.count)
    }
  }
}

class Stderr {
  static func print(_ s: String) {
    let out = "\(CommandLine.programName): " + s
    printToFd(out, fd: 2)
  }
}

class Stdout {
  static func print(_ s: String) { printToFd(s, fd: 1) }
  static func write(bytes: Data) {
    bytes.withUnsafeBytes { (p: UnsafePointer<UInt8>) -> () in
      _ = _write(1, p, bytes.count)
    }
  }
}

class Stdin {
  static func readall() -> Data? {
    let fd: Int32 = 0
    let buffSize = 1024
    var buff = [UInt8]()
    var fragment = [UInt8](repeating: 0, count: buffSize)
    while true {
      let count = read(fd, &fragment, buffSize)
      if count < 0 {
        return nil
      }
      if count < buffSize {
        if count > 0 {
          buff += fragment[0..<count]
        }
        return Data(bytes: buff)
      }
      buff += fragment
    }
  }
}


func readFileData(filename: String) throws -> Data {
    let url = URL(fileURLWithPath: filename)
    return try Data(contentsOf: url)
}
