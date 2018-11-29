//
// DO NOT EDIT.
//
// Generated by the protocol buffer compiler.
// Source: example.proto
//

//
// Copyright 2018, gRPC Authors All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import Foundation
import Dispatch
import SwiftGRPC
import SwiftProtobuf

internal protocol Example_HelloServiceSayHelloCall: ClientCallUnary {}

fileprivate final class Example_HelloServiceSayHelloCallBase: ClientCallUnaryBase<Example_HelloRequest, Example_HelloResponse>, Example_HelloServiceSayHelloCall {
  override class var method: String { return "/example.HelloService/SayHello" }
}


/// Instantiate Example_HelloServiceServiceClient, then call methods of this protocol to make API calls.
internal protocol Example_HelloServiceService: ServiceClient {
  /// Synchronous. Unary.
  func sayHello(_ request: Example_HelloRequest) throws -> Example_HelloResponse
  /// Asynchronous. Unary.
  func sayHello(_ request: Example_HelloRequest, completion: @escaping (Example_HelloResponse?, CallResult) -> Void) throws -> Example_HelloServiceSayHelloCall

}

internal final class Example_HelloServiceServiceClient: ServiceClientBase, Example_HelloServiceService {
  /// Synchronous. Unary.
  internal func sayHello(_ request: Example_HelloRequest) throws -> Example_HelloResponse {
    return try Example_HelloServiceSayHelloCallBase(channel)
      .run(request: request, metadata: metadata)
  }
  /// Asynchronous. Unary.
  internal func sayHello(_ request: Example_HelloRequest, completion: @escaping (Example_HelloResponse?, CallResult) -> Void) throws -> Example_HelloServiceSayHelloCall {
    return try Example_HelloServiceSayHelloCallBase(channel)
      .start(request: request, metadata: metadata, completion: completion)
  }

}

/// To build a server, implement a class that conforms to this protocol.
/// If one of the methods returning `ServerStatus?` returns nil,
/// it is expected that you have already returned a status to the client by means of `session.close`.
internal protocol Example_HelloServiceProvider: ServiceProvider {
  func sayHello(request: Example_HelloRequest, session: Example_HelloServiceSayHelloSession) throws -> Example_HelloResponse
}

extension Example_HelloServiceProvider {
  internal var serviceName: String { return "example.HelloService" }

  /// Determines and calls the appropriate request handler, depending on the request's method.
  /// Throws `HandleMethodError.unknownMethod` for methods not handled by this service.
  internal func handleMethod(_ method: String, handler: Handler) throws -> ServerStatus? {
    switch method {
    case "/example.HelloService/SayHello":
      return try Example_HelloServiceSayHelloSessionBase(
        handler: handler,
        providerBlock: { try self.sayHello(request: $0, session: $1 as! Example_HelloServiceSayHelloSessionBase) })
          .run()
    default:
      throw HandleMethodError.unknownMethod
    }
  }
}

internal protocol Example_HelloServiceSayHelloSession: ServerSessionUnary {}

fileprivate final class Example_HelloServiceSayHelloSessionBase: ServerSessionUnaryBase<Example_HelloRequest, Example_HelloResponse>, Example_HelloServiceSayHelloSession {}
