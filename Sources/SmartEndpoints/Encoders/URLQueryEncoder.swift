//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct URLQueryEncoder<P: Encodable & Sendable>: QueryParameterEncoder, Sendable {
    
    public func encode(_ params: P, into components: inout URLComponents) throws {
        guard !(P.self is None.Type) else { return }
        
        let dict = try DictionaryEncoder().encode(params)
        var items = components.queryItems ?? []
        for (k, v) in dict {
            if let arr = v as? [Any] {
                items.append(contentsOf: arr.map { URLQueryItem(name: k, value: "\($0)") })
            } else {
                items.append(URLQueryItem(name: k, value: "\(v)"))
            }
        }
        components.queryItems = items
    }
}
