Pod::Spec.new do |s|
  s.name             = 'gRPC-Client-Swift'
  s.version          = '1.0.0'
  s.swift_version    = '5.0'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.summary          = 'Client-side library that depends on SwiftGRPC which is a library of gRPC written in Swift.'
  s.homepage         = 'https://github.com/cats-oss/grpc-swift-client'
  s.author           = { 'Kyohei Ito' => 'ito_kyohei@cyberagent.co.jp' }
  s.source           = { :git => 'https://github.com/cats-oss/grpc-swift-client.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target       = '10.0'
  s.tvos.deployment_target      = '10.0'
  s.osx.deployment_target       = '10.12'
  s.source_files     = 'Sources/GRPCClient/**/*.{h,swift}'
  s.module_name      = 'GRPCClient'
  s.dependency 'gRPC-Swift', '1.5.0'
end
