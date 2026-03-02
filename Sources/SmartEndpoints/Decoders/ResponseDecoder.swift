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


