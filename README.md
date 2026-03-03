# SmartEndpoints

SmartEndpoints is a Swift library for defining API endpoints in a type-safe, protocol-oriented way. It replaces the common pattern of modelling endpoints as a single enum — popularised by [Moya](https://github.com/Moya/Moya) — with a design where every endpoint is its own type, and the compiler enforces the correct encoder/decoder for every request component.

- **Platforms:** iOS 15+, macOS 12+
- **Swift:** 6.0+
- **Core dependencies:** none (Foundation only)

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
    typealias Result     = User    // decoded via JSONResponseDecoder
    typealias Parameters = None    // no query params
    typealias Body       = None    // no body
    typealias API        = MyAPI   // which service

    let userId: Int
    var path: Path     { Path("/users/:id", values: ["id": "\(userId)"]) }
    var method: HTTPMethod { .get }
}
```

Or with the optional macro product:

```swift
@GET("/users/:id")
struct GetUserEndpoint {
    typealias API    = MyAPI
    typealias Result = User
    let userId: Int
}
```

The compiler resolves the correct encoder/decoder for `Result`, `Parameters`, `Body`, and `Credentials` at compile time. Passing a JSON body to a form encoder, or forgetting credentials on a protected route, is a build error.

---

## Installation

### Core library (no dependencies)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/SmartEndpoints.git", from: "1.0.0")
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "SmartEndpoints", package: "SmartEndpoints")
        ]
    )
]
```

### With macros (optional, opt-in)

Adds `@GET`, `@POST`, `@PUT`, `@PATCH`, `@DELETE`, and `@endpoint` macros. Requires Swift 6.1+. Pulls in `swift-syntax` as a **build-time only** dependency — it is never linked into your app binary.

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "SmartEndpointsMacros", package: "SmartEndpoints")
    ]
)
```

`import SmartEndpointsMacros` re-exports `SmartEndpoints`, so one import covers everything.

---

## Table of Contents

- [Core Concepts](#core-concepts)
- [Defining an API](#defining-an-api)
- [API Endpoint Protocols](#api-endpoint-protocols)
- [Defining Endpoints](#defining-endpoints)
- [Endpoint Macros](#endpoint-macros)
- [Building Requests](#building-requests)
- [Using with URLSession](#using-with-urlsession)
- [Using with Alamofire](#using-with-alamofire)
- [Public vs. Authenticated APIs](#public-vs-authenticated-apis)
- [Per-Endpoint Credential Override](#per-endpoint-credential-override)
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

Three protocols describe every aspect of an HTTP endpoint:

| Protocol | Role |
|---|---|
| `APIProtocol` | Base URL, default headers, and default credential type for a service |
| `Endpoint` | Path, method, and the four associated types that shape the request |
| `Request<E: Endpoint>` | Bundles an endpoint with its runtime values (params, body, credentials, headers) |

The four associated types on `Endpoint` each carry their own encoder/decoder through a static property, resolved automatically by the type system:

```
Endpoint
├── Result:      ResultDecodable          →  ResponseDecoder
├── Parameters:  QueryParameterEncodable  →  QueryParameterEncoder
├── Body:        BodyEncodable            →  RequestBodyEncoder
├── API:         APIProtocol
│                └── Credentials: CredentialsEncodable  →  RequestCredentialsEncoder (default)
└── Credentials: CredentialsEncodable     →  RequestCredentialsEncoder (per-endpoint override)
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
        h.update(name: "Accept-Language", value: Locale.current.language.languageCode?.identifier ?? "en")
        return h
    }
}
```

---

## API Endpoint Protocols

Define a protocol per API that pre-fills `API` and `Credentials`. Every endpoint for that service then inherits both for free — no repeated typealiases.

```swift
protocol MyAPIEndpoint: Endpoint
    where API == MyAPI, Credentials == BearerCredential {}
```

Endpoints just conform to the protocol:

```swift
struct GetProductEndpoint: MyAPIEndpoint {
    typealias Result     = Product
    typealias Parameters = None
    typealias Body       = None

    let productId: Int
    var path: Path         { Path("/products/:id", values: ["id": "\(productId)"]) }
    var method: HTTPMethod { .get }
}
```

Combined with macros, only `Result` and the stored properties remain:

```swift
@GET("/products/:id")
struct GetProductEndpoint: MyAPIEndpoint {
    typealias Result = Product
    let productId: Int
}
```

### Public endpoints

For routes that require no authentication, constrain `Credentials` to `None`:

```swift
protocol PublicMyAPIEndpoint: Endpoint
    where API == MyAPI, Credentials == None {}
```

```swift
@GET("/products")
struct ListProductsEndpoint: PublicMyAPIEndpoint {
    typealias Result = [Product]
}
```

Attempting to pass credentials to a `PublicMyAPIEndpoint` request is a compile error, and attempting to omit them from a `MyAPIEndpoint` request is equally a compile error.

### Per-endpoint credential override

The `where Credentials ==` constraint on the endpoint protocol can be omitted entirely, leaving credential handling up to individual endpoints:

```swift
protocol MyAPIEndpoint: Endpoint where API == MyAPI {}

// Most endpoints use bearer tokens
struct GetOrderEndpoint: MyAPIEndpoint {
    typealias Credentials = BearerCredential
    …
}

// One endpoint uses basic auth
struct RefreshTokenEndpoint: MyAPIEndpoint {
    typealias Credentials = BasicCredentials
    …
}
```

---

## Defining Endpoints

Each endpoint conforms to `Endpoint` and declares associated types. Convenience protocols auto-wire the encoder/decoder so the associated type declaration is usually all that's needed:

```swift
struct SearchProductsEndpoint: Endpoint {
    typealias Result     = ProductsResponse  // JSONDecodable → JSONResponseDecoder
    typealias Parameters = SearchQuery       // Encodable → URLQueryEncoder
    typealias Body       = None
    typealias API        = MyAPI

    var path: Path         { Path("/products/search") }
    var method: HTTPMethod { .get }
}
```

### Path

`Path` holds the URL path string. It substitutes `:token` placeholders from a dictionary at init time:

```swift
Path("/users/:id", values: ["id": "\(userId)"])
// → "/users/42"

Path("/users/:userId/posts/:postId", values: ["userId": "\(userId)", "postId": "\(postId)"])
// → "/users/7/posts/99"
```

---

## Endpoint Macros

With `import SmartEndpointsMacros`, you can collapse the boilerplate down to what actually varies per endpoint.

**Without an API endpoint protocol** — `API` and `Result` must be declared manually:

```swift
@GET("/products/:id")
struct GetProduct {
    typealias API    = MyAPI     // required
    typealias Result = Product   // required
    let id: Int
}
```

**With an API endpoint protocol** (recommended) — only `Result` remains:

```swift
@GET("/products/:id")
struct GetProduct: MyAPIEndpoint {
    typealias Result = Product
    let id: Int
}
```

The macro synthesises:

| Generated | Value |
|---|---|
| `var method: HTTPMethod` | `.get` (or whichever method macro you use) |
| `var path: Path` | Built from the template + stored properties by name |
| `typealias Parameters = None` | Only if you don't declare it yourself |
| `typealias Body = None` | Only if you don't declare it yourself |
| `extension GetProduct: Endpoint` | Only if the struct has no inheritance clause |

### Override defaults

The macro emits `Parameters = None` and `Body = None` only if you haven't declared them. Declare either to override:

```swift
@POST("/products")
struct CreateProduct: MyAPIEndpoint {
    typealias Result = Product
    typealias Body   = NewProduct   // overrides None
    // Parameters stays None
}

@GET("/products")
struct ListProducts: MyAPIEndpoint {
    typealias Result     = [Product]
    typealias Parameters = ListQuery  // overrides None
    // Body stays None
}
```

### Available macros

| Macro | Method |
|---|---|
| `@GET("/path")` | GET |
| `@POST("/path")` | POST |
| `@PUT("/path")` | PUT |
| `@PATCH("/path")` | PATCH |
| `@DELETE("/path")` | DELETE |
| `@endpoint(.method, "/path")` | any `HTTPMethod` |

### Compile-time safety

If a `:token` in the path template has no matching stored property, the compiler emits an error:

```swift
@GET("/products/:id")
struct GetProduct {
    typealias API    = MyAPI
    typealias Result = Product
    // ❌ error: Path template uses ':id' but no stored property named 'id' was found
}
```

---

## Building Requests

`Request<E>` bundles an endpoint with its runtime values. Convenience initialisers exist for every combination of `None` components so you only provide what the endpoint actually needs:

```swift
// All four components present
Request(endpoint: e, queryParams: p, body: b, credentials: c)

// Combinations where some components are None
Request(endpoint: e)                             // Parameters, Body, Credentials all None
Request(endpoint: e, credentials: c)            // Parameters and Body are None
Request(endpoint: e, body: b)                   // Parameters and Credentials are None
Request(endpoint: e, body: b, credentials: c)  // Parameters is None
Request(endpoint: e, queryParams: p)            // Body and Credentials are None
Request(endpoint: e, query: p, credentials: c) // Body is None
Request(endpoint: e, query: p, body: b)        // Credentials is None
```

`Request` turns itself into a standard `URLRequest`:

```swift
let urlRequest: URLRequest = try request.asURLRequest()
```

---

## Using with URLSession

SmartEndpoints produces `URLRequest` values — plug them straight into `URLSession`:

```swift
let urlRequest = try Request(endpoint: GetProduct(id: 42),
                              credentials: BearerCredential(value: token))
                    .asURLRequest()

let (data, response) = try await URLSession.shared.data(for: urlRequest)
let httpResponse = response as! HTTPURLResponse
let product = try JSONDecoder().decode(Product.self, from: data)
```

Or wrap the pattern in a helper once and reuse it:

```swift
func send<E: Endpoint>(_ request: Request<E>) async throws -> (E.Result, HTTPURLResponse) {
    let urlRequest = try request.asURLRequest()
    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    let httpResponse = response as! HTTPURLResponse
    return (try E.Result.resultDecoder.decode(data, httpResponse), httpResponse)
}
```

---

## Using with Alamofire

Because `Request` already implements `asURLRequest()`, conforming to Alamofire's `URLRequestConvertible` takes one line in your app module:

```swift
import Alamofire
import SmartEndpoints

extension Request: URLRequestConvertible {}
```

Then pass any `Request` directly to `AF.request`:

```swift
AF.request(
    Request(endpoint: GetProduct(id: 42), credentials: BearerCredential(value: token))
)
.responseDecodable(of: Product.self) { response in
    // …
}
```

---

## Public vs. Authenticated APIs

Use the [API Endpoint Protocols](#api-endpoint-protocols) pattern to separate public and authenticated routes. Define two endpoint protocols — one for each credential level:

```swift
struct MyAPI: APIProtocol {
    typealias Credentials = BearerCredential
    static let baseUrl = "https://api.example.com"
}

// Authenticated endpoints — BearerCredential required at the call site
protocol MyAPIEndpoint: Endpoint where API == MyAPI, Credentials == BearerCredential {}

// Public endpoints — no credentials required
protocol PublicMyAPIEndpoint: Endpoint where API == MyAPI, Credentials == None {}
```

Assign each endpoint to the appropriate protocol. Attempting to build a `Request` for a `MyAPIEndpoint` without a `BearerCredential` is a compile error.

```swift
@GET("/auth/login")
struct LoginEndpoint: PublicMyAPIEndpoint {   // no credentials
    typealias Result = AuthToken
}

@GET("/profile")
struct GetProfileEndpoint: MyAPIEndpoint {    // BearerCredential required
    typealias Result = UserProfile
}
```

---

## Per-Endpoint Credential Override

`Credentials` defaults to `API.Credentials` but can be overridden per endpoint by declaring a different `typealias Credentials`. This is useful when a single route within an authenticated API is publicly accessible:

```swift
// Most endpoints use MyAPIEndpoint (BearerCredential required)
// This one opts out by declaring Credentials = None directly
@GET("/products/:id")
struct GetPublicProductEndpoint: Endpoint {
    typealias API         = MyAPI
    typealias Credentials = None     // overrides the API default
    typealias Result      = Product
    let id: Int
}

// No credentials argument required — the type system enforces it
Request(endpoint: GetPublicProductEndpoint(id: 42))
```

For a more structured approach, see [API Endpoint Protocols](#api-endpoint-protocols).

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
    fields: [
        KeyValuePair(key: "description", value: "Profile photo")
    ],
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

To customise the decoder per endpoint, override `resultDecoder` on your response type:

```swift
extension MyType {
    static var resultDecoder: JSONResponseDecoder<Self> {
        JSONResponseDecoder(keyDecodingStrategy: .convertFromSnakeCase)
    }
}
```

### Plain text response

Declare `Result = String`. `String` already conforms to `ResultDecodable` via `PlainTextDecoder`. Adds `Accept: text/plain`, validates 2xx, and throws `APIError.decodingFailed` if the body is not valid UTF-8.

### Ignored response body

Declare `Result = Empty`. `EmptyResponseDecoder` validates the 2xx range and throws `APIError.http` on error responses but discards the body.

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

All errors thrown by the library are `APIError`. Callers only need to catch one type:

```swift
do {
    let (user, _) = try send(request)
} catch let error as APIError {
    switch error {
    case .http(let status, let payload):
        // Non-2xx response. payload is the raw response body, or nil if empty.
        print("HTTP \(status): \(payload ?? "no body")")
    case .invalidURL:
        // API.baseUrl could not be parsed as a valid URL.
        print("Malformed base URL")
    case .bodyNotAllowed(let method):
        // A body was set on a GET, HEAD, DELETE, or TRACE request.
        print("Body not allowed for \(method)")
    case .encodingFailed(let underlying):
        // A parameter, body, or credential encoder threw an error.
        print("Encoding failed: \(underlying)")
    case .decodingFailed(let underlying):
        // The response decoder threw an error (e.g. malformed JSON, invalid UTF-8).
        print("Decoding failed: \(underlying)")
    }
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
