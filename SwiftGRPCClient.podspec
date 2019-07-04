Pod::Spec.new do |s|
  s.name             = 'SwiftGRPCClient'
  s.version          = '0.3.0'
  s.swift_version    = '5.0'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.summary          = 'Client-side library that depends on SwiftGRPC which is a library of gRPC written in Swift.'
  s.homepage         = 'https://github.com/cats-oss/grpc-swift-client'
  s.author           = { 'Kyohei Ito' => 'ito_kyohei@cyberagent.co.jp' }
  s.source           = { :git => 'https://github.com/cats-oss/grpc-swift-client.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target       = '9.0'
  # s.tvos.deployment_target      = '10.0'
  s.osx.deployment_target       = '10.10'
  # s.watchos.deployment_target   = '2.0'
  s.source_files     = 'Sources/SwiftGRPCClient/*.{h,swift}'
  s.dependency 'SwiftGRPC', '~> 0.9.0'
end
