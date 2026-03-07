//
//  RequestCredentialsEncoder.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 9/1/25.
//

import Foundation

public protocol RequestCredentialsEncoder<Credentials>: Sendable where Credentials: Sendable {
    associatedtype Credentials
    func encode(_ credentials: Credentials, into request: inout URLRequest) throws
    
}

public struct BearerCredentialsEncoder: RequestCredentialsEncoder, Sendable {
    public func encode(_ credentials: BearerCredentials, into request: inout URLRequest) throws {
        request.setValue("Bearer \(credentials.value)", forHTTPHeaderField: "Authorization")
    }
}

public struct BasicCredentialsEncoder: RequestCredentialsEncoder, Sendable {
    public func encode(_ credentials: BasicCredentials, into request: inout URLRequest) throws {
        guard let data = "\(credentials.username):\(credentials.password)".data(using: .utf8) else {
            throw EncodingError.invalidValue(credentials, 
                .init(codingPath: [], debugDescription: "Failed to encode credentials to UTF-8"))
        }
        let token = data.base64EncodedString()
        request.setValue( "Basic \(token)", forHTTPHeaderField: "Authorization")
    }
}

public struct BearerCredentials: Sendable, BearerCredentialsEncodable {
    public let value: String

    public init(value: String) {
        self.value = value
    }
}

public struct BasicCredentials: Sendable, BasicCredentialsEncodable {
    public let username: String
    public let password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}
