//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 9/9/25.
//

import XCTest
@testable import SmartEndpoints

final class MultipartBodyEncoderTests: XCTestCase {

    struct DummyBody: Sendable {
        let fields: [(String, String)]
        let files: [MultipartFile]
    }

    // MARK: - Helpers

    private func makeRequest() -> URLRequest {
        var request = URLRequest(url: URL(string: "https://example.com/upload")!)
        request.httpMethod = "POST"
        return request
    }

    private func extractBoundary(from contentType: String?) -> String? {
        guard
            let contentType,
            contentType.hasPrefix("multipart/form-data"),
            let range = contentType.range(of: "boundary=")
        else { return nil }
        return String(contentType[range.upperBound...])
    }
    
    func dataContains(_ haystack: Data, _ needle: String) -> Bool {
        haystack.range(of: Data(needle.utf8)) != nil
    }

    // MARK: - Tests

    func testEncode_SetsContentTypeAndBuildsBody_WithFieldsAndFiles() throws {
        // Given
        let textFileData = Data("Hello, world!".utf8)
        let pngBytes: [UInt8] = [0x89, 0x50, 0x4E, 0x47] // minimal PNG signature prefix
        let pngData = Data(pngBytes)

        let body = (
            fields: [("username", "carlos"), ("note", "line1\nline2")],
            files: [
                MultipartFile(name: "avatar", filename: "me.txt", mimeType: "text/plain", data: textFileData),
                MultipartFile(name: "icon", filename: "icon.png", mimeType: "image/png", data: pngData)
            ]
        )

        let encoder = MultipartBodyEncoder()

        var request = makeRequest()

        // When
        try encoder.encode(body, into: &request)

        // Then
        let contentType = request.value(forHTTPHeaderField: "Content-Type")
        let boundary = extractBoundary(from: contentType)
        XCTAssertNotNil(boundary, "Content-Type should include a boundary parameter")
        XCTAssertTrue(contentType?.hasPrefix("multipart/form-data; boundary=") == true)

        let httpBody = try XCTUnwrap(request.httpBody, "httpBody must be set")
        
        // Field parts
        XCTAssertTrue(
            dataContains(httpBody, "Content-Disposition: form-data; name=\"username\"\r\n\r\ncarlos\r\n"),
            "Did not find expected username field block in multipart body"
        )
        
        XCTAssertTrue(
            dataContains(httpBody, "Content-Disposition: form-data; name=\"note\"\r\n\r\nline1\nline2\r\n"),
            "Did not find expected note field block in multipart body"
        )

        // File part headers
        XCTAssertTrue(
            dataContains(httpBody, "Content-Disposition: form-data; name=\"avatar\"; filename=\"me.txt\"\r\n"),
            "Did not find expected avatar file block in multipart body"
        )
        XCTAssertTrue(
            dataContains(httpBody, "Content-Type: text/plain\r\n\r\n"),
            "Did not find expected mimetype for avatar file in multipart body"
        )
        XCTAssertTrue(
            dataContains(httpBody, "Content-Disposition: form-data; name=\"icon\"; filename=\"icon.png\"\r\n"),
            "Did not find expected icon field block in multipart body"
        )
        XCTAssertTrue(
            dataContains(httpBody, "Content-Type: image/png\r\n\r\n"),
            "Did not find expected mimetype for icon file in multipart body"
        )

        // File payloads (text payload should appear verbatim)
        XCTAssertTrue(
            dataContains(httpBody, "Hello, world!"),
            "Did not find expected avatar file payload in multipart body"
        )

        // Binary payload presence (look for the PNG signature sequence inside the raw bytes)
        let signatureRange = httpBody.range(of: pngData, options: [], in: httpBody.startIndex..<httpBody.endIndex)
        XCTAssertNotNil(signatureRange, "Binary file data should be present in the multipart body")

        // Boundary framing checks
        let b = try XCTUnwrap(boundary)
        let openingMarker = "--\(b)\r\n".data(using: .utf8)!
        let closingMarker = "--\(b)--\r\n".data(using: .utf8)!

        // Expect one opening per part (2 fields + 2 files = 4)
        let openingCount = httpBody
            .split(separator: openingMarker) // custom splitter below
        XCTAssertEqual(openingCount - 1, 4, "Expected 4 opening boundaries")

        // Ends with the proper closing boundary
        XCTAssertTrue(httpBody.suffix(closingMarker.count) == closingMarker, "Body should end with the closing boundary")
    }

    func testEncode_OrderIsFieldsThenFiles() throws {
        // Given
        let body = (
            fields: [("a", "1"), ("b", "2")],
            files: [MultipartFile(name: "f", filename: "x.txt", mimeType: "text/plain", data: Data("X".utf8))]
        )

        let encoder = MultipartBodyEncoder()

        var request = makeRequest()

        // When
        try encoder.encode(body, into: &request)

        // Then
        let b = try XCTUnwrap(extractBoundary(from: request.value(forHTTPHeaderField: "Content-Type")))
        let bodyString = try XCTUnwrap(String(data: try XCTUnwrap(request.httpBody), encoding: .utf8))

        // Find indices to ensure fields come before files (per implementation)
        let fieldAIndex = bodyString.range(of: "--\(b)\r\nContent-Disposition: form-data; name=\"a\"")!.lowerBound
        let fieldBIndex = bodyString.range(of: "--\(b)\r\nContent-Disposition: form-data; name=\"b\"")!.lowerBound
        let fileIndex   = bodyString.range(of: "--\(b)\r\nContent-Disposition: form-data; name=\"f\"; filename=\"x.txt\"")!.lowerBound

        XCTAssertTrue(fieldAIndex < fieldBIndex && fieldBIndex < fileIndex, "Fields should precede files in the encoded body")
    }


}

// MARK: - Data helpers

private extension Data {
    /// Count occurrences of a sub-Data pattern by splitting.
    func split(separator: Data) -> Int {
        guard !separator.isEmpty else { return 0 }
        var count = 0
        var searchRange: Range<Data.Index> = startIndex..<endIndex
        while let r = self.range(of: separator, options: [], in: searchRange) {
            count += 1
            searchRange = r.upperBound..<endIndex
        }
        return count + 1 // number of segments = occurrences + 1
    }
}
