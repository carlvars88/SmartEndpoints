//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation
public protocol NetworkClient: Sendable {
    func send<R: Requestable>(_ request: R) async throws -> (R.E.Output, HTTPURLResponse)
    func buildRequest<R: Requestable>(request: R) throws -> URLRequest
}

extension NetworkClient {
    public func buildRequest<R: Requestable>(request: R) throws -> URLRequest {
        return try request.asURLRequest()
    }
}
