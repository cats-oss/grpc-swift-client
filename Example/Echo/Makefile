xcodegen:
	xcodegen
	pod install

all:
	protoc echo.proto \
		--plugin=../../protoc-gen-swift --plugin=../../protoc-gen-grpc-swift --plugin=../../protoc-gen-grpc-client-swift \
		--swift_out=Echo/Generated/. --grpc-swift_out=Echo/Generated/. --grpc-client-swift_out=Echo/Generated/. \
		--swift_opt=Visibility=Public --grpc-swift_opt=Visibility=Public --grpc-client-swift_opt=Visibility=Public

proto:
	protoc echo.proto \
		--plugin=../../protoc-gen-swift --plugin=../../protoc-gen-swiftgrpc-client \
		--swift_out=Echo/Generated/. --grpc-client-swift_out=Echo/Generated/. \
		--swift_opt=Visibility=Public --grpc-client-swift_opt=Visibility=Public
