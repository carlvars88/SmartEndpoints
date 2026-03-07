# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build the package
swift build

# Run all tests
swift test

# Run a single test by name
swift test --filter "DummyJSONAPITests/testGetSingleProduct"

# Run a test suite
swift test --filter "DummyJSONAPITests"
```

## Architecture

SmartEndpoints is a Swift Package (iOS 13+, Swift 6) providing a type-safe, protocol-oriented HTTP networking layer. The design uses associated types to enforce compile-time safety across the request/response lifecycle.

### Core Abstractions

**`APIProtocol`** — Represents an API service. Defines `baseUrl`, `defaultHeaders`, and an associated `Credentials` type. Implement once per backend service.

**`Endpoint`** — Represents a single API route. Declares four associated types that fully describe the request shape:
- `Result: ResultDecodable` — the decoded response type
- `Parameters: QueryParameterEncodable` — URL query parameters
- `Body: BodyEncodable` — request body
- `API: APIProtocol` — which service this endpoint belongs to

**`Request<E: Endpoint>`** — A value type that bundles an endpoint with its runtime data (queryParams, body, credentials, headers). Picks up the correct encoder/decoder instances from the associated types automatically. Convenience `init` overloads exist for common combinations where some of `Parameters`, `Body`, or `Credentials` are `None`.

**`NetworkClient`** — Protocol with `send(_:)` and `buildRequest(request:)`. `DefaultNetworkClient` wraps `URLSession` and delegates to `request.asURLRequest()`.

### Encoder/Decoder System

Each associated type on `Endpoint` carries its own encoder/decoder via a static property, resolved automatically when constructing a `Request`:

| Layer | Protocol | Built-in implementations |
|---|---|---|
| Query params | `QueryParameterEncoder` | `URLQueryEncoder<P: Encodable>`, `EmptyParametersEncoder` |
| Body | `RequestBodyEncoder` | `JSONBodyEncoder`, `FormURLEncodedBodyEncoder`, `MultipartBodyEncoder`, `EmptyBodyEncoder` |
| Credentials | `RequestCredentialsEncoder` | `BearerCredentialEncoder`, `BasicCredentialsEncoder`, `EmptyCredentialsEncoder` |
| Response | `ResponseDecoder` | `JSONResponseDecoder<T>`, `PlainTextDecoder`, `EmptyResponseDecoder` |

### Convenience Protocols

These protocols auto-wire the encoder/decoder via extensions, so conforming types need no additional boilerplate:

- `JSONDecodable` (= `Decodable + ResultDecodable`) → uses `JSONResponseDecoder`
- `JSONEncodable` (= `Encodable + BodyEncodable`) → uses `JSONBodyEncoder`
- `FormURLEncodeBodyEncodable` → uses `FormURLEncodedBodyEncoder`
- `BearerCredentialEncodable` → uses `BearerCredentialEncoder`

### Sentinel Types

- `None` — used for `Parameters`, `Body`, or `Credentials` when not applicable; its encoders are no-ops
- `Empty` — used as a `Result` type when the response body should be ignored

### Headers

`HTTPHeaders` (adapted from Alamofire) is an order-preserving, case-insensitive collection of `HTTPHeader` values. Request-level headers are merged with `API.defaultHeaders` (request headers take precedence by default). `HTTPHeader` provides static factory methods for common headers (`.authorization(bearerToken:)`, `.contentType(_:)`, etc.).

### Error Handling

`APIError.http(status: Int, payload: String?)` is thrown by `JSONResponseDecoder` (and other decoders) when the HTTP status is outside 2xx.

### Typical Usage Pattern

```swift
// 1. Define an API
struct MyAPI: APIProtocol {
    typealias Credentials = BearerCredential
    static let baseUrl = "https://api.example.com"
}

// 2. Define an Endpoint
struct GetUserEndpoint: Endpoint {
    typealias Result = User      // User: JSONDecodable
    typealias Parameters = None
    typealias Body = None
    typealias API = MyAPI

    let userId: Int
    var api: MyAPI.Type { MyAPI.self }
    var path: Path { Path("/users/:id", values: ["id": "\(userId)"]) }
    var method: HTTPMethod { .get }
}

// 3. Build and send a Request
let client = DefaultNetworkClient()
let (user, _) = try await client.send(
    Request(endpoint: GetUserEndpoint(userId: 42),
            credentials: BearerCredential(value: token))
)
```
