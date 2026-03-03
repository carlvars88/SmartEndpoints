//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public enum APIError: Error {
    case http(status: Int, payload: String?)
    case invalidURL
    case bodyNotAllowed(HTTPMethod)
    case encodingFailed(any Error)
    case decodingFailed(any Error)
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.http(let s1, let p1), .http(let s2, let p2)): return s1 == s2 && p1 == p2
        case (.invalidURL, .invalidURL):                      return true
        case (.bodyNotAllowed(let a), .bodyNotAllowed(let b)): return a == b
        case (.encodingFailed, .encodingFailed):              return true
        case (.decodingFailed, .decodingFailed):              return true
        default:                                              return false
        }
    }
}
