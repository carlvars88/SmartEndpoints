//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct JSONBodyEncoder<B: Encodable & Sendable>: RequestBodyEncoder, Sendable {
    public func encode(_ body: B, into urlRequest: inout URLRequest) throws {
        urlRequest.httpBody = try JSONEncoder().encode(body)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}
