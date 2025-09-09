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
    var queryParams: E.PEncoder.Parameters { get }
    var body: E.BEncoder.Body { get }
    var credentials: E.CEncoder.Credentials { get }
}


public struct Request<E: Endpoint>: Requestable {
    public let endpoint: E
    public let queryParams: E.Parameters
    public let body: E.Body
    public let credentials: E.Credentials
    
    init(endpoint: E, queryParams: E.Parameters, body: E.Body, credentials: E.Credentials) {
        self.endpoint = endpoint
        self.queryParams = queryParams
        self.body = body
        self.credentials = credentials
    }
}

extension Request: Sendable where
    E.PEncoder.Parameters: Sendable, E.BEncoder.Body: Sendable, E: Sendable {}

public extension Request where
    E.PEncoder == EmptyParametersEncoder,
    E.BEncoder == EmptyBodyEncoder,
    E.CEncoder == EmptyCredentialsEncoder
{
    init(endpoint: E) {
        self.init(endpoint: endpoint,
                  queryParams: .init(),
                  body: .init(),
                  credentials: .init())
    }
}

public extension Request where E.PEncoder == EmptyParametersEncoder {
    init(endpoint: E, body: E.BEncoder.Body, credentials: E.CEncoder.Credentials) {
        self.init(endpoint: endpoint, queryParams: .init(), body: body, credentials: credentials)
    }
}

public extension Request where E.BEncoder == EmptyBodyEncoder {
    init(endpoint: E, query: E.PEncoder.Parameters, credentials: E.CEncoder.Credentials) {
        self.init(endpoint: endpoint, queryParams: query, body: .init(), credentials: credentials)
    }
}

public extension Request where E.CEncoder == EmptyCredentialsEncoder {
    init(endpoint: E, query:  E.PEncoder.Parameters, body: E.BEncoder.Body) {
        self.init(endpoint: endpoint, queryParams: query, body: body, credentials: .init())
    }
}

// Parameters & Body empty
public extension Request where E.PEncoder == EmptyParametersEncoder,
                              E.BEncoder == EmptyBodyEncoder {
    init(endpoint: E, credentials: E.Credentials) {
        self.init(endpoint: endpoint,
                  queryParams: None(),
                  body: None(),
                  credentials: credentials)
    }
}

// Parameters & Credentials empty
public extension Request where E.PEncoder == EmptyParametersEncoder,
                              E.CEncoder == EmptyCredentialsEncoder {
    init(endpoint: E, body: E.Body) {
        self.init(endpoint: endpoint,
                  queryParams: None(),
                  body: body,
                  credentials: None())
    }
}

// Body & Credentials empty
public extension Request where E.BEncoder == EmptyBodyEncoder,
                              E.CEncoder == EmptyCredentialsEncoder {
    init(endpoint: E, queryParams: E.Parameters) {
        self.init(endpoint: endpoint,
                  queryParams: queryParams,
                  body: None(),
                  credentials: None())
    }
}

