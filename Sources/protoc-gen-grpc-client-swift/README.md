# protoc-gen-swiftgrpc-client

`protoc-gen-swiftgrpc-client` is a plugin for [Protocol Buffers](https://github.com/apple/swift-protobuf). It automatically defines requests, responses and methods used when connecting using `SwiftGRPCClient`.

See also [Swift Protobuf Plugin](https://github.com/apple/swift-protobuf/blob/master/Documentation/PLUGIN.md) document.

### Requirements

- Swift 5.0
- SwiftProtobuf 1.5.0

### How to get plugin

Execute the following command.

```
$ make gen
```

### Converting .proto files into Swift

To generate Swift output for your `.proto` files, you run the `protoc` command as usual, using the `--swiftgrpc-client_out=<directory>` option:

```
$ protoc --swift_out=. --swiftgrpc-client_out=. my.proto
```

By convention the `--swift_out` option invokes the `protoc-gen-swift` plugin and `--swiftgrpc-client_out` invokes `protoc-gen-swiftgrpc-client`.

The protoc program will automatically look for `protoc-gen-swiftgrpc-client` in your PATH and use it. If the plugins are in your search path, it is possible to omit the `--plugin` option.

```
$ protoc --plugin=./protoc-gen-swiftgrpc-client --swiftgrpc-client_out=. my.proto
```

Each `.proto` input file will get translated to a corresponding `.grpc.client.swift` file in the output directory.

#### How to Specify Code-Generation Options

The plugin tries to use reasonable default behaviors for the code it generates, but there are a few things that can be configured to specific needs.

You can use the `--swiftgrpc-client_opt` argument to protoc to pass options to the Swift code generator as follows:

```
$ protoc --swiftgrpc-client_opt=[NAME]=[VALUE] --swiftgrpc-client_out=. my.proto
```

#### Generation Option: `FileNaming` - Naming of Generated Sources

The possible values for FileNaming are:

- FullPath (default): Like all other languages.
- PathToUnderscores: To help with things like the Swift Package Manager where someone might want all the files in one directory.
- DropPath: Drop the path from the input and just write all files into the output directory.

#### Generation Option: `Visibility` - Visibility of Generated Types

The possible values for Visibility are:

- Internal (default): No visibility is set for the types, so they get the default internal visibility.
- Public: The visibility on the types is set to public so the types will be exposed outside the module they are compiled into.

#### Generation Option: `ProtoPathModuleMappings` - Swift Module names for proto paths

The format of that mapping file is defined in [swift_protobuf_module_mappings.proto](https://github.com/apple/swift-protobuf/blob/master/Protos/SwiftProtobufPluginLibrary/swift_protobuf_module_mappings.proto), and files would look something like:

```
mapping {
  module_name: "MyModule"
  proto_file_path: "foo/bar.proto"
}
mapping {
  module_name: "OtherModule"
  proto_file_path: "mumble.proto"
  proto_file_path: "other/file.proto"
}
```

The `proto_file_path` values here should match the paths used in the proto file `import` statements.
