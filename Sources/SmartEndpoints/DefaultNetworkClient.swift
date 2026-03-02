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

    public func send<E: Endpoint>(_ r: Request<E>) async throws -> (E.Result, HTTPURLResponse) {
        let req = try buildRequest(request: r)
        let (data, response) = try await urlSession.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (try r.resultDecoder.decode(data, httpResponse), httpResponse)
    }
}


