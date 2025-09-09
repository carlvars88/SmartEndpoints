//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct DefaultNetworkClient: NetworkClient {
    public let baseURL: URL
    public let urlSession: URLSession

    public init(baseURL: URL,
                urlSession: URLSession = .shared) {
        self.baseURL = baseURL
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
    
    private func buildRequest<R: Requestable>(request: R, headers: [String: String] = [:]) throws -> URLRequest {
        let endpoint = request.endpoint
        
        // 1. Build URL
        guard var components = URLComponents(string: R.E.A.baseUrl) else {
            throw URLError(.badURL)
        }
        components.path = endpoint.path.value
        try endpoint.parameterEncoder.encode(request.queryParams, into: &components)
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        // 2. Build URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method
        
        // Add default headers
        for (key, value) in R.E.A.defaultHeaders {
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        // Encode credentials
        let credentialHeaders = try endpoint.credentialsEncoder.encode(request.credentials)
        for (key, value) in credentialHeaders {
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        // Encode body
        try endpoint.bodyEncoder.encode(request.body, into: &urlRequest)
        
        return urlRequest
    }
}


