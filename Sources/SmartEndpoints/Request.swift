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
}


public struct Request<E: Endpoint>: Requestable {
    public let endpoint: E
    public let queryParams: E.ParametersEncoder.Parameters
    public let body: E.BodyEncoder.Body
    public let credentials: E.CredentialsEncoder.Credentials
    
    init(endpoint: E, queryParams: E.ParametersEncoder.Parameters, body: E.BodyEncoder.Body, credentials: E.CredentialsEncoder.Credentials) {
        self.endpoint = endpoint
        self.queryParams = queryParams
        self.body = body
        self.credentials = credentials
    }
}

extension Request: Sendable where
    E.ParametersEncoder.Parameters: Sendable, E.BodyEncoder.Body: Sendable, E: Sendable {}

public extension Request where
    E.ParametersEncoder == EmptyParametersEncoder,
    E.BodyEncoder == EmptyBodyEncoder,
    E.CredentialsEncoder == EmptyCredentialsEncoder
{
    init(endpoint: E) {
        self.init(endpoint: endpoint,
                  queryParams: .init(),
                  body: .init(),
                  credentials: .init())
    }
}

public extension Request where E.ParametersEncoder == EmptyParametersEncoder {
    init(endpoint: E, body: E.BodyEncoder.Body, credentials: E.CredentialsEncoder.Credentials) {
        self.init(endpoint: endpoint, queryParams: .init(), body: body, credentials: credentials)
    }
}

public extension Request where E.BodyEncoder == EmptyBodyEncoder {
    init(endpoint: E, query: E.ParametersEncoder.Parameters, credentials: E.CredentialsEncoder.Credentials) {
        self.init(endpoint: endpoint, queryParams: query, body: .init(), credentials: credentials)
    }
}

public extension Request where E.CredentialsEncoder == EmptyCredentialsEncoder {
    init(endpoint: E, query:  E.ParametersEncoder.Parameters, body: E.BodyEncoder.Body) {
        self.init(endpoint: endpoint, queryParams: query, body: body, credentials: .init())
    }
}

// Parameters & Body empty
public extension Request where E.ParametersEncoder == EmptyParametersEncoder,
                              E.BodyEncoder == EmptyBodyEncoder {
    init(endpoint: E, credentials: E.CredentialsEncoder.Credentials) {
        self.init(endpoint: endpoint,
                  queryParams: None(),
                  body: None(),
                  credentials: credentials)
    }
}

// Parameters & Credentials empty
public extension Request where E.ParametersEncoder == EmptyParametersEncoder,
                              E.CredentialsEncoder == EmptyCredentialsEncoder {
    init(endpoint: E, body: E.BodyEncoder.Body) {
        self.init(endpoint: endpoint,
                  queryParams: None(),
                  body: body,
                  credentials: None())
    }
}

// Body & Credentials empty
public extension Request where E.BodyEncoder == EmptyBodyEncoder,
                              E.CredentialsEncoder == EmptyCredentialsEncoder {
    init(endpoint: E, queryParams: E.ParametersEncoder.Parameters) {
        self.init(endpoint: endpoint,
                  queryParams: queryParams,
                  body: None(),
                  credentials: None())
    }
}

