//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 9/1/25.
//

import Foundation

public protocol CredentialsEncoder<Credentials>: Sendable where Credentials: Sendable {
    associatedtype Credentials
    func encode(_ credentials: Credentials) throws -> [String: String]
    
}

public struct BearerCredentialEncoder: CredentialsEncoder {
    public static let shared = Self()
    public func encode(_ credentials: String) throws -> [String: String] {
        return ["Authorization": "Bearer \(credentials)"]
    }
}

public struct BasicCredentialsEncoder: CredentialsEncoder, Sendable {
    public static let shared = Self()
    
    public struct Credentials: Sendable {
        let username: String
        let password: String
    }
   
    public func encode(_ credentials: Credentials) throws -> [String: String] {
        let token = "\(credentials.username):\(credentials.password)".data(using: .utf8)!.base64EncodedString()
        return ["Authorization": "Basic \(token)"]
    }
}

