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
        try validateStatus(response, data: data)
        return .init()
    }
    
}
