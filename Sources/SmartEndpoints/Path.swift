//
//  File.swift
//  SmartEndpoints
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
        var usedKeys = Set<String>()
        
        // Find all :token patterns in template
        let regex = try! NSRegularExpression(pattern: ":[a-zA-Z_]\\w*")
        let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
        for match in matches {
            let range = Range(match.range, in: template)!
            let token = String(template[range])
            let key = String(token.dropFirst()) // remove ":"
            guard let val = values[key] else {
                preconditionFailure("Path token '\(token)' has no matching value")
            }
            result = result.replacingOccurrences(of: token, with: val)
            usedKeys.insert(key)
        }

        // Check for extra keys not matching any token
        let extraKeys = Set(values.keys).subtracting(usedKeys)
        if !extraKeys.isEmpty {
            preconditionFailure("Values \(extraKeys) don't match any token in '\(template)'")
        }

        self.value = result
    }
}
