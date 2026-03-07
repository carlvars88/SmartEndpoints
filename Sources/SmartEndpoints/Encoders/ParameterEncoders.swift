//
//  ParameterEncoders.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public protocol QueryParameterEncoder<Parameters>: Sendable {
    associatedtype Parameters: Sendable
    func encode(_ params: Parameters, into components: inout URLComponents) throws
}

public protocol RequestBodyEncoder<Body>: Sendable {
    associatedtype Body: Sendable
    func encode(_ body: Body, into urlRequest: inout URLRequest) throws
}
