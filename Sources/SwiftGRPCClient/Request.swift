//
//  Request.swift
//  SwiftGRPCClient
//
//  Created by Kyohei Ito on 2017/10/26.
//  Copyright © 2017年 CyberAgent, Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf
import SwiftGRPC

public protocol UnaryRequest: Request {}
public protocol SendRequest: Request {}
public protocol ReceiveRequest: Request {}
public protocol CloseRequest: Request {}
public protocol CloseAndReciveRequest: Request {}

public protocol UnaryStreamingRequest: UnaryRequest {}
extension UnaryStreamingRequest {
    public var style: CallStyle {
        return .unary
    }
}

public protocol ServerStreamingRequest: ReceiveRequest {}
extension ServerStreamingRequest {
    public var style: CallStyle {
        return .serverStreaming
    }
}

public protocol ClientStreamingRequest: SendRequest, CloseAndReciveRequest {}
extension ClientStreamingRequest {
    public var style: CallStyle {
        return .clientStreaming
    }
}

public protocol BidirectionalStreamingRequest: ReceiveRequest, SendRequest, CloseRequest {}
extension BidirectionalStreamingRequest {
    public var style: CallStyle {
        return .bidiStreaming
    }
}

public protocol Request {
    associatedtype InputType
    associatedtype OutputType
    associatedtype Message

    var metadata: Metadata { get }
    var method: CallMethod { get }
    var style: CallStyle { get }
    var timeout: TimeInterval? { get }

    func buildRequest() -> InputType
    func buildRequest(_ message: Message) -> InputType

    func serialized() throws -> Data
    func serialized(_ message: Message) throws -> Data

    func intercept(metadata: Metadata) throws -> Metadata
    func parse(data: Data) throws -> OutputType
}

public extension Request {
    var metadata: Metadata {
        return Metadata()
    }

    var timeout: TimeInterval? {
        return nil
    }

    func intercept(metadata: Metadata) throws -> Metadata {
        return metadata
    }
}

public extension Request where InputType: SwiftProtobuf.Message {
    func buildRequest() -> InputType {
        return InputType()
    }

    func buildRequest(_ message: Void) -> InputType {
        return buildRequest()
    }

    func serialized() throws -> Data {
        return try buildRequest().serializedData()
    }

    func serialized(_ message: Message) throws -> Data {
        return try buildRequest(message).serializedData()
    }
}

public extension Request where OutputType: SwiftProtobuf.Message {
    func parse(data: Data) throws -> OutputType {
        return try OutputType(serializedData: data)
    }
}
