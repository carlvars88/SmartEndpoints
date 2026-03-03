//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct EmptyParametersEncoder: QueryParameterEncoder, Sendable {
    public typealias Parameters = None
    public func encode(_ params: Parameters, into components: inout URLComponents) throws { }
}


