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
    public let credentials: E.Credentials
    public let headers: HTTPHeaders

    public let parameterEncoder: E.Parameters.ParameterEncoder
    public let bodyEncoder: E.Body.BodyEncoder
    public let credentialsEncoder: E.Credentials.CredentialsEncoder
    public let resultDecoder: E.Result.ResultDecoder

    public init(endpoint: E, queryParams: E.Parameters, body: E.Body, credentials: E.Credentials, headers: HTTPHeaders = .init()) {
        self.endpoint = endpoint
        self.queryParams = queryParams
        self.body = body
        self.credentials = credentials
        self.headers = headers
        self.parameterEncoder = E.Parameters.queryParameterEncoder
        self.bodyEncoder = E.Body.bodyEncoder
        self.credentialsEncoder = E.Credentials.credentialsEncoder
        self.resultDecoder = E.Result.resultDecoder
    }
}

extension Request {
    public func asURLRequest() throws -> URLRequest {
        let endpoint = self.endpoint

        guard let url = URL(string: self.endpoint.api.baseUrl), url.host != nil else {
            throw APIError.invalidURL
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        components.path = url.path + endpoint.path.value
        try wrapping { try self.parameterEncoder.encode(self.queryParams, into: &components) }
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
        try wrapping { try self.credentialsEncoder.encode(self.credentials, into: &urlRequest) }
        try wrapping { try self.bodyEncoder.encode(self.body, into: &urlRequest) }
        try urlRequest.validate()
        return urlRequest
    }
}

private func wrapping(_ block: () throws -> Void) throws {
    do { try block() }
    catch let e as APIError { throw e }
    catch { throw APIError.encodingFailed(error) }
}

public extension Request where
E.Parameters == None,
E.Body == None,
E.Credentials == None
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
         credentials: E.Credentials,
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
         credentials: E.Credentials,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: query,
                  body: .init(),
                  credentials: credentials,
                  headers: headers)
    }
}


public extension Request where
E.Credentials == None
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
         credentials: E.Credentials,
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
E.Credentials == None
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
E.Credentials == None
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


