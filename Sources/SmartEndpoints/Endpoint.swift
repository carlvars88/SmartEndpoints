//
//  Endpoint.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public protocol Endpoint: Sendable {
    associatedtype Result: ResultDecodable
    associatedtype Parameters: QueryParameterEncodable
    associatedtype Body: BodyEncodable
    associatedtype API: APIProtocol
    associatedtype Credentials: CredentialsEncodable = API.Credentials

    var api: API.Type { get }
    var path: Path { get }
    var method: String { get }
}

extension Endpoint {
    public var api: API.Type { API.self }
}


public protocol ResultDecodable: Sendable {
    associatedtype ResultDecoder: ResponseDecoder where ResultDecoder.Result == Self
    
    static var resultDecoder: ResultDecoder { get }
}

public protocol QueryParameterEncodable: Sendable {
    associatedtype ParameterEncoder: QueryParameterEncoder where ParameterEncoder.Parameters == Self
    
    static var queryParameterEncoder: ParameterEncoder { get }
}

public protocol BodyEncodable: Sendable {
    associatedtype BodyEncoder: RequestBodyEncoder where BodyEncoder.Body == Self
    
    static var bodyEncoder: BodyEncoder { get }
}

public protocol CredentialsEncodable: Sendable {
    associatedtype CredentialsEncoder: RequestCredentialsEncoder where CredentialsEncoder.Credentials == Self
    
    static var credentialsEncoder: CredentialsEncoder { get }
}

public protocol JSONDecodable: Decodable, ResultDecodable {}

public protocol JSONEncodable: Encodable, BodyEncodable {}

public protocol FormURLEncodeBodyEncodable: Encodable, BodyEncodable {}

public protocol BearerCredentialsEncodable: CredentialsEncodable {}

extension JSONDecodable {
    public static var resultDecoder: JSONResponseDecoder<Self> { .init() }
}

extension String: ResultDecodable {
    static public var resultDecoder: PlainTextDecoder { .init() }
}

extension JSONEncodable {
    public static var bodyEncoder: JSONBodyEncoder<Self> { .init() }
}

extension FormURLEncodeBodyEncodable {
    public static var bodyEncoder: FormURLEncodedBodyEncoder<Self> { .init() }
}

extension BearerCredentialsEncodable {
    public static var credentialsEncoder: BearerCredentialsEncoder { .init() }
}

public protocol BasicCredentialsEncodable: CredentialsEncodable {}

extension BasicCredentialsEncodable {
    public static var credentialsEncoder: BasicCredentialsEncoder { .init() }
}

extension Empty: ResultDecodable {
    public static var resultDecoder: EmptyResponseDecoder { .init() }
}

extension None: QueryParameterEncodable {
    public static var queryParameterEncoder: EmptyParametersEncoder { .init() }
}

extension None: BodyEncodable {
    public static var bodyEncoder: EmptyBodyEncoder { .init() }
}

extension None: CredentialsEncodable {
    public static var credentialsEncoder: EmptyCredentialsEncoder { .init() }
}
