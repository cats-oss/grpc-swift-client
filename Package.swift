// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGRPCClient",
    products: [
        .library(name: "SwiftGRPCClient", targets: ["SwiftGRPCClient"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", .upToNextMinor(from: "1.0.3")),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "0.5.1")
    ],
    targets: [
        .target(name: "SwiftGRPCClient",
                dependencies: ["SwiftGRPC"]),
        .target(name: "protoc-gen-swiftgrpc-client",
                dependencies: [
                    "SwiftProtobufPluginLibrary",
                    "protoc-gen-swift"])
    ])
