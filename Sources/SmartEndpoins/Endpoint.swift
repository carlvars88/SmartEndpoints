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
    associatedtype A: API
    associatedtype PEncoder: ParameterEncoder where PEncoder.Parameters == Parameters
    associatedtype BEncoder: BodyEncoder      where BEncoder.Body == Body
    associatedtype RDecoder: ResponseDecoder  where RDecoder.Output == Output
    associatedtype CEncoder: CredentialsEncoder where CEncoder.Credentials == Credentials
    
    var path: Path { get }
    var method: String { get }
    var parameterEncoder: PEncoder { get }
    var bodyEncoder: BEncoder { get }
    var responseDecoder: RDecoder { get }
    var credentialsEncoder: CEncoder { get }
}

// Base default (harmless if you always use method-marker protocols)
public extension Endpoint { var method: String { "GET" } }

// Zero/empty conveniences
public extension Endpoint where PEncoder == EmptyParametersEncoder {
    var parameterEncoder: EmptyParametersEncoder { .shared }
}
public extension Endpoint where BEncoder == EmptyBodyEncoder {
    var bodyEncoder: EmptyBodyEncoder { .shared }
}
public extension Endpoint where CEncoder == EmptyCredentialsEncoder {
    var credentialsEncoder: EmptyCredentialsEncoder { .shared }
}

public extension Endpoint where RDecoder == PlainTextDecoder, Output == String {
    var responseDecoder: PlainTextDecoder { .shared }
}

// Method markers
public protocol GETEndpoint: Endpoint {}
public protocol POSTEndpoint: Endpoint {}
public protocol PUTEndpoint: Endpoint {}
public protocol PATCHEndpoint: Endpoint {}
public protocol DELETEEndpoint: Endpoint {}

public extension GETEndpoint    {
    var method: String { "GET" }
    var bodyEncoder: EmptyBodyEncoder { .shared }
}

public extension POSTEndpoint   { var method: String { "POST" } }
public extension PUTEndpoint    { var method: String { "PUT" } }
public extension PATCHEndpoint  { var method: String { "PATCH" } }
public extension DELETEEndpoint { var method: String { "DELETE" } }


public protocol ParameterlessEndpoint: Endpoint where PEncoder == EmptyParametersEncoder {}
public extension ParameterlessEndpoint { var parameterEncoder: EmptyParametersEncoder { .shared } }

public protocol NoBodyEndpoint: Endpoint where BEncoder == EmptyBodyEncoder {}
public extension NoBodyEndpoint { var bodyEncoder: EmptyBodyEncoder { .shared } }

public protocol NoCredentialEndpoint: Endpoint where CEncoder == EmptyCredentialsEncoder {}
public extension NoCredentialEndpoint { var credentialsEncoder: EmptyCredentialsEncoder { .shared } }

public protocol Queryable: Endpoint where PEncoder == URLQueryEncoder<Parameters> {}
public extension Queryable { var parameterEncoder: URLQueryEncoder<Parameters> { .init() } }

public protocol JSONBodyCarrying: Endpoint where Body: Encodable, BEncoder == JSONBodyEncoder<Body> {}
public extension JSONBodyCarrying { var bodyEncoder: JSONBodyEncoder<Body> { .init() } }

public protocol FormURLBodyCarrying: Endpoint where Body: Encodable, BEncoder == FormURLEncodedBodyEncoder<Body> {}
public extension FormURLBodyCarrying { var bodyEncoder: FormURLEncodedBodyEncoder<Body> { .init() } }

public protocol MultipartBodyCarrying: Endpoint where BEncoder == MultipartBodyEncoder {}
public extension MultipartBodyCarrying { var bodyEncoder: MultipartBodyEncoder { .shared } }

public protocol BearerAuthenticated: Endpoint where CEncoder == BearerCredentialEncoder, Credentials == String {}
public extension BearerAuthenticated { var credentialsEncoder: BearerCredentialEncoder { .shared } }

public protocol BasicAuthenticated: Endpoint where CEncoder == BasicCredentialsEncoder, Credentials == BasicCredentialsEncoder.Credentials {}
public extension BasicAuthenticated { var credentialsEncoder: BasicCredentialsEncoder { .shared } }

public protocol JSONDecodableResult: Endpoint where Output: Decodable, RDecoder == JSONResponseDecoder<Output> {}
public extension JSONDecodableResult { var responseDecoder: JSONResponseDecoder<Output> { .init() } }

public protocol PlainTextResult: Endpoint where Output == String, RDecoder == PlainTextDecoder {}
public extension PlainTextResult { var responseDecoder: PlainTextDecoder { .shared } }


public typealias QueryableEndpoint = GETEndpoint & Queryable

public typealias RestEndpoint = JSONDecodableResult & BearerAuthenticated
public typealias QueryableRestEndpoint = QueryableEndpoint & RestEndpoint
public typealias PostableRestEndpoint = POSTEndpoint & JSONBodyCarrying & RestEndpoint & ParameterlessEndpoint
public typealias DeleteRestEndpoint = DELETEEndpoint & RestEndpoint & ParameterlessEndpoint & NoBodyEndpoint
public typealias PatchRestEndpoint = PATCHEndpoint & JSONBodyCarrying & RestEndpoint & ParameterlessEndpoint

public typealias RawEndpoint = PlainTextResult & NoCredentialEndpoint
public typealias RawQueryableEndpoint = QueryableEndpoint & RawEndpoint
public typealias RawPostableEndpoint  = POSTEndpoint & FormURLBodyCarrying & RawEndpoint & ParameterlessEndpoint
