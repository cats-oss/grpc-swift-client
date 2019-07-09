# Swift gRPC Client

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/SwiftGRPCClient.svg?style=flat)](http://cocoadocs.org/docsets/SwiftGRPCClient)
[![License](https://img.shields.io/cocoapods/l/SwiftGRPCClient.svg?style=flat)](http://cocoadocs.org/docsets/SwiftGRPCClient)
[![Platform](https://img.shields.io/cocoapods/p/SwiftGRPCClient.svg?style=flat)](http://cocoadocs.org/docsets/SwiftGRPCClient)

Client-side library that depends on [SwiftGRPC](https://github.com/grpc/grpc-swift) which is a library of [gRPC](https://grpc.io/) written in Swift. Basically it is used the function of `Core` part of `SwiftGRPC`, but it is made to make client implementation easier. 

---
:warning: **WARNING :** If there is the breaking change in SwiftGRPC, this library may not be updatable.

---

The following two modules are included.

#### SwiftGRPCClient
It is a plugin to use when running at runtime. Link to the application or framework.

#### protoc-gen-swiftgrpc-client
It is a [Protocol Buffer's](https://github.com/apple/swift-protobuf) plugin for creating the functions necessary to use `SwiftGRPCClient`. Use `protoc` to generate `.swift` from `.proto`.

## SwiftGRPCClient

If you use `SwiftGRPC`, you can do `Unary` connection using generated `protocol` or `struct` as follows.

```swift
let service = Echo_EchoServiceClient(address: "YOUR_SERVER_ADDRESS")
var requestMessage = Echo_EchoRequest()
requestMessage.text = "message"
_ = try? service.get(requestMessage) { responseMessage, callResult in
}
```

The `get` method above can get a `message` by sending arbitrary `message`, but with this method you can not get the information of the logged-in user. For example, if you want to get user information, you will need to prepare the following methods.

```swift
var requestUser = Example_UserRequest()
requestUser.id = "user_id"
_ = try? service.getUser(requestUser) { responseUser, callResult in
}
```

In this way, when connecting using a certain request, a special method is required to execute the request.

With `SwiftGRPCClient`, `data` is the only method to make a `Unary` request.

```swift
let session = Session(address: "YOUR_SERVER_ADDRESS")
session.stream(with: EchoUnaryRequest(text: "message"))
    .data { result in
    }
```

It is possible to get the user's login information just by changing the request.

```swift
session.stream(with: GetUserRequest(id: "user_id"))
    .data { result in
    }
```

### Requirements

- Swift 5.0
- SwiftGRPC 0.9.1

### How to Install

#### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'SwiftGRPCClient'
```

#### Carthage

Add the following to your `Cartfile`:

```
github "cats-oss/grpc-swift-client"
```

Then, add `BoringSSL`, `CgRPC`, `SwiftProtobuf`, `SwiftGRPC` and `SwiftGRPCClient` on link binary and `carthage copy-frameworks`.

### How to use

#### Session

It is inheriting `ServiceClientBase`. See also [ServiceClient](https://github.com/grpc/grpc-swift/blob/0.5.1/Sources/SwiftGRPC/Runtime/ServiceClient.swift) in [grpc/grpc-swift](https://github.com/grpc/grpc-swift/).

It has [Dependency](#dependency) object. It can replace if necessary.

```swift
var dependency: Dependency
```

`Session` can create a `Stream` from an instance of `Request`.

```swift
func stream<R>(with request: R) -> Stream<R> where R : Request
```

Make one instance of `Session` for the server. If necessary, create a singleton object.

```swift
extension Session {
    static let shared = Session(address: "YOUR_SERVER_ADDRESS", secure: false)
}
```

#### Stream

There is a way to access the resources of the server. Depending on the type of `Request` used to create `Stream`, the available connection method changes.

- UnaryRequest

Unary connection is possible.

```swift
func data(_ completion: @escaping (Result<Request.OutputType>) -> Void) -> Self
```

- ClientStreamingRequest

It is possible to send data continuously to the server. Data can be received only once when connection is completed.

```swift
func send(_ message: Message, completion: ((Result<Void>) -> Void)? = default) -> Self
func closeAndReceive(_ completion: @escaping (Result<Request.OutputType>) -> Void)
```

- ServerStreamingRequest

It is possible to receive data continuously from the server.

```swift
func receive(_ completion: @escaping (Result<Request.OutputType?>) -> Void) -> Self
```

- BidirectionalStreamingRequest

It is possible to send and receive data bi-directionally with the server.

```swift
func send(_ message: Message, completion: @escaping (Result<Void>) -> Void) -> Self
func receive(_ completion: @escaping (Result<Request.OutputType?>) -> Void) -> Self
func func close(_ completion: ((Result<Void>) -> Void)? = default)
```

- Request

The following methods can be executed with any connection method. You can abort the connection and discard internally held `Call` objects.

```swift
func cancel()
func refresh()
```

#### Request

You can create a `Stream` object using objects conforming to this `protocol`.

When sending data to the server, implement the following method.

```swift
func buildRequest() -> InputType
func buildRequest(_ message: Message) -> InputType
```

For example, an `Echo` request to send a message can be implemented as follows.

```swift
struct EchoGetRequest: Echo_EchoGetRequest {
    var text = ""

    func buildRequest() -> Echo_EchoRequest {
        var request = Echo_EchoRequest()
        request.text = text
        return request
    }
}
```

#### Dependency

It is possible to monitor all requests. Processing can be interrupted as necessary.

```swift
func intercept(metadata: Metadata) throws -> Metadata
```

## protoc-gen-swiftgrpc-client

`protoc-gen-swiftgrpc-client` is a plugin for [Protocol Buffers](https://github.com/apple/swift-protobuf). It automatically defines requests, responses and methods used when connecting using `SwiftGRPCClient`.

### Requirements

- Swift 4.1
- SwiftProtobuf 1.0.3

### How to get plugin

Execute the following command.

```
$ make all
```

### How to use

Invoke plugins with `protoc` commands like the following:

```
$ protoc [proto files path] --plugin=./protoc-gen-swift --plugin=./protoc-gen-swiftgrpc-client --swiftgrpc-client_out. --swift_out=.
```

By convention the `--swift_out` option invokes the `protoc-gen-swift` plugin and `--swiftgrpc-client_out` invokes `protoc-gen-swiftgrpc-client`.

If the plugins are in your search path, it is possible to omit the `--plugin` option.

```
$ protoc [proto files path] --swift_out=. --swiftgrpc-client_out=.
```

#### Generation Option: Visibility - Visibility of Generated Types

You can change this with the Visibility option like the following:

```
$ protoc [proto files path] --swiftgrpc-client_out=Visibility='Public':.
```

### Explain generated code

As an example, prepare the following `.proto`.

```protobuf
syntax = "proto3";

package echo;

service Echo {
    rpc Get(EchoRequest) returns (EchoResponse) {}
}

message EchoRequest {
    string text = 1;
}

message EchoResponse {
    string text = 1;
}
```

`protoc` creates `.swift` file.

```swift
// MARK: - Echo Request Method
enum Echo_EchoMethod: String, CallMethod {
    case get = "Get"

    static let service = "echo.Echo"
}

// MARK: - Echo_Echo Get Request
protocol _Echo_EchoGetRequest {
    typealias InputType = Echo_EchoRequest
    typealias OutputType = Echo_EchoResponse
}

protocol Echo_EchoGetRequest: _Echo_EchoGetRequest, UnaryRequest {}

extension Echo_EchoGetRequest {
    var method: CallMethod {
        return Echo_EchoMethod.get
    }
}
```


Define the `Request` object using `protocol` in the generated `.swift`.

```swift
struct EchoGetRequest: Echo_EchoGetRequest {
    var text = ""

    func buildRequest() -> Echo_EchoRequest {
        var request = Echo_EchoRequest()
        request.text = text
        return request
    }
}
```

## LICENSE

Under the MIT license. See LICENSE file for details.
