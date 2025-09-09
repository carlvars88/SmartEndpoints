//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct EmptyBodyEncoder: BodyEncoder {
    public static let shared = Self()
    public func encode(_ body: None, into urlRequest: inout URLRequest) throws {}
}
