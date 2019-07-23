# SwiftGRPCClient

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
