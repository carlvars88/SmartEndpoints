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
        try validateStatus(response, data: data)
        guard let text = String(data: data, encoding: .utf8) else {
            throw APIError.decodingFailed(
                DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: [],
                                          debugDescription: "Response data is not valid UTF-8 text.")
                )
            )
        }
        return text
    }
}
