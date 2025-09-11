//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public protocol ResponseDecoder<Output>: Sendable where Output: Sendable {
    associatedtype Output
    func decode(_ data: Data, _ response: HTTPURLResponse) throws -> Output
    
    var acceptHeader: String? { get }
}
