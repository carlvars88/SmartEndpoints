//
//  HTTPTransport+Endpoint.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/25/26.
//

import Foundation
@_exported import NetworkingCore

public extension HTTPTransport {
    func execute<E: Endpoint>(_ request: Request<E>) async throws -> E.Result {
        let urlRequest = try request.asURLRequest()
        return try await performRequest(request: urlRequest) { data, response in
            try E.Result.resultDecoder.decode(data, response)
        }
    }
}

public extension AuthenticatedHTTPTransport {
    /// Skips the endpoint's own `Credentials` encoding — the transport already
    /// authenticates every request it sends, so applying `Credentials` again
    /// here would be redundant (or could clobber the transport's own headers).
    func execute<E: Endpoint>(_ request: Request<E>) async throws -> E.Result {
        let urlRequest = try request.asUnauthenticatedURLRequest()
        return try await performRequest(request: urlRequest) { data, response in
            try E.Result.resultDecoder.decode(data, response)
        }
    }
}
