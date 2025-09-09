//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct FormURLEncodedBodyEncoder<B: Encodable & Sendable>: BodyEncoder, Sendable {
    // RFC 3986 unreserved: ALPHA / DIGIT / "-" / "." / "_" / "~"
    private let unreserved = CharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))

    @inline(__always)
    private func pctEncode(_ s: String) -> String {
        // Do NOT use .urlQueryAllowed — it allows '+', '/' etc.
        s.unicodeScalars.map { scalar -> String in
            if self.unreserved.contains(scalar) { return String(scalar) }
            if scalar == " " { return "%20" }            // stick with %20 (not '+')
            let utf8 = String(scalar).utf8
            return utf8.map { String(format: "%%%02X", $0) }.joined()
        }.joined()
    }

    public func encode(_ body: B, into urlRequest: inout URLRequest) throws {
        // Short-circuit for None
        if B.self is None.Type { return }

        let dict = try DictionaryEncoder().encode(body)

        // Flatten to [(name,value)] (arrays => repeated keys)
        var pairs: [(String, String)] = []
        for (k, v) in dict {
            if let arr = v as? [Any] {
                for item in arr { pairs.append((k, String(describing: item))) }
            } else {
                pairs.append((k, String(describing: v)))
            }
        }

        // Build percent-encoded query string manually
        let query = pairs
            .map { pctEncode($0.0) + "=" + pctEncode($0.1) }
            .joined(separator: "&")

        guard let httpBody = query.data(using: .utf8) else {
            throw EncodingError.invalidValue(
                self, .init(codingPath: [], debugDescription: "Failed to convert query string to Data.")
            )
        }

        urlRequest.httpBody = httpBody
        urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8",
                            forHTTPHeaderField: "Content-Type")
    }
}
