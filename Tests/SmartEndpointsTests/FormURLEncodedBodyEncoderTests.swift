//
//  File.swift
//  SmartEndpoins
//
//  Created by MacBook Pro on 9/8/25.
//

import XCTest
@testable import SmartEndpoints


final class FormURLEncodedBodyEncoderTests: XCTestCase {

    // MARK: - Fixtures

    struct LoginForm: Encodable, Sendable {
        let username: String
        let password: String
        
        enum CodingKeys: String, CodingKey {
            case username = "user_name"
            case password = "pass_word"
        }
    }

    struct ComplexForm: Encodable, Sendable {
        let name: String
        let tags: [Int]
        let note: String
    }

    // MARK: - Helpers

    private func bodyString(_ request: URLRequest) -> String? {
        guard let data = request.httpBody else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func containsAll(_ s: String, _ parts: [String]) -> Bool {
        parts.allSatisfy { s.contains($0) }
    }

    // MARK: - Tests

    func testEncodesSimpleFormAsXWWWFormURLEncoded() throws {
        var request = URLRequest(url: URL(string: "https://example.com/login")!)
        let encoder = FormURLEncodedBodyEncoder<LoginForm>()
        try encoder.encode(LoginForm(username: "john", password: "s3cr3t"), into: &request)

        // Content-Type header
        let contentType = request.value(forHTTPHeaderField: "Content-Type")
        XCTAssertEqual(contentType, "application/x-www-form-urlencoded; charset=utf-8")

        // UTF-8 body present
        let body = try XCTUnwrap(bodyString(request))
        // Order is not guaranteed; assert membership
        XCTAssertTrue(containsAll(body, ["user_name=john", "pass_word=s3cr3t"]),
                      "Body should contain both key-value pairs. Got: \(body)")
    }

    func testPercentEncodingOfSpacesAndSymbols() throws {
        var request = URLRequest(url: URL(string: "https://example.com/complex")!)
        let encoder = FormURLEncodedBodyEncoder<ComplexForm>()
        let form = ComplexForm(name: "John Doe", tags: [1], note: "a+b & c/d")
        try encoder.encode(form, into: &request)

        let body = try XCTUnwrap(bodyString(request))
        // URLComponents percent-encodes spaces as %20 (not '+') by default.
        // Symbols like '+' and '&' should be encoded in the value.
        XCTAssertTrue(body.contains("name=John%20Doe"), "Expected space to be %20. Body: \(body)")
        XCTAssertTrue(body.contains("note=a%2Bb%20%26%20c%2Fd"), "Expected symbols to be percent-encoded. Body: \(body)")
    }

    func testArrayEncodesAsRepeatedQueryItems() throws {
        var request = URLRequest(url: URL(string: "https://example.com/complex")!)
        let encoder = FormURLEncodedBodyEncoder<ComplexForm>()
        let form = ComplexForm(name: "n", tags: [10, 20, 30], note: "ok")
        try encoder.encode(form, into: &request)

        let body = try XCTUnwrap(bodyString(request))
        // Expect repeated keys like tags=10&tags=20&tags=30 (order not guaranteed)
        XCTAssertTrue(containsAll(body, ["tags=10", "tags=20", "tags=30"]),
                      "Expected repeated tags entries. Body: \(body)")
    }

    func testNoneTypeShortCircuits_NoBody_NoHeader() throws {
        struct EmptyForm: Encodable, Sendable {} // not used; we’ll target None below

        var request = URLRequest(url: URL(string: "https://example.com/empty")!)
        let encoder = FormURLEncodedBodyEncoder<None>() // B == None triggers guard-return

        try encoder.encode(None(), into: &request)

        XCTAssertNil(request.httpBody, "Body should be nil for None")
        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"),
                     "Content-Type should not be set when body is None")
    }

    func testCallingEncodeTwiceOverwritesBody() throws {
        var request = URLRequest(url: URL(string: "https://example.com/login")!)
        let encoder = FormURLEncodedBodyEncoder<LoginForm>()
        try encoder.encode(LoginForm(username: "a", password: "1"), into: &request)

        let firstBody = try XCTUnwrap(bodyString(request))
        XCTAssertTrue(containsAll(firstBody, ["username=a", "password=1"]))

        // Call again with different content; ensure httpBody is replaced, not appended
        try encoder.encode(LoginForm(username: "b", password: "2"), into: &request)
        let secondBody = try XCTUnwrap(bodyString(request))
        XCTAssertTrue(containsAll(secondBody, ["username=b", "password=2"]))
        XCTAssertFalse(secondBody.contains("username=a"),
                       "Second encode should overwrite previous body")
    }
}
