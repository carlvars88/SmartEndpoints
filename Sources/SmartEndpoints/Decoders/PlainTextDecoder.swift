//
//  File 2.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct PlainTextDecoder: ResponseDecoder {
    public static let shared = Self()
    
    public let acceptHeader: String? = "text/plain"
    
    public func decode(_ data: Data, _ response: HTTPURLResponse) throws -> String {
        guard 200..<300 ~= response.statusCode else {
            throw APIError.http(status: response.statusCode,
                                payload: String(data: data, encoding: .utf8))
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [],
                                      debugDescription: "Response data is not valid UTF-8 text.")
            )
        }
        return text
    }
}
