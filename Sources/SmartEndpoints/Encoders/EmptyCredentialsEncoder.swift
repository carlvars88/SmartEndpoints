//
//  EmptyCredentialsEncoder.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 9/1/25.
//

import Foundation

public struct EmptyCredentialsEncoder: RequestCredentialsEncoder, Sendable {
    public typealias Credentials = None
    public func encode(_ credentials: Credentials, into request: inout URLRequest) throws { }
}


