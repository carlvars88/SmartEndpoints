//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 8/22/25.
//

import Foundation

public struct MultipartFile: Sendable {
    public let name, filename, mimeType: String
    public let data: Data
    public init(name: String, filename: String, mimeType: String, data: Data) {
        self.name = name; self.filename = filename; self.mimeType = mimeType; self.data = data
    }
}

public struct MultipartParts: Sendable, BodyEncodable {
    public let fields: [(String, String)]
    public let files: [MultipartFile]

    public init(fields: [(String, String)] = [], files: [MultipartFile] = []) {
        self.fields = fields
        self.files = files
    }

    public static var bodyEncoder: MultipartBodyEncoder { .shared }
}

public struct MultipartBodyEncoder: RequestBodyEncoder {
    public static let shared = Self()

    public func encode(_ body: MultipartParts, into urlRequest: inout URLRequest) throws {
        let boundary = "Boundary-\(UUID().uuidString)"
        var data = Data()
        func append(_ s: String) {
            guard let encoded = s.data(using: .utf8) else { return }
            data.append(encoded)
        }

        for (k, v) in body.fields {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(k)\"\r\n\r\n")
            append("\(v)\r\n")
        }
        for f in body.files {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(f.name)\"; filename=\"\(f.filename)\"\r\n")
            append("Content-Type: \(f.mimeType)\r\n\r\n")
            data.append(f.data)
            append("\r\n")
        }
        append("--\(boundary)--\r\n")
        urlRequest.httpBody = data
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    }
}
