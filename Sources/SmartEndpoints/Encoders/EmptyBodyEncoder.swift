//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct EmptyBodyEncoder: RequestBodyEncoder {
    public typealias Body = None
    public func encode(_ body: Body, into urlRequest: inout URLRequest) throws {}
}
