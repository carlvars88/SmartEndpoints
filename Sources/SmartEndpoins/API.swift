//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 9/4/25.
//

import Foundation

public protocol API: Sendable {
    static var baseUrl: String { get }
    static var defaultHeaders: [String: String] { get }
}

public extension API {
    static var defaultHeaders: [String: String] {
        [:]
    }
}
