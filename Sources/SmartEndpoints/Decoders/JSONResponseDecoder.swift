//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct JSONResponseDecoder<T: Decodable & Sendable>: ResponseDecoder, Sendable {
    public let acceptHeader: String? = "application/json"
    
    public func decode(_ data: Data, _ response: HTTPURLResponse) throws -> T {
        guard 200..<300 ~= response.statusCode else {
            throw APIError.http(status: response.statusCode,
                                payload: String(data: data, encoding: .utf8))
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

