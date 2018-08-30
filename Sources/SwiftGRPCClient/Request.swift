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

/// Unary connection is possible.
public protocol UnaryRequest: Request {}
extension UnaryRequest {
    public var style: CallStyle {
        return .unary
    }
}

public protocol SendRequest: Request {}
public protocol ReceiveRequest: Request {
    /// Default is true.
    /// If it is false, will not retry on any error.
    /// If it is true, will retry every time it times out or retry once on error.
    var isRetryable: Bool { get }
}
public extension ReceiveRequest {
    var isRetryable: Bool {
        return true
    }
}

public protocol CloseRequest: Request {}
public protocol CloseAndReciveRequest: Request {}

/// It is possible to receive data continuously from the server.
public protocol ServerStreamingRequest: ReceiveRequest {}
extension ServerStreamingRequest {
    public var style: CallStyle {
        return .serverStreaming
    }
}

/// It is possible to send data continuously to the server. Data can be received only once when connection is completed.
public protocol ClientStreamingRequest: SendRequest, CloseAndReciveRequest {}
extension ClientStreamingRequest {
    public var style: CallStyle {
        return .clientStreaming
    }
}

/// It is possible to send and receive data bi-directionally with the server.
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

    /// Streaming Method
    var method: CallMethod { get }
    
    /// Streaming type
    var style: CallStyle { get }

    /// A timeout value in seconds. If nil, used timeout value of Session as default.
    var timeout: TimeInterval? { get }

    /// Create a Request object for sending to server finally
    ///
    /// - Returns: Request object for sending to server
    func buildRequest() -> InputType

    /// Create a Request object for sending to server finally
    ///
    /// - Parameter message: object to be sent
    /// - Returns: Request object for sending to server
    func buildRequest(_ message: Message) -> InputType

    /// Serialize Request object to `Data`. Call `buildRequest()` internally.
    ///
    /// - Returns: serialized `Data` of Request object
    /// - Throws: Error when fail to build request
    func serialized() throws -> Data

    /// Serialize Request object to `Data`. Call `buildRequest()` internally.
    ///
    /// - Parameter message: object to be sent
    /// - Returns: serialized `Data` of Request object
    /// - Throws: Error when fail to build request
    func serialized(_ message: Message) throws -> Data

    /// Called just before sending the request.
    ///
    /// - Parameter metadata: Metadata to be sent
    /// - Returns: Metadata changed as necessary
    /// - Throws: Error when intercepting request
    func intercept(metadata: Metadata) throws -> Metadata

    /// Parse Data of the response into Response object
    ///
    /// - Parameter data: response Data
    /// - Returns: Parsed Response object
    /// - Throws: Error when parse
    func parse(data: Data) throws -> OutputType
}

public extension Request {
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
