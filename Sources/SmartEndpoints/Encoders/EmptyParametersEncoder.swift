//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct EmptyParametersEncoder: QueryParameterEncoder, Sendable {
    public static let shared = Self()
    public func encode(_ params: None, into components: inout URLComponents) throws { }
}


public struct None: Codable, Sendable { public init() {} }
