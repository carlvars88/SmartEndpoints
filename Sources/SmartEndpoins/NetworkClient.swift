//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation
public protocol NetworkClient {
    func send<R: Requestable>(_ request: R) async throws -> R.E.Output
}
