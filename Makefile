gen:
	swift build --product protoc-gen-swiftgrpc-client -c release
	cp .build/release/protoc-gen-swift .
	cp .build/release/protoc-gen-swiftgrpc-client .

all:
	swift build
	cp .build/debug/protoc-gen-swift .
	cp .build/debug/protoc-gen-swiftgrpc-client .

project:
	swift package generate-xcodeproj

clean:
	rm -rf Packages
	rm -rf .build build DerivedData
	rm -rf SwiftGRPCClient.xcodeproj
	rm -rf Package.pins Package.resolved
	rm -rf protoc-gen-swift protoc-gen-swiftgrpc-client
