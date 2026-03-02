//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 3/2/26.
//

import Foundation

public struct EmptyResponseDecoder: ResponseDecoder {
    public var acceptHeader: String?
    
    public func decode(_ data: Data, _ response: HTTPURLResponse) throws -> Empty {
        guard 200..<300 ~= response.statusCode else {
            throw APIError.http(status: response.statusCode,
                                payload: String(data: data, encoding: .utf8))
        }
        return .init()
    }
    
}
