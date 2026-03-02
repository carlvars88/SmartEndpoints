# SmartEndpoints

SmartEndpoints is a Swift library for defining API endpoints in a type-safe, protocol-oriented way. It replaces the common pattern of modelling endpoints as a single enum — popularised by [Moya](https://github.com/Moya/Moya) — with a design where every endpoint is its own type, and the compiler enforces the correct encoder/decoder for every request component.

- **Platforms:** iOS 15+, macOS 12+
- **Swift:** 6.0
- **Dependencies:** none (Foundation only)

---

## The Problem with the Enum Approach

Most Swift projects model their API endpoints as a large enum:

```swift
enum API {
    case getUser(id: Int)
    case login(username: String, password: String)
    case uploadAvatar(userId: Int, image: Data)
}
```

This leads to a growing `switch` statement that handles URL construction, headers, body encoding, and response decoding for every case. Adding or changing an endpoint means editing a central file and ensuring every `switch` branch remains exhaustive. The compiler knows which *case* you used, but it has no knowledge of what *shape* the request or response has — body encoder, parameter encoder, decoder, and credential type are all resolved at runtime.

---

## The SmartEndpoints Approach

Each endpoint is a dedicated type that declares its exact request shape through associated types:

```swift
struct GetUserEndpoint: Endpoint {
    typealias Result     = User            // decoded via JSONResponseDecoder
    typealias Parameters = None            // no query params
    typealias Body       = None            // no body
    typealias API        = MyAPI           // which service

    let userId: Int
    var api: API.Type  { MyAPI.self }
    var path: Path     { Path("/users/\(userId)") }
    var method: HTTPMethod { .get }
}
```

The compiler resolves the correct encoder/decoder for `Result`, `Parameters`, `Body`, and `Credentials` at compile time. Passing a JSON body to a form encoder, or forgetting credentials on a protected route, is a build error.

---

## Installation

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/carlvars88/SmartEndpoints.git", from: "1.0.0")
]
```

Or add it via **Xcode → File → Add Package Dependencies**.

---

## Table of Contents

- [Core Concepts](#core-concepts)
- [Defining an API](#defining-an-api)
- [Defining Endpoints](#defining-endpoints)
- [Building and Sending Requests](#building-and-sending-requests)
- [Public vs. Authenticated APIs](#public-vs-authenticated-apis)
- [Query Parameters](#query-parameters)
- [Request Body](#request-body)
- [Response Decoding](#response-decoding)
- [Credentials](#credentials)
- [Headers](#headers)
- [Error Handling](#error-handling)
- [Sentinel Types](#sentinel-types)
- [Encoder / Decoder Reference](#encoder--decoder-reference)

---

## Core Concepts

Four protocols describe every aspect of an HTTP endpoint:

| Protocol | Role |
|---|---|
| `APIProtocol` | Base URL, default headers, and credential type for a service |
| `Endpoint` | Path, method, and the four associated types that shape the request |
| `Request<E>` | Bundles an endpoint with its runtime values (params, body, credentials, headers) |
| `NetworkClient` | Executes a `Request` and returns the decoded result |

The four associated types on `Endpoint` each carry their own encoder/decoder through a static property, resolved automatically by the type system:

```
Endpoint
├── Result:     ResultDecodable          →  ResponseDecoder
├── Parameters: QueryParameterEncodable  →  QueryParameterEncoder
├── Body:       BodyEncodable            →  RequestBodyEncoder
└── API:        APIProtocol
                └── Credentials: CredentialsEncodable  →  RequestCredentialsEncoder
```

Convenience protocols (`JSONDecodable`, `JSONEncodable`, `BearerCredentialEncodable`, …) auto-wire the standard encoders/decoders so conforming types need no additional boilerplate.

---

## Defining an API

`APIProtocol` represents a backend service. Define it once per service.

```swift
struct MyAPI: APIProtocol {
    typealias Credentials = BearerCredential

    static let baseUrl = "https://api.example.com"

    // Optional — applied to every request against this API
    static var defaultHeaders: HTTPHeaders {
        var h = HTTPHeaders()
        h["Content-Type"] = "application/json"
        return h
    }
}
```

---

## Defining Endpoints

Each endpoint conforms to `Endpoint` and declares four associated types. Convenience protocols auto-wire the encoder/decoder so the associated type declaration is usually all that's needed:

```swift
struct SearchProductsEndpoint: Endpoint {
    typealias Result     = ProductsResponse  // JSONDecodable → JSONResponseDecoder
    typealias Parameters = SearchQuery       // QueryParameterEncodable → URLQueryEncoder
    typealias Body       = None              // no body
    typealias API        = MyAPI

    var api: API.Type  { MyAPI.self }
    var path: Path     { Path("/products/search") }
    var method: HTTPMethod { .get }
}
```

### Path

`Path` holds the URL path string. Values can be interpolated inline or substituted via a dictionary:

```swift
Path("/users/\(userId)")
Path("/users/:id", values: ["id": "\(userId)"])
```

---

## Building and Sending Requests

`Request<E>` bundles an endpoint with its runtime values. Convenience initialisers exist for every combination of `None` components so you only provide what the endpoint actually needs:

```swift
// All four components present
Request(endpoint: e, queryParams: p, body: b, credentials: c)

// Combinations where some components are None
Request(endpoint: e)                            // Parameters, Body, Credentials all None
Request(endpoint: e, credentials: c)           // Parameters and Body are None
Request(endpoint: e, body: b)                  // Parameters and Credentials are None
Request(endpoint: e, body: b, credentials: c) // Parameters is None
Request(endpoint: e, queryParams: p)           // Body and Credentials are None
Request(endpoint: e, query: p, credentials: c) // Body is None
Request(endpoint: e, query: p, body: b)        // Credentials is None
```

`Request` can be converted to a standard `URLRequest` at any point:

```swift
let urlRequest: URLRequest = try request.asURLRequest()
```

`DefaultNetworkClient` is a thin `URLSession` wrapper that executes a `Request` and returns the decoded result:

```swift
let client = DefaultNetworkClient()
let (products, _) = try await client.send(
    Request(endpoint: SearchProductsEndpoint(), queryParams: SearchQuery(q: "phone"))
)
```

`send` returns `(E.Result, HTTPURLResponse)`, so you can inspect headers and status codes after decoding.

---

## Public vs. Authenticated APIs

Many services expose both public and protected routes under the same base URL. Define two API types rather than making credentials optional:

```swift
/// Endpoints documented as not requiring an Authorization header
struct PublicMyAPI: APIProtocol {
    typealias Credentials = None
    static let baseUrl = "https://api.example.com"
}

/// Endpoints that require a Bearer token
struct MyAPI: APIProtocol {
    typealias Credentials = BearerCredential
    static let baseUrl = "https://api.example.com"
}
```

Assign each endpoint to the appropriate API. Attempting to build a `Request` for a `MyAPI` endpoint without a `BearerCredential` is a compile error.

```swift
// Public — no credentials in the Request
struct LoginEndpoint: Endpoint {
    typealias API = PublicMyAPI
    …
}

// Private — credentials are required by the type system
struct GetProfileEndpoint: Endpoint {
    typealias API = MyAPI
    …
}
```

```swift
let (auth, _) = try await client.send(
    Request(endpoint: LoginEndpoint(), body: LoginBody(username: u, password: p))
)

let (profile, _) = try await client.send(
    Request(endpoint: GetProfileEndpoint(),
            credentials: BearerCredential(value: auth.accessToken))
)
```

---

## Query Parameters

Conform your parameter type to `QueryParameterEncodable`:

```swift
struct SearchQuery: Codable, Sendable, QueryParameterEncodable {
    let q: String
    let limit: Int?

    static var queryParameterEncoder: URLQueryEncoder<Self> { .init() }
}
```

`URLQueryEncoder` serialises any `Encodable` type into URL query items. `nil` properties are omitted automatically.

---

## Request Body

### JSON body

Conform to `JSONEncodable` (`Encodable + BodyEncodable`). Sets `Content-Type: application/json`.

```swift
struct CreatePostBody: Codable, Sendable, JSONEncodable {
    let title: String
    let content: String
}
```

### Form URL-encoded body

Conform to `FormURLEncodeBodyEncodable`. Sets `Content-Type: application/x-www-form-urlencoded` with RFC 3986 percent-encoding.

```swift
struct LoginForm: Codable, Sendable, FormURLEncodeBodyEncodable {
    let username: String
    let password: String
}
```

### Multipart form data

Use `MultipartParts` as the `Body` type. Sets `Content-Type: multipart/form-data; boundary=…`.

```swift
struct UploadAvatarEndpoint: Endpoint {
    typealias Body = MultipartParts
    …
}

let parts = MultipartParts(
    fields: [("description", "Profile photo")],
    files: [
        MultipartFile(name: "avatar", filename: "photo.jpg",
                      mimeType: "image/jpeg", data: imageData)
    ]
)
Request(endpoint: UploadAvatarEndpoint(), body: parts)
```

### No body

Use `None`. `EmptyBodyEncoder` is a no-op and is wired automatically.

---

## Response Decoding

### JSON response

Conform the result type to `JSONDecodable` (`Decodable + ResultDecodable`). Adds `Accept: application/json` and validates the 2xx status range before decoding.

```swift
struct Product: Codable, Sendable, JSONDecodable {
    let id: Int
    let title: String
}
```

`JSONResponseDecoder` can be customised:

```swift
JSONResponseDecoder<MyType>(
    keyDecodingStrategy: .convertFromSnakeCase,
    dateDecodingStrategy: .iso8601
)

// or provide a fully configured JSONDecoder
JSONResponseDecoder<MyType>(customDecoder: myDecoder)
```

### Plain text response

Declare `Result = String`. `String` already conforms to `ResultDecodable` via `PlainTextDecoder`. Adds `Accept: text/plain`, validates 2xx, and throws `DecodingError` if the body is not valid UTF-8.

### Ignored response body

Declare `Result = Empty`. `EmptyResponseDecoder` validates the 2xx range and throws on error responses but discards the body.

---

## Credentials

### Bearer token

`BearerCredential` conforms to `BearerCredentialEncodable` and is auto-wired to `BearerCredentialEncoder`, which adds `Authorization: Bearer <value>`.

```swift
struct MyAPI: APIProtocol {
    typealias Credentials = BearerCredential
    …
}

Request(endpoint: e, credentials: BearerCredential(value: token))
```

### Basic auth

`BasicCredentials` is wired to `BasicCredentialsEncoder`, which adds `Authorization: Basic <base64(username:password)>`.

```swift
struct MyAPI: APIProtocol {
    typealias Credentials = BasicCredentials
    …
}

Request(endpoint: e, credentials: BasicCredentials(username: u, password: p))
```

### No credentials

Use `None` as the `Credentials` type. `EmptyCredentialsEncoder` is a no-op and is wired automatically.

---

## Headers

### Request-level headers

```swift
var headers = HTTPHeaders()
headers["X-Request-ID"] = UUID().uuidString

Request(endpoint: e, queryParams: p, headers: headers)
```

### Merge precedence (lowest → highest)

1. `API.defaultHeaders`
2. Decoder's `acceptHeader` (e.g. `"application/json"` from `JSONResponseDecoder`)
3. Request-level `headers` — always win

### HTTPHeaders API

`HTTPHeaders` is an order-preserving, case-insensitive collection adapted from Alamofire:

```swift
var h = HTTPHeaders()
h.add(name: "X-Foo", value: "bar")
h.update(name: "X-Foo", value: "baz")   // update in place
h.remove(name: "X-Foo")
h.value(for: "x-foo")                   // case-insensitive lookup
h["Accept"] = "application/json"        // subscript set / remove

let merged = requestHeaders.merge(apiDefaultHeaders)
```

`HTTPHeader` factory methods cover the most common headers:

```swift
.contentType("application/json")
.authorization(bearerToken: token)
.authorization(username: u, password: p)
.accept("application/json")
.userAgent("MyApp/1.0")
```

---

## Error Handling

Every decoder validates the HTTP status code before decoding and throws for non-2xx responses:

```swift
do {
    let (user, _) = try await client.send(request)
} catch let error as APIError {
    switch error {
    case .http(let status, let payload):
        print("HTTP \(status): \(payload ?? "no body")")
    case .invalidURL:
        print("Malformed base URL")
    }
} catch {
    // URLError, DecodingError, …
}
```

`APIError.http` carries both the status code and the raw response body as `String?`, making it straightforward to surface server-provided error messages.

---

## Sentinel Types

| Type | Used as | Wires to |
|---|---|---|
| `None` | `Parameters`, `Body`, or `Credentials` | No-op encoders (`EmptyParametersEncoder`, `EmptyBodyEncoder`, `EmptyCredentialsEncoder`) |
| `Empty` | `Result` | `EmptyResponseDecoder` — validates 2xx, discards body |

---

## Encoder / Decoder Reference

### Query parameter encoders

| Type | Behaviour |
|---|---|
| `URLQueryEncoder<P: Encodable>` | Serialises any `Encodable` to URL query items; omits `nil` |
| `EmptyParametersEncoder` | No-op, used with `None` |

### Body encoders

| Type | `Content-Type` |
|---|---|
| `JSONBodyEncoder<B: Encodable>` | `application/json` |
| `FormURLEncodedBodyEncoder<B: Encodable>` | `application/x-www-form-urlencoded` |
| `MultipartBodyEncoder` | `multipart/form-data; boundary=…` |
| `EmptyBodyEncoder` | — |

### Credentials encoders

| Type | Header added |
|---|---|
| `BearerCredentialEncoder` | `Authorization: Bearer <token>` |
| `BasicCredentialsEncoder` | `Authorization: Basic <base64>` |
| `EmptyCredentialsEncoder` | — |

### Response decoders

| Type | `Accept` header | Validates 2xx |
|---|---|---|
| `JSONResponseDecoder<T: Decodable>` | `application/json` | Yes |
| `PlainTextDecoder` | `text/plain` | Yes |
| `EmptyResponseDecoder` | — | Yes |
