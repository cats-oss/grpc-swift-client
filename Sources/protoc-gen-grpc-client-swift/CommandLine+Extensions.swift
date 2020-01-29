import Foundation

extension CommandLine {
  static var programName: String {
    guard let base = arguments.first else {
      return "protoc-gen-grpc-client-swift"
    }
    // Strip it down to just the leaf if it was a path.
    let parts = splitPath(pathname: base)
    return parts.base + parts.suffix
  }
}
