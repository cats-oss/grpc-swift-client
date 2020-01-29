gen:
	swift build --product protoc-gen-grpc-client-swift -c release
	cp .build/release/protoc-gen-grpc-client-swift .

all:
	swift build
	cp .build/debug/protoc-gen-swift .
	cp .build/debug/protoc-gen-grpc-client-swift .

project:
	swift package generate-xcodeproj

clean:
	rm -rf Packages
	rm -rf .build build DerivedData
	rm -rf GRPCClient.xcodeproj
	rm -rf Package.pins Package.resolved
	rm -rf protoc-gen-swift protoc-gen-grpc-client-swift
