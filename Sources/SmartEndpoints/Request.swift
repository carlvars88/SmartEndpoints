//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/24/25.
//

import Foundation


public struct Request<E: Endpoint>: Sendable {
    public let endpoint: E
    public let queryParams: E.Parameters
    public let body: E.Body
    public let credentials: E.API.Credentials
    public let headers: HTTPHeaders
    
    public let parameterEncoder: any QueryParameterEncoder<E.Parameters>
    public let bodyEncoder: any RequestBodyEncoder<E.Body>
    public let credentialsEncoder: any RequestCredentialsEncoder<E.API.Credentials>
    public let resultDecoder: any ResponseDecoder<E.Result>
    
    public init(endpoint: E, queryParams: E.Parameters, body: E.Body, credentials: E.API.Credentials, headers: HTTPHeaders = .init()) {
        self.endpoint = endpoint
        self.queryParams = queryParams
        self.body = body
        self.credentials = credentials
        self.headers = headers
        self.parameterEncoder = E.Parameters.queryParameterEncoder
        self.bodyEncoder = E.Body.bodyEncoder
        self.credentialsEncoder = E.API.Credentials.credentialsEncoder
        self.resultDecoder = E.Result.resultDecoder
    }
}

extension Request {
    public func asURLRequest() throws -> URLRequest {
        let endpoint = self.endpoint
        
        guard let url = URL(string: self.endpoint.api.baseUrl) else {
            throw APIError.invalidURL
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.path = endpoint.path.value
        try self.parameterEncoder.encode(self.queryParams, into: &components)
        // 2. Build URLRequest
        guard let componentURL = components.url else {
            throw APIError.invalidURL
        }
        var urlRequest = URLRequest(url: componentURL)
        urlRequest.method = endpoint.method
        
        // Build base headers: API defaults, with decoder's Accept applied on top
        var baseHeaders = self.endpoint.api.defaultHeaders
        if let acceptValue = self.resultDecoder.acceptHeader {
            baseHeaders.update(name: "Accept", value: acceptValue)
        }

        // Merge with request-specific headers (request headers have highest precedence)
        let headers = self.headers.merge(baseHeaders)
        urlRequest.headers = headers

        // Encode credentials and body (these may override headers if needed)
        try self.credentialsEncoder.encode(self.credentials, into: &urlRequest)
        try self.bodyEncoder.encode(self.body, into: &urlRequest)
        try urlRequest.validate()
        return urlRequest
    }
}

public extension Request where
E.Parameters == None,
E.Body == None,
E.API.Credentials == None
{
    init(endpoint: E, headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: .init(),
                  body: .init(),
                  credentials: .init(),
                  headers: headers)
    }
}

public extension Request where
E.Parameters == None
{
    init(endpoint: E, body: E.Body,
         credentials: E.API.Credentials,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: .init(),
                  body: body,
                  credentials: credentials,
                  headers: headers)
    }
}

public extension Request where
E.Body == None
{
    init(endpoint: E,
         query: E.Parameters,
         credentials: E.API.Credentials,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: query,
                  body: .init(),
                  credentials: credentials,
                  headers: headers)
    }
}


public extension Request where
E.API.Credentials == None
{
    init(endpoint: E,
         query:  E.Parameters,
         body: E.Body,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: query,
                  body: body,
                  credentials: .init(),
                  headers: headers)
    }
}

public extension Request where
E.Parameters == None,
E.Body == None
{
    init(endpoint: E,
         credentials: E.API.Credentials,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: None(),
                  body: None(),
                  credentials: credentials,
                  headers: headers)
    }
}

public extension Request where
E.Parameters == None,
E.API.Credentials == None
{
    init(endpoint: E,
         body: E.Body,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: None(),
                  body: body,
                  credentials: None(),
                  headers: headers)
    }
}


public extension Request where
E.Body == None,
E.API.Credentials == None
{
    init(endpoint: E,
         queryParams: E.Parameters,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: queryParams,
                  body: None(),
                  credentials: None(),
                  headers: headers)
    }
}



