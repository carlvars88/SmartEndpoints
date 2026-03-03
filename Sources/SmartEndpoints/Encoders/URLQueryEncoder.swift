//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct URLQueryEncoder<P: Encodable & Sendable>: QueryParameterEncoder, Sendable {
    public func encode(_ params: P, into components: inout URLComponents) throws {
        let pairs = try KeyValueEncoder().encode(params)
        var items = components.queryItems ?? []
        items.append(contentsOf: pairs.map { URLQueryItem(name: $0.key, value: $0.value) })
        components.queryItems = items
    }
}
