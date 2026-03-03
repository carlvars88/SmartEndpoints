//
//  SmartEndpointsTests.swift
//  SmartEndpoints
//
//  Created on 3/2/26.
//

import Testing
import Foundation
@testable import SmartEndpoints

// MARK: - Test fixtures

private struct MockAPI: APIProtocol {
    typealias Credentials = None
    static let baseUrl = "https://api.example.com"
}

private struct MockAPIWithDefaults: APIProtocol {
    typealias Credentials = None
    static let baseUrl = "https://api.example.com"
    static var defaultHeaders: HTTPHeaders {
        var h = HTTPHeaders()
        h["X-Version"] = "2"
        h["Accept"] = "application/xml"   // should be overridden by decoder
        return h
    }
}

private struct AuthAPI: APIProtocol {
    typealias Credentials = BearerCredential
    static let baseUrl = "https://api.example.com"
}

private struct BasicAuthAPI: APIProtocol {
    typealias Credentials = BasicCredentials
    static let baseUrl = "https://api.example.com"
}

private struct InvalidAPI: APIProtocol {
    typealias Credentials = None
    static let baseUrl = "not a url"
}

// Response types
private struct Item: Codable, Sendable, JSONDecodable { let id: Int }

// Body types
private struct JSONBody: Codable, Sendable, JSONEncodable {
    let name: String
    let count: Int
}

private struct FormBody: Codable, Sendable, FormURLEncodeBodyEncodable {
    let username: String
    let password: String
}

// Parameter types
private struct SearchParams: Codable, Sendable, QueryParameterEncodable {
    let q: String
    let limit: Int?
    static var queryParameterEncoder: URLQueryEncoder<Self> { .init() }
}

// Endpoints
private struct GetItemsEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = None
    typealias API = MockAPI
    var path: Path { Path("/items") }
    var method: HTTPMethod { .get }
}

private struct GetItemEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = None
    typealias API = MockAPI
    let id: Int
    var path: Path { Path("/items/:id", values: ["id": "\(id)"]) }
    var method: HTTPMethod { .get }
}

private struct SearchEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = SearchParams
    typealias Body = None
    typealias API = MockAPI
    var path: Path { Path("/search") }
    var method: HTTPMethod { .get }
}

private struct CreateEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = JSONBody
    typealias API = MockAPI
    var path: Path { Path("/items") }
    var method: HTTPMethod { .post }
}

private struct FormEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = FormBody
    typealias API = MockAPI
    var path: Path { Path("/login") }
    var method: HTTPMethod { .post }
}

private struct JSONResultEndpoint: Endpoint {
    typealias Result = Item
    typealias Parameters = None
    typealias Body = None
    typealias API = MockAPI
    var path: Path { Path("/items/1") }
    var method: HTTPMethod { .get }
}

// Uses MockAPIWithDefaults (Accept: application/xml) but result is JSON — decoder should win
private struct JSONResultWithDefaultsEndpoint: Endpoint {
    typealias Result = Item
    typealias Parameters = None
    typealias Body = None
    typealias API = MockAPIWithDefaults
    var path: Path { Path("/items/1") }
    var method: HTTPMethod { .get }
}

private struct DefaultHeadersEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = None
    typealias API = MockAPIWithDefaults
    var path: Path { Path("/items") }
    var method: HTTPMethod { .get }
}

private struct AuthEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = None
    typealias API = AuthAPI
    var path: Path { Path("/me") }
    var method: HTTPMethod { .get }
}

private struct BasicAuthEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = None
    typealias API = BasicAuthAPI
    var path: Path { Path("/me") }
    var method: HTTPMethod { .get }
}

private struct InvalidURLEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = None
    typealias API = InvalidAPI
    var path: Path { Path("/items") }
    var method: HTTPMethod { .get }
}

// Endpoints for validation tests — method has body but shouldn't
private struct GetWithBodyEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = JSONBody
    typealias API = MockAPI
    var path: Path { Path("/bad") }
    var method: HTTPMethod { .get }
}

private struct HeadWithBodyEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = JSONBody
    typealias API = MockAPI
    var path: Path { Path("/bad") }
    var method: HTTPMethod { .head }
}

private struct DeleteWithBodyEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = JSONBody
    typealias API = MockAPI
    var path: Path { Path("/bad") }
    var method: HTTPMethod { .delete }
}

private struct TraceWithBodyEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = JSONBody
    typealias API = MockAPI
    var path: Path { Path("/bad") }
    var method: HTTPMethod { .trace }
}

// Credential override — public endpoint on an otherwise-authenticated API
private struct PublicEndpointOnAuthAPI: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = None
    typealias API = AuthAPI
    typealias Credentials = None        // override
    var path: Path { Path("/public") }
    var method: HTTPMethod { .get }
}

// Fixtures for error surface tests
private struct FailingBody: Encodable, Sendable, BodyEncodable {
    struct Encoder: RequestBodyEncoder {
        typealias Body = FailingBody
        func encode(_ body: FailingBody, into request: inout URLRequest) throws {
            throw EncodingError.invalidValue(body, .init(codingPath: [], debugDescription: "deliberate"))
        }
    }
    static var bodyEncoder: Encoder { .init() }
}

private struct FailingBodyEndpoint: Endpoint {
    typealias Result = Empty
    typealias Parameters = None
    typealias Body = FailingBody
    typealias API = MockAPI
    var path: Path { Path("/fail") }
    var method: HTTPMethod { .post }
}

// MARK: - URLSession convenience (test-only)

protocol NetworkClient: Sendable {
    func send<E: Endpoint>(_ request: Request<E>) async throws -> (E.Result, HTTPURLResponse)
    func buildRequest<E: Endpoint>(request: Request<E>) throws -> URLRequest
}

extension NetworkClient {
    func buildRequest<E: Endpoint>(request: Request<E>) throws -> URLRequest {
        try request.asURLRequest()
    }
}

struct DefaultNetworkClient: NetworkClient {
    let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func send<E: Endpoint>(_ r: Request<E>) async throws -> (E.Result, HTTPURLResponse) {
        let req = try buildRequest(request: r)
        let (data, response) = try await urlSession.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (try r.resultDecoder.decode(data, httpResponse), httpResponse)
    }
}

// MARK: - URL building

@Suite("URL Building")
struct URLBuildingTests {

    @Test("Sets base URL host and scheme")
    func testBaseURL() throws {
        let req = try Request(endpoint: GetItemsEndpoint()).asURLRequest()
        #expect(req.url?.scheme == "https")
        #expect(req.url?.host == "api.example.com")
    }

    @Test("Appends path to base URL")
    func testPath() throws {
        let req = try Request(endpoint: GetItemsEndpoint()).asURLRequest()
        #expect(req.url?.path == "/items")
    }

    @Test("Substitutes a single path parameter")
    func testSinglePathParam() throws {
        let req = try Request(endpoint: GetItemEndpoint(id: 42)).asURLRequest()
        #expect(req.url?.path == "/items/42")
    }

    @Test("Sets HTTP method")
    func testHTTPMethod() throws {
        let getReq  = try Request(endpoint: GetItemsEndpoint()).asURLRequest()
        let postReq = try Request(endpoint: CreateEndpoint(), body: JSONBody(name: "x", count: 1)).asURLRequest()
        #expect(getReq.method  == .get)
        #expect(postReq.method == .post)
    }

    @Test("Appends query parameters")
    func testQueryParams() throws {
        let req = try Request(endpoint: SearchEndpoint(),
                              queryParams: SearchParams(q: "hello", limit: 10)).asURLRequest()
        let url = req.url?.absoluteString ?? ""
        #expect(url.contains("q=hello"))
        #expect(url.contains("limit=10"))
    }

    @Test("Skips nil optional query parameters")
    func testNilQueryParamsSkipped() throws {
        let req = try Request(endpoint: SearchEndpoint(),
                              queryParams: SearchParams(q: "hello", limit: nil)).asURLRequest()
        let url = req.url?.absoluteString ?? ""
        #expect(!url.contains("limit"))
        #expect(!url.contains("null"))
    }

    @Test("Invalid base URL throws APIError.invalidURL")
    func testInvalidURL() {
        #expect(throws: APIError.invalidURL) {
            try Request(endpoint: InvalidURLEndpoint()).asURLRequest()
        }
    }
}

// MARK: - Headers

@Suite("Headers")
struct HeaderTests {

    @Test("API default headers are applied")
    func testAPIDefaultHeaders() throws {
        let req = try Request(endpoint: DefaultHeadersEndpoint()).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "X-Version") == "2")
    }

    @Test("JSON result decoder sets Accept: application/json")
    func testJSONAcceptHeader() throws {
        let req = try Request(endpoint: JSONResultEndpoint()).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("Decoder Accept overrides API default Accept")
    func testDecoderAcceptOverridesAPIDefault() throws {
        // MockAPIWithDefaults sets Accept: application/xml, but the JSON decoder sets application/json — decoder wins
        let req = try Request(endpoint: JSONResultWithDefaultsEndpoint()).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("Request headers override API defaults")
    func testRequestHeadersOverrideAPIDefaults() throws {
        var custom = HTTPHeaders()
        custom["X-Version"] = "99"
        let req = try Request(endpoint: DefaultHeadersEndpoint(), headers: custom).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "X-Version") == "99")
    }

    @Test("Request headers and API defaults are merged")
    func testRequestAndAPIHeadersMerged() throws {
        var custom = HTTPHeaders()
        custom["X-Request-ID"] = "abc"
        let req = try Request(endpoint: DefaultHeadersEndpoint(), headers: custom).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "X-Version") == "2")
        #expect(req.value(forHTTPHeaderField: "X-Request-ID") == "abc")
    }
}

// MARK: - Credentials

@Suite("Credentials")
struct CredentialTests {

    @Test("Bearer credential sets Authorization header")
    func testBearerCredential() throws {
        let req = try Request(endpoint: AuthEndpoint(),
                              credentials: BearerCredential(value: "tok123")).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer tok123")
    }

    @Test("Basic credential sets Authorization header")
    func testBasicCredential() throws {
        let req = try Request(endpoint: BasicAuthEndpoint(),
                              credentials: BasicCredentials(username: "user", password: "pass")).asURLRequest()
        let header = req.value(forHTTPHeaderField: "Authorization") ?? ""
        #expect(header.hasPrefix("Basic "))
        let decoded = String(data: Data(base64Encoded: String(header.dropFirst(6)))!, encoding: .utf8)
        #expect(decoded == "user:pass")
    }

    @Test("No credentials sets no Authorization header")
    func testNoCredentials() throws {
        let req = try Request(endpoint: GetItemsEndpoint()).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("Endpoint can override API credentials with None")
    func testCredentialOverrideToNone() throws {
        // PublicEndpointOnAuthAPI overrides Credentials = None on an AuthAPI (BearerCredential)
        let req = try Request(endpoint: PublicEndpointOnAuthAPI()).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "Authorization") == nil)
    }
}

// MARK: - Body encoding

@Suite("Body Encoding")
struct BodyEncodingTests {

    @Test("JSON body sets httpBody")
    func testJSONBodySet() throws {
        let req = try Request(endpoint: CreateEndpoint(),
                              body: JSONBody(name: "widget", count: 3)).asURLRequest()
        #expect(req.httpBody != nil)
    }

    @Test("JSON body sets Content-Type: application/json")
    func testJSONContentType() throws {
        let req = try Request(endpoint: CreateEndpoint(),
                              body: JSONBody(name: "widget", count: 3)).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test("JSON body content round-trips correctly")
    func testJSONBodyContent() throws {
        let body = JSONBody(name: "widget", count: 7)
        let req = try Request(endpoint: CreateEndpoint(), body: body).asURLRequest()
        let decoded = try JSONDecoder().decode(JSONBody.self, from: req.httpBody!)
        #expect(decoded.name == "widget")
        #expect(decoded.count == 7)
    }

    @Test("Form body sets Content-Type: application/x-www-form-urlencoded")
    func testFormContentType() throws {
        let req = try Request(endpoint: FormEndpoint(),
                              body: FormBody(username: "alice", password: "secret")).asURLRequest()
        let ct = req.value(forHTTPHeaderField: "Content-Type") ?? ""
        #expect(ct.hasPrefix("application/x-www-form-urlencoded"))
    }

    @Test("Form body encodes key=value pairs")
    func testFormBodyContent() throws {
        let req = try Request(endpoint: FormEndpoint(),
                              body: FormBody(username: "alice", password: "secret")).asURLRequest()
        let body = String(data: req.httpBody!, encoding: .utf8) ?? ""
        #expect(body.contains("username=alice"))
        #expect(body.contains("password=secret"))
    }

    @Test("Form body sets Content-Length")
    func testFormContentLength() throws {
        let req = try Request(endpoint: FormEndpoint(),
                              body: FormBody(username: "alice", password: "s")).asURLRequest()
        #expect(req.value(forHTTPHeaderField: "Content-Length") != nil)
    }

    @Test("Empty body sets no httpBody")
    func testEmptyBodyNil() throws {
        let req = try Request(endpoint: GetItemsEndpoint()).asURLRequest()
        #expect(req.httpBody == nil)
    }
}

// MARK: - Validation

@Suite("Request Validation")
struct ValidationTests {

    private let body = JSONBody(name: "x", count: 1)

    @Test("GET with body throws bodyNotAllowed")
    func testGETBodyForbidden() {
        #expect(throws: APIError.bodyNotAllowed(.get)) {
            try Request(endpoint: GetWithBodyEndpoint(), body: body).asURLRequest()
        }
    }

    @Test("HEAD with body throws bodyNotAllowed")
    func testHEADBodyForbidden() {
        #expect(throws: APIError.bodyNotAllowed(.head)) {
            try Request(endpoint: HeadWithBodyEndpoint(), body: body).asURLRequest()
        }
    }

    @Test("DELETE with body throws bodyNotAllowed")
    func testDELETEBodyForbidden() {
        #expect(throws: APIError.bodyNotAllowed(.delete)) {
            try Request(endpoint: DeleteWithBodyEndpoint(), body: body).asURLRequest()
        }
    }

    @Test("TRACE with body throws bodyNotAllowed")
    func testTRACEBodyForbidden() {
        #expect(throws: APIError.bodyNotAllowed(.trace)) {
            try Request(endpoint: TraceWithBodyEndpoint(), body: body).asURLRequest()
        }
    }

    @Test("POST with body is valid")
    func testPOSTBodyAllowed() throws {
        try Request(endpoint: CreateEndpoint(), body: body).asURLRequest()
    }
}

// MARK: - KeyValueEncoder

@Suite("KeyValueEncoder")
struct KeyValueEncoderTests {

    private func encode<T: Encodable>(_ value: T) throws -> [KeyValuePair] {
        try KeyValueEncoder().encode(value)
    }

    @Test("Encodes String")
    func testString() throws {
        struct S: Encodable { let name: String }
        let pairs = try encode(S(name: "hello"))
        #expect(pairs == [KeyValuePair(key: "name", value: "hello")])
    }

    @Test("Encodes Int")
    func testInt() throws {
        struct S: Encodable { let count: Int }
        let pairs = try encode(S(count: 42))
        #expect(pairs == [KeyValuePair(key: "count", value: "42")])
    }

    @Test("Encodes Bool as true/false")
    func testBool() throws {
        struct S: Encodable { let flag: Bool }
        #expect(try encode(S(flag: true))  == [KeyValuePair(key: "flag", value: "true")])
        #expect(try encode(S(flag: false)) == [KeyValuePair(key: "flag", value: "false")])
    }

    @Test("Skips nil optional — no null in output")
    func testNilSkipped() throws {
        struct S: Encodable { let value: Int? }
        let pairs = try encode(S(value: nil))
        #expect(pairs.isEmpty)
        #expect(!pairs.map(\.value).contains("null"))
    }

    @Test("Includes non-nil optional")
    func testNonNilOptional() throws {
        struct S: Encodable { let value: Int? }
        let pairs = try encode(S(value: 7))
        #expect(pairs == [KeyValuePair(key: "value", value: "7")])
    }

    @Test("Array produces repeated keys")
    func testArray() throws {
        struct S: Encodable { let ids: [Int] }
        let pairs = try encode(S(ids: [1, 2, 3]))
        #expect(pairs == [KeyValuePair(key: "ids", value: "1"),
                          KeyValuePair(key: "ids", value: "2"),
                          KeyValuePair(key: "ids", value: "3")])
    }

    @Test("Nested struct uses dot-separated keys")
    func testNestedStruct() throws {
        struct Address: Encodable { let city: String }
        struct S: Encodable { let address: Address }
        let pairs = try encode(S(address: Address(city: "Paris")))
        #expect(pairs == [KeyValuePair(key: "address.city", value: "Paris")])
    }

    @Test("Preserves property insertion order")
    func testOrder() throws {
        struct S: Encodable {
            let a: String
            let b: String
            let c: String
        }
        let pairs = try encode(S(a: "1", b: "2", c: "3"))
        #expect(pairs.map(\.key) == ["a", "b", "c"])
    }
}

// MARK: - Path

@Suite("Path")
struct PathTests {

    @Test("Simple path passes through unchanged")
    func testSimplePath() {
        #expect(Path("/items").value == "/items")
    }

    @Test("Substitutes a single parameter")
    func testSingleParam() {
        #expect(Path("/items/:id", values: ["id": "42"]).value == "/items/42")
    }

    @Test("Substitutes multiple parameters")
    func testMultipleParams() {
        let path = Path("/users/:userId/posts/:postId", values: ["userId": "1", "postId": "99"])
        #expect(path.value == "/users/1/posts/99")
    }

    @Test("Leaves unmatched tokens untouched")
    func testUnmatchedToken() {
        #expect(Path("/items/:id", values: [:]).value == "/items/:id")
    }
}

// MARK: - Error surface

@Suite("Error Surface")
struct ErrorSurfaceTests {

    @Test("Encoding failure wraps as APIError.encodingFailed")
    func testEncodingFailureWrapped() {
        #expect(throws: APIError.encodingFailed(URLError(.unknown))) {
            try Request(endpoint: FailingBodyEndpoint(), body: FailingBody()).asURLRequest()
        }
    }

    @Test("JSON decoding failure wraps as APIError.decodingFailed")
    func testJSONDecodingFailureWrapped() throws {
        struct Item: Decodable, Sendable {}
        let decoder = JSONResponseDecoder<Item>()
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!
        #expect(throws: APIError.decodingFailed(URLError(.unknown))) {
            try decoder.decode(Data("not json".utf8), response)
        }
    }

    @Test("PlainText decoding failure wraps as APIError.decodingFailed")
    func testPlainTextDecodingFailureWrapped() throws {
        let decoder = PlainTextDecoder()
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!
        // 0xFF is invalid UTF-8
        #expect(throws: APIError.decodingFailed(URLError(.unknown))) {
            try decoder.decode(Data([0xFF, 0xFE]), response)
        }
    }

    @Test("HTTP error status still throws APIError.http")
    func testHTTPErrorPassesThrough() throws {
        struct Item: Decodable, Sendable {}
        let decoder = JSONResponseDecoder<Item>()
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                       statusCode: 404,
                                       httpVersion: nil,
                                       headerFields: nil)!
        #expect(throws: APIError.http(status: 404, payload: nil)) {
            try decoder.decode(Data(), response)
        }
    }
}

// MARK: - Shared helpers

private func mockResponse(status: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "https://example.com")!,
                    statusCode: status,
                    httpVersion: nil,
                    headerFields: nil)!
}

// MARK: - MultipartBodyEncoder

@Suite("MultipartBodyEncoder")
struct MultipartBodyEncoderTests {

    private var emptyRequest: URLRequest { URLRequest(url: URL(string: "https://example.com")!) }

    private func boundary(from request: URLRequest) -> String {
        let ct = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        guard let range = ct.range(of: "boundary=") else { return "" }
        return String(ct[range.upperBound...])
    }

    private func bodyString(from request: URLRequest) -> String {
        request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    @Test("Sets httpBody")
    func testSetsBody() throws {
        var req = emptyRequest
        try MultipartBodyEncoder.shared.encode(MultipartParts(), into: &req)
        #expect(req.httpBody != nil)
    }

    @Test("Content-Type header starts with multipart/form-data; boundary=")
    func testContentTypeHeader() throws {
        var req = emptyRequest
        try MultipartBodyEncoder.shared.encode(MultipartParts(), into: &req)
        let ct = req.value(forHTTPHeaderField: "Content-Type") ?? ""
        #expect(ct.hasPrefix("multipart/form-data; boundary="))
    }

    @Test("Empty parts body contains only the terminator")
    func testEmptyParts() throws {
        var req = emptyRequest
        try MultipartBodyEncoder.shared.encode(MultipartParts(), into: &req)
        let b = boundary(from: req)
        #expect(bodyString(from: req) == "--\(b)--\r\n")
    }

    @Test("Body boundary matches Content-Type header")
    func testBoundaryConsistency() throws {
        var req = emptyRequest
        try MultipartBodyEncoder.shared.encode(MultipartParts(fields: [KeyValuePair(key: "k", value: "v")]), into: &req)
        let b = boundary(from: req)
        let body = bodyString(from: req)
        #expect(body.contains("--\(b)\r\n"))
        #expect(body.hasSuffix("--\(b)--\r\n"))
    }

    @Test("Encodes a text field with correct disposition")
    func testSingleTextField() throws {
        var req = emptyRequest
        try MultipartBodyEncoder.shared.encode(MultipartParts(fields: [KeyValuePair(key: "username", value: "alice")]), into: &req)
        let body = bodyString(from: req)
        #expect(body.contains("Content-Disposition: form-data; name=\"username\""))
        #expect(body.contains("alice"))
    }

    @Test("Encodes multiple fields in order")
    func testMultipleFieldsInOrder() throws {
        var req = emptyRequest
        try MultipartBodyEncoder.shared.encode(MultipartParts(fields: [KeyValuePair(key: "a", value: "1"), KeyValuePair(key: "b", value: "2")]), into: &req)
        let body = bodyString(from: req)
        let posA = body.range(of: "name=\"a\"")!.lowerBound
        let posB = body.range(of: "name=\"b\"")!.lowerBound
        #expect(posA < posB)
    }

    @Test("Encodes a file with correct disposition and Content-Type")
    func testFileHeaders() throws {
        var req = emptyRequest
        let file = MultipartFile(name: "avatar", filename: "photo.jpg", mimeType: "image/jpeg", data: Data())
        try MultipartBodyEncoder.shared.encode(MultipartParts(files: [file]), into: &req)
        let body = bodyString(from: req)
        #expect(body.contains("name=\"avatar\"; filename=\"photo.jpg\""))
        #expect(body.contains("Content-Type: image/jpeg"))
    }

    @Test("File binary data is present in body")
    func testFileDataEmbedded() throws {
        var req = emptyRequest
        let fileData = Data("binary content".utf8)
        let file = MultipartFile(name: "doc", filename: "file.txt", mimeType: "text/plain", data: fileData)
        try MultipartBodyEncoder.shared.encode(MultipartParts(files: [file]), into: &req)
        #expect(req.httpBody?.range(of: fileData) != nil)
    }

    @Test("Fields and files can be mixed")
    func testMixedFieldsAndFiles() throws {
        var req = emptyRequest
        let file = MultipartFile(name: "upload", filename: "data.bin", mimeType: "application/octet-stream",
                                 data: Data([0x01, 0x02]))
        try MultipartBodyEncoder.shared.encode(MultipartParts(fields: [KeyValuePair(key: "note", value: "hi")], files: [file]), into: &req)
        let body = bodyString(from: req)
        #expect(body.contains("name=\"note\""))
        #expect(body.contains("name=\"upload\""))
    }
}

// MARK: - PlainTextDecoder

@Suite("PlainTextDecoder")
struct PlainTextDecoderTests {

    private let decoder = PlainTextDecoder.shared

    @Test("Accept header is text/plain")
    func testAcceptHeader() {
        #expect(decoder.acceptHeader == "text/plain")
    }

    @Test("Decodes valid UTF-8 body")
    func testDecodesText() throws {
        let result = try decoder.decode(Data("hello world".utf8), mockResponse())
        #expect(result == "hello world")
    }

    @Test("Decodes empty body as empty string")
    func testDecodesEmptyBody() throws {
        let result = try decoder.decode(Data(), mockResponse())
        #expect(result == "")
    }

    @Test("Preserves newlines and whitespace")
    func testPreservesWhitespace() throws {
        let text = "line one\nline two\t tabbed"
        let result = try decoder.decode(Data(text.utf8), mockResponse())
        #expect(result == text)
    }

    @Test("Throws APIError.decodingFailed for invalid UTF-8 bytes")
    func testInvalidUTF8() {
        #expect(throws: APIError.decodingFailed(URLError(.unknown))) {
            try decoder.decode(Data([0xFF, 0xFE]), mockResponse())
        }
    }

    @Test("Throws APIError.http for non-2xx status")
    func testHTTPError() {
        #expect(throws: APIError.http(status: 404, payload: nil)) {
            try decoder.decode(Data(), mockResponse(status: 404))
        }
    }

    @Test("APIError.http carries non-empty response body as payload")
    func testHTTPErrorPayload() throws {
        do {
            _ = try decoder.decode(Data("Not Found".utf8), mockResponse(status: 404))
            Issue.record("Expected throw")
        } catch let e as APIError {
            guard case .http(let status, let payload) = e else {
                Issue.record("Wrong error case: \(e)"); return
            }
            #expect(status == 404)
            #expect(payload == "Not Found")
        }
    }
}

// MARK: - EmptyResponseDecoder

@Suite("EmptyResponseDecoder")
struct EmptyResponseDecoderTests {

    private let decoder = EmptyResponseDecoder()

    @Test("Accept header is nil")
    func testNoAcceptHeader() {
        #expect(decoder.acceptHeader == nil)
    }

    @Test("Returns Empty for 2xx response")
    func testReturnsEmpty() throws {
        _ = try decoder.decode(Data(), mockResponse(status: 200))
    }

    @Test("Ignores response body content")
    func testIgnoresBody() throws {
        _ = try decoder.decode(Data("anything".utf8), mockResponse(status: 204))
    }

    @Test("Throws APIError.http for 4xx")
    func testHTTP4xx() {
        #expect(throws: APIError.http(status: 422, payload: nil)) {
            try decoder.decode(Data(), mockResponse(status: 422))
        }
    }

    @Test("Throws APIError.http for 5xx")
    func testHTTP5xx() {
        #expect(throws: APIError.http(status: 503, payload: nil)) {
            try decoder.decode(Data(), mockResponse(status: 503))
        }
    }

    @Test("APIError.http carries non-empty body as payload")
    func testHTTPErrorWithPayload() throws {
        do {
            _ = try decoder.decode(Data("Service Unavailable".utf8), mockResponse(status: 503))
            Issue.record("Expected throw")
        } catch let e as APIError {
            guard case .http(let status, let payload) = e else {
                Issue.record("Wrong error case: \(e)"); return
            }
            #expect(status == 503)
            #expect(payload == "Service Unavailable")
        }
    }
}

// MARK: - JSONResponseDecoder

@Suite("JSONResponseDecoder")
struct JSONResponseDecoderTests {

    private struct Item: Codable, Equatable { let id: Int; let name: String }

    @Test("Accept header is application/json")
    func testAcceptHeader() {
        #expect(JSONResponseDecoder<Item>().acceptHeader == "application/json")
    }

    @Test("Decodes valid JSON into expected type")
    func testDecodesJSON() throws {
        let data = Data(#"{"id":1,"name":"widget"}"#.utf8)
        let item = try JSONResponseDecoder<Item>().decode(data, mockResponse())
        #expect(item == Item(id: 1, name: "widget"))
    }

    @Test("Throws APIError.decodingFailed for malformed JSON")
    func testMalformedJSON() {
        #expect(throws: APIError.decodingFailed(URLError(.unknown))) {
            try JSONResponseDecoder<Item>().decode(Data("not json".utf8), mockResponse())
        }
    }

    @Test("Throws APIError.decodingFailed for type mismatch")
    func testTypeMismatch() {
        // id is expected to be Int but JSON has a String
        #expect(throws: APIError.decodingFailed(URLError(.unknown))) {
            try JSONResponseDecoder<Item>().decode(Data(#"{"id":"x","name":"y"}"#.utf8), mockResponse())
        }
    }

    @Test("Throws APIError.http for non-2xx status")
    func testHTTPError() {
        #expect(throws: APIError.http(status: 500, payload: nil)) {
            try JSONResponseDecoder<Item>().decode(Data(), mockResponse(status: 500))
        }
    }

    @Test("APIError.http carries non-empty body as payload")
    func testHTTPErrorWithPayload() throws {
        do {
            _ = try JSONResponseDecoder<Item>().decode(Data(#"{"error":"gone"}"#.utf8), mockResponse(status: 410))
            Issue.record("Expected throw")
        } catch let e as APIError {
            guard case .http(let status, let payload) = e else {
                Issue.record("Wrong error case: \(e)"); return
            }
            #expect(status == 410)
            #expect(payload == #"{"error":"gone"}"#)
        }
    }

    @Test("Applies convertFromSnakeCase key decoding strategy")
    func testSnakeCaseKeyDecoding() throws {
        struct Snake: Decodable, Equatable { let firstName: String; let lastName: String }
        let data = Data(#"{"first_name":"John","last_name":"Doe"}"#.utf8)
        let result = try JSONResponseDecoder<Snake>(keyDecodingStrategy: .convertFromSnakeCase).decode(data, mockResponse())
        #expect(result == Snake(firstName: "John", lastName: "Doe"))
    }

    @Test("Uses custom JSONDecoder when provided")
    func testCustomDecoder() throws {
        struct Snake: Decodable, Equatable { let firstName: String }
        let custom = JSONDecoder()
        custom.keyDecodingStrategy = .convertFromSnakeCase
        let data = Data(#"{"first_name":"Alice"}"#.utf8)
        let result = try JSONResponseDecoder<Snake>(customDecoder: custom).decode(data, mockResponse())
        #expect(result == Snake(firstName: "Alice"))
    }
}
