//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public protocol QueryParameterEncoder<Parameters>: Sendable where Parameters: Encodable & Sendable {
    associatedtype Parameters
    func encode(_ params: Parameters, into components: inout URLComponents) throws
}

public protocol RequestBodyEncoder<Body>: Sendable where Body: Sendable {
    associatedtype Body
    func encode(_ body: Body, into urlRequest: inout URLRequest) throws
}
