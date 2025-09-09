//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 9/1/25.
//

import Foundation

public struct EmptyCredentialsEncoder: CredentialsEncoder, Sendable {
    public static let shared = Self()
    public func encode(_ credentials: None) throws -> [String: String] { [:] }
}
