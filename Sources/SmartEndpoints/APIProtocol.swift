//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 9/4/25.
//

import Foundation

public protocol APIProtocol: Sendable {
    static var baseUrl: String { get }
    static var defaultHeaders: [String: String] { get }
}

public extension APIProtocol {
    static var defaultHeaders: [String: String] {
        [:]
    }
}
