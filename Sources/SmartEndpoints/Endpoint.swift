//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public protocol Endpoint: Sendable {
    associatedtype Output
    associatedtype Parameters
    associatedtype Body
    associatedtype Credentials
    associatedtype API: APIProtocol
    associatedtype ParametersEncoder: QueryParameterEncoder where ParametersEncoder.Parameters == Parameters
    associatedtype BodyEncoder: RequestBodyEncoder      where BodyEncoder.Body == Body
    associatedtype ResultDecoder: ResponseDecoder  where ResultDecoder.Output == Output
    associatedtype CredentialsEncoder: RequestCredentialsEncoder where CredentialsEncoder.Credentials == Credentials
    
    var api: API.Type { get }
    var path: Path { get }
    var method: HTTMethod { get }
    var parameterEncoder: ParametersEncoder { get }
    var bodyEncoder: BodyEncoder { get }
    var responseDecoder: ResultDecoder { get }
    var credentialsEncoder: CredentialsEncoder { get }
}

// Base default (harmless if you always use method-marker protocols)
public extension Endpoint {
    var api: API.Type { API.self }
}

// Zero/empty conveniences
public extension Endpoint where ParametersEncoder == EmptyParametersEncoder {
    var parameterEncoder: EmptyParametersEncoder { .shared }
}
public extension Endpoint where BodyEncoder == EmptyBodyEncoder {
    var bodyEncoder: EmptyBodyEncoder { .shared }
}
public extension Endpoint where CredentialsEncoder == EmptyCredentialsEncoder {
    var credentialsEncoder: EmptyCredentialsEncoder { .shared }
}
public extension Endpoint where ResultDecoder == PlainTextDecoder, Output == String {
    var responseDecoder: PlainTextDecoder { .shared }
}

public extension Endpoint where ResultDecoder == JSONResponseDecoder<Output> {
    var responseDecoder: JSONResponseDecoder<Output> { .init() }
}

public extension Endpoint where ParametersEncoder == URLQueryEncoder<Parameters> {
    var parameterEncoder: URLQueryEncoder<Parameters> { .init() }
}

public extension Endpoint where BodyEncoder == JSONBodyEncoder<Body> {
    var bodyEncoder: JSONBodyEncoder<Body> { .init() }
}

public extension Endpoint where BodyEncoder == FormURLEncodedBodyEncoder<Body> {
    var bodyEncoder: FormURLEncodedBodyEncoder<Body> { .init() }
}

public extension Endpoint where BodyEncoder == MultipartBodyEncoder {
    var bodyEncoder: MultipartBodyEncoder { .shared }
}

public extension Endpoint where CredentialsEncoder == BearerCredentialEncoder {
    var credentialsEncoder: BearerCredentialEncoder { .shared }
}

public extension Endpoint where CredentialsEncoder == BasicCredentialsEncoder {
    var credentialsEncoder: BasicCredentialsEncoder { .shared }
}

