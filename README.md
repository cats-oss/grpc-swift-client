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

See also [SwiftGRPCClient](./Sources/SwiftGRPCClient/README.md) document.

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

## protoc-gen-swiftgrpc-client

`protoc-gen-swiftgrpc-client` is a plugin for [Protocol Buffers](https://github.com/apple/swift-protobuf). It automatically defines requests, responses and methods used when connecting using `SwiftGRPCClient`.

See also [protoc-gen-swiftgrpc-client](./Sources/protoc-gen-swiftgrpc-client/README.md) document.

### Requirements

- Swift 5.0
- SwiftProtobuf 1.5.0

### How to get plugin

Execute the following command.

```
$ make gen
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
    var request = Echo_EchoRequest()

    init(text: String) {
        request.text = text
    }
}
```

## LICENSE

Under the MIT license. See [LICENSE](./LICENSE) file for details.
