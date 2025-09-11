//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct DefaultNetworkClient: NetworkClient {
    public let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func send<R: Requestable>(_ r: R) async throws -> R.E.Output {
        try await execute(r)
    }

    private func execute<R: Requestable>(_ r: R) async throws -> R.E.Output {
        let req = try buildRequest(request: r)
        let (data, response) = try await urlSession.data(for: req)
        let http = response as! HTTPURLResponse
        return try r.endpoint.responseDecoder.decode(data, http)
    }
}


