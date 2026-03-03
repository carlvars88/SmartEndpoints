//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public protocol ResponseDecoder<Result>: Sendable where Result: Sendable {
    associatedtype Result
    func decode(_ data: Data, _ response: HTTPURLResponse) throws -> Result

    var acceptHeader: String? { get }
}

extension ResponseDecoder {
    func validateStatus(_ response: HTTPURLResponse, data: Data) throws {
        guard 200..<300 ~= response.statusCode else {
            let payload = String(data: data, encoding: .utf8).flatMap { $0.isEmpty ? nil : $0 }
            throw APIError.http(status: response.statusCode, payload: payload)
        }
    }
}


