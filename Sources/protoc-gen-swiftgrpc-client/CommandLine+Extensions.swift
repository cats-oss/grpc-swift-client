//
//  CommandLine+Extensions.swift
//  protoc-gen-swiftgrpc-client
//
//  Created by Kyohei Ito on 2018/08/09.
//

import Foundation

extension CommandLine {
  static var programName: String {
    guard let base = arguments.first else {
      return "protoc-gen-swiftgrpc-client"
    }
    // Strip it down to just the leaf if it was a path.
    let parts = splitPath(pathname: base)
    return parts.base + parts.suffix
  }
}
