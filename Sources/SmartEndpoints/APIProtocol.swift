//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 9/4/25.
//

import Foundation

public protocol APIProtocol: Sendable {
    associatedtype Credentials: CredentialsEncodable
    static var baseUrl: String { get }
    static var defaultHeaders: HTTPHeaders { get }
}

public extension APIProtocol {
    static var defaultHeaders: HTTPHeaders {
        .init()
    }
}
