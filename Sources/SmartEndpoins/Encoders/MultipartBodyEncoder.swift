//
//  File.swift
//  SmartEndpoins
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

public struct MultipartBodyEncoder: BodyEncoder {
    public typealias Parts = (fields: [(String, String)], files: [MultipartFile])
    
    public static let shared = Self()
    
    public func encode(_ body: Parts, into urlRequest: inout URLRequest) throws {
        let boundary = "Boundary-\(UUID().uuidString)"
        var data = Data()
        func append(_ s: String) { data.append(s.data(using: .utf8)!) }

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
