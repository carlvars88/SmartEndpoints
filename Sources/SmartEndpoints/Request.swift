//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/24/25.
//

import Foundation

public protocol Requestable: Sendable {
    associatedtype E: Endpoint
    var endpoint: E { get }
    var queryParams: E.ParametersEncoder.Parameters { get }
    var body: E.BodyEncoder.Body { get }
    var credentials: E.CredentialsEncoder.Credentials { get }
    var headers: HTTPHeaders { get }
}


public struct Request<E: Endpoint>: Requestable {
    public let endpoint: E
    public let queryParams: E.ParametersEncoder.Parameters
    public let body: E.BodyEncoder.Body
    public let credentials: E.CredentialsEncoder.Credentials
    public let headers: HTTPHeaders
    
    init(endpoint: E, queryParams: E.ParametersEncoder.Parameters, body: E.BodyEncoder.Body, credentials: E.CredentialsEncoder.Credentials, headers: HTTPHeaders = .init()) {
        self.endpoint = endpoint
        self.queryParams = queryParams
        self.body = body
        self.credentials = credentials
        self.headers = headers
    }
}

extension Request: Sendable where
    E.ParametersEncoder.Parameters: Sendable, E.BodyEncoder.Body: Sendable, E: Sendable {}

public extension Request where
    E.ParametersEncoder == EmptyParametersEncoder,
    E.BodyEncoder == EmptyBodyEncoder,
    E.CredentialsEncoder == EmptyCredentialsEncoder
{
    init(endpoint: E, headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: .init(),
                  body: .init(),
                  credentials: .init(),
                  headers: headers)
    }
}

public extension Request where E.ParametersEncoder == EmptyParametersEncoder {
    init(endpoint: E, body: E.BodyEncoder.Body,
         credentials: E.CredentialsEncoder.Credentials,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: .init(),
                  body: body,
                  credentials: credentials,
                  headers: headers)
    }
}

public extension Request where E.BodyEncoder == EmptyBodyEncoder {
    init(endpoint: E,
         query: E.ParametersEncoder.Parameters,
         credentials: E.CredentialsEncoder.Credentials,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: query,
                  body: .init(),
                  credentials: credentials,
                  headers: headers)
    }
}

public extension Request where E.CredentialsEncoder == EmptyCredentialsEncoder {
    init(endpoint: E,
         query:  E.ParametersEncoder.Parameters,
         body: E.BodyEncoder.Body,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: query,
                  body: body,
                  credentials: .init(),
                  headers: headers)
    }
}

// Parameters & Body empty
public extension Request where E.ParametersEncoder == EmptyParametersEncoder,
                               E.BodyEncoder == EmptyBodyEncoder {
    init(endpoint: E,
         credentials: E.CredentialsEncoder.Credentials,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: None(),
                  body: None(),
                  credentials: credentials,
                  headers: headers)
    }
}

// Parameters & Credentials empty
public extension Request where E.ParametersEncoder == EmptyParametersEncoder,
                               E.CredentialsEncoder == EmptyCredentialsEncoder {
    init(endpoint: E,
         body: E.BodyEncoder.Body,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: None(),
                  body: body,
                  credentials: None(),
                  headers: headers)
    }
}

// Body & Credentials empty
public extension Request where E.BodyEncoder == EmptyBodyEncoder,
                               E.CredentialsEncoder == EmptyCredentialsEncoder {
    init(endpoint: E,
         queryParams: E.ParametersEncoder.Parameters,
         headers: HTTPHeaders = .init()) {
        self.init(endpoint: endpoint,
                  queryParams: queryParams,
                  body: None(),
                  credentials: None(),
                  headers: headers)
    }
}

extension Requestable {
    public func asURLRequest() throws -> URLRequest {
        let endpoint = self.endpoint
        
        guard let url = URL(string: self.endpoint.api.baseUrl) else {
            throw URLError(.badURL)
        }
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.path = endpoint.path.value
        try endpoint.parameterEncoder.encode(self.queryParams, into: &components)
        // 2. Build URLRequest
        guard let componentURL = components.url else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: componentURL)
        urlRequest.method = endpoint.method
        
        let headers = self.headers.merge(self.endpoint.api.defaultHeaders)
        
        let credentialHeaders = try endpoint.credentialsEncoder.encode(self.credentials)
        
        urlRequest.headers = headers.merge(credentialHeaders, preferExisting: false)
        try endpoint.bodyEncoder.encode(self.body, into: &urlRequest)
        
        return urlRequest
    }
}

