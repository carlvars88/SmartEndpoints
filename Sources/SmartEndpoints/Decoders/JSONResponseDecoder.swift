//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct JSONResponseDecoder<T: Decodable & Sendable>: ResponseDecoder, Sendable {
    public let acceptHeader: String? = "application/json"
    // Customizable strategies
    private let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
    private let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
    private let dataDecodingStrategy: JSONDecoder.DataDecodingStrategy
    
    // Optional custom JSONDecoder for ultimate flexibility
    private let customDecoder: JSONDecoder?
    
    /// Fully generic initializer
    public init(
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64,
        customDecoder: JSONDecoder? = nil
    ) {
        self.keyDecodingStrategy = keyDecodingStrategy
        self.dateDecodingStrategy = dateDecodingStrategy
        self.dataDecodingStrategy = dataDecodingStrategy
        self.customDecoder = customDecoder
    }
    
    public func decode(_ data: Data, _ response: HTTPURLResponse) throws -> T {
        try validateStatus(response, data: data)

        // Use the fully customized decoder
        let decoder: JSONDecoder
        if let custom = customDecoder {
            decoder = custom
        } else {
            decoder = JSONDecoder()
            decoder.keyDecodingStrategy = keyDecodingStrategy
            decoder.dateDecodingStrategy = dateDecodingStrategy
            decoder.dataDecodingStrategy = dataDecodingStrategy
        }
        
        return try decoder.decode(T.self, from: data)
    }
}

