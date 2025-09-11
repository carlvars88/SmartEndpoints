//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation
public protocol NetworkClient {
    func send<R: Requestable>(_ request: R) async throws -> R.E.Output
}

extension NetworkClient {
    public func buildRequest<R: Requestable>(request: R, headers: [String: String] = [:]) throws -> URLRequest {
        let endpoint = request.endpoint
        
        // 1. Build URL
        guard let url = URL(string: request.endpoint.api.baseUrl) else {
            throw URLError(.badURL)
        }
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.path = endpoint.path.value
        try endpoint.parameterEncoder.encode(request.queryParams, into: &components)
        // 2. Build URLRequest
        guard let componentURL = components.url else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: componentURL)
        urlRequest.httpMethod = endpoint.method.rawValue
        // Add default headers
        for (key, value) in R.E.API.defaultHeaders {
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
