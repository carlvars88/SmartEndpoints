//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct Path: Sendable {
    public let value: String

    /// Example:
    ///   Path("/users/:id/posts/:postId", values: ["id": "42", "postId": "99"])
    /// -> "/users/42/posts/99"
    public init(_ template: String, values: [String: String] = [:]) {
        var result = template
        for (key, val) in values {
            result = result.replacingOccurrences(of: ":\(key)", with: val)
        }
        self.value = result
    }
}
