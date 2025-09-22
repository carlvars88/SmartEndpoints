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

    public func send<R: Requestable>(_ r: R) async throws -> (R.E.Output, HTTPURLResponse) {
        let req = try buildRequest(request: r)
        let (data, response) = try await urlSession.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (try r.endpoint.responseDecoder.decode(data, httpResponse), httpResponse)
    }
}


