
//
//  SmartEndpoinsTests.swift
//  SmartEndpoints
//
//  Created on 3/2/26.
//

import Testing
import Foundation
@testable import SmartEndpoints

// MARK: - DummyJSON API Definition

/// Public (unauthenticated) API configuration for https://dummyjson.com/
struct PublicDummyJSONAPI: APIProtocol {
    typealias Credentials = None
    static let baseUrl = "https://dummyjson.com"
    static var defaultHeaders: HTTPHeaders {
        var headers = HTTPHeaders()
        headers["Content-Type"] = "application/json"
        return headers
    }
}

/// Authenticated API configuration for https://dummyjson.com/ (requires Bearer token)
struct DummyJSONAPI: APIProtocol {
    typealias Credentials = BearerCredential
    static let baseUrl = "https://dummyjson.com"
    static var defaultHeaders: HTTPHeaders {
        var headers = HTTPHeaders()
        headers["Content-Type"] = "application/json"
        return headers
    }
}

typealias DummyAPIJSONResult = JSONDecodable

// MARK: - Data Models

struct Product: Codable, Sendable, JSONDecodable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let discountPercentage: Double?
    let rating: Double?
    let stock: Int?
    let brand: String?
    let category: String?
    let thumbnail: String?
    let images: [String]?
}

struct ProductsResponse: Codable, Sendable, JSONDecodable {
    let products: [Product]
    let total: Int
    let skip: Int
    let limit: Int
}

struct User: Codable, Sendable, JSONDecodable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let age: Int?
}

struct UsersResponse: Codable, Sendable, JSONDecodable {
    let users: [User]
    let total: Int
    let skip: Int
    let limit: Int
}

struct AuthResponse: Codable, Sendable, JSONDecodable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let gender: String
    let image: String
    let accessToken: String
}

struct LoginBody: Codable, Sendable, JSONEncodable {
    let username: String
    let password: String
}

struct SearchParameters: Codable, Sendable {
    let q: String  // Changed from 'query' to match API parameter name
}

struct PaginationParameters: Codable, Sendable {
    let limit: Int?
    let skip: Int?
}

// MARK: - Protocol Conformances

extension SearchParameters: QueryParameterEncodable {
    static var queryParameterEncoder: URLQueryEncoder<Self> { .init() }
}

extension PaginationParameters: QueryParameterEncodable {
    static var queryParameterEncoder: URLQueryEncoder<Self> { .init() }
}


// MARK: - Endpoints

// MARK: - Public Endpoints (no authentication required)

/// GET /products - Get all products
struct GetProductsEndpoint: Endpoint {
    typealias Result = ProductsResponse
    typealias Parameters = PaginationParameters
    typealias Body = None
    typealias API = PublicDummyJSONAPI

    var api: API.Type { PublicDummyJSONAPI.self }
    var path: Path { Path("/products") }
    var method: HTTPMethod { .get }
}

/// GET /products/{id} - Get a single product
struct GetProductEndpoint: Endpoint {
    typealias Result = Product
    typealias Parameters = None
    typealias Body = None
    typealias API = PublicDummyJSONAPI

    let productId: Int

    var api: API.Type { PublicDummyJSONAPI.self }
    var path: Path { Path("/products/\(productId)") }
    var method: HTTPMethod { .get }
}

/// GET /products/search - Search products
struct SearchProductsEndpoint: Endpoint {
    typealias Result = ProductsResponse
    typealias Parameters = SearchParameters
    typealias Body = None
    typealias API = PublicDummyJSONAPI

    var api: API.Type { PublicDummyJSONAPI.self }
    var path: Path { Path("/products/search") }
    var method: HTTPMethod { .get }
}

/// GET /users - Get all users
struct GetUsersEndpoint: Endpoint {
    typealias Result = UsersResponse
    typealias Parameters = PaginationParameters
    typealias Body = None
    typealias API = PublicDummyJSONAPI

    var api: API.Type { PublicDummyJSONAPI.self }
    var path: Path { Path("/users") }
    var method: HTTPMethod { .get }
}

/// GET /users/{id} - Get a single user
struct GetUserEndpoint: Endpoint {
    typealias Result = User
    typealias Parameters = None
    typealias Body = None
    typealias API = PublicDummyJSONAPI

    let userId: Int

    var api: API.Type { PublicDummyJSONAPI.self }
    var path: Path { Path("/users/\(userId)") }
    var method: HTTPMethod { .get }
}

/// POST /auth/login - Login endpoint (public — no credentials needed)
struct LoginEndpoint: Endpoint {
    typealias Result = AuthResponse
    typealias Parameters = None
    typealias Body = LoginBody
    typealias API = PublicDummyJSONAPI

    var api: API.Type { PublicDummyJSONAPI.self }
    var path: Path { Path("/auth/login") }
    var method: HTTPMethod { .post }
}

// MARK: - Private Endpoints (Bearer token required)

/// GET /auth/me - Fetch the authenticated user's profile
struct GetMeEndpoint: Endpoint {
    typealias Result = User
    typealias Parameters = None
    typealias Body = None
    typealias API = DummyJSONAPI

    var api: API.Type { DummyJSONAPI.self }
    var path: Path { Path("/auth/me") }
    var method: HTTPMethod { .get }
}

// MARK: - Test Suite

@Suite("DummyJSON API Tests")
struct DummyJSONAPITests {
    let client = DefaultNetworkClient()
    
    // MARK: - Product Tests
    
    @Test("Fetch all products with pagination")
    func testGetAllProducts() async throws {
        // Arrange
        let endpoint = GetProductsEndpoint()
        let request = Request(
            endpoint: endpoint,
            queryParams: PaginationParameters(limit: 10, skip: 0)
        )
        
        // Act
        let (response, _) = try await client.send(request)
        
        // Assert
        #expect(response.products.count > 0, "Should return at least one product")
        #expect(response.products.count <= 10, "Should respect limit parameter")
        #expect(response.total > 0, "Total should be greater than zero")
        #expect(response.limit == 10, "Limit should match request")
        #expect(response.skip == 0, "Skip should match request")
    }
    
    @Test("Fetch single product by ID")
    func testGetSingleProduct() async throws {
        // Arrange
        let endpoint = GetProductEndpoint(productId: 1)
        let request = Request(endpoint: endpoint)
        
        // Act
        let (product, _) = try await client.send(request)
        
        // Assert
        #expect(product.id == 1, "Product ID should match requested ID")
        #expect(!product.title.isEmpty, "Product should have a title")
        #expect(!product.description.isEmpty, "Product should have a description")
        #expect(product.price > 0, "Product should have a positive price")
    }
    
    @Test("Search products by query")
    func testSearchProducts() async throws {
        // Arrange
        let endpoint = SearchProductsEndpoint()
        let request = Request(
            endpoint: endpoint,
            queryParams: SearchParameters(q: "phone")
        )
        
        // Act
        let (response, _) = try await client.send(request)
        
        // Assert
        #expect(response.products.count > 0, "Should find products matching 'phone'")
        
        // Check if any product title contains "phone" (case-insensitive)
        let hasPhoneInTitle = response.products.contains { product in
            product.title.lowercased().contains("phone")
        }
        #expect(hasPhoneInTitle, "At least one product should have 'phone' in title")
    }
    
    @Test("Pagination with skip parameter")
    func testProductsPagination() async throws {
        // Arrange
        let endpoint = GetProductsEndpoint()
        let firstPageRequest = Request(
            endpoint: endpoint,
            queryParams: PaginationParameters(limit: 5, skip: 0)
        )
        let secondPageRequest = Request(
            endpoint: endpoint,
            queryParams: PaginationParameters(limit: 5, skip: 5)
        )
        
        // Act
        let (firstPage, _) = try await client.send(firstPageRequest)
        let (secondPage, _) = try await client.send(secondPageRequest)
        
        // Assert
        #expect(firstPage.products.count == 5, "First page should have 5 products")
        #expect(secondPage.products.count == 5, "Second page should have 5 products")
        
        // Products should be different
        let firstIds = Set(firstPage.products.map(\.id))
        let secondIds = Set(secondPage.products.map(\.id))
        #expect(firstIds.isDisjoint(with: secondIds), "Pages should have different products")
    }
    
    // MARK: - User Tests
    
    @Test("Fetch all users")
    func testGetAllUsers() async throws {
        // Arrange
        let endpoint = GetUsersEndpoint()
        let request = Request(
            endpoint: endpoint,
            queryParams: PaginationParameters(limit: 5, skip: nil)
        )
        
        // Act
        let (response, _) = try await client.send(request)
        
        // Assert
        #expect(response.users.count > 0, "Should return at least one user")
        #expect(response.users.count <= 5, "Should respect limit parameter")
        #expect(response.total > 0, "Total users should be greater than zero")
    }
    
    @Test("Fetch single user by ID")
    func testGetSingleUser() async throws {
        // Arrange
        let endpoint = GetUserEndpoint(userId: 1)
        let request = Request(endpoint: endpoint)
        
        // Act
        let (user, _) = try await client.send(request)
        
        // Assert
        #expect(user.id == 1, "User ID should match requested ID")
        #expect(!user.firstName.isEmpty, "User should have a first name")
        #expect(!user.lastName.isEmpty, "User should have a last name")
        #expect(!user.email.isEmpty, "User should have an email")
    }
    
    // MARK: - Authentication Tests
    
    @Test("User login with credentials")
    func testUserLogin() async throws {
        // Arrange
        let endpoint = LoginEndpoint()
        let loginBody = LoginBody(username: "emilys", password: "emilyspass")
        let request = Request(
            endpoint: endpoint,
            body: loginBody
        )

        // Act
        let (authResponse, _) = try await client.send(request)

        // Assert
        #expect(authResponse.id > 0, "Should return a valid user ID")
        #expect(!authResponse.accessToken.isEmpty, "Should return a valid token")
        #expect(authResponse.username == "emilys", "Username should match")
        #expect(!authResponse.email.isEmpty, "Should have an email")
        #expect(!authResponse.firstName.isEmpty, "Should have a first name")
    }

    @Test("Fetch authenticated user profile with bearer token")
    func testGetAuthenticatedUserProfile() async throws {
        // Arrange — first obtain a token via the public login endpoint
        let loginRequest = Request(
            endpoint: LoginEndpoint(),
            body: LoginBody(username: "emilys", password: "emilyspass")
        )
        let (authResponse, _) = try await client.send(loginRequest)

        // Act — use the token on a private endpoint
        let meRequest = Request(
            endpoint: GetMeEndpoint(),
            credentials: BearerCredential(value: authResponse.accessToken)
        )
        let (me, _) = try await client.send(meRequest)

        // Assert
        #expect(me.id == authResponse.id, "Profile ID should match the logged-in user")
        #expect(!me.firstName.isEmpty, "Should have a first name")
        #expect(!me.email.isEmpty, "Should have an email")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handle invalid product ID")
    func testInvalidProductId() async throws {
        // Arrange
        let endpoint = GetProductEndpoint(productId: 999999)
        let request = Request(endpoint: endpoint)
        
        // Act & Assert
        do {
            _ = try await client.send(request)
            Issue.record("Expected error for invalid product ID")
        } catch let error as APIError {
            if case .http(let status, _) = error {
                #expect(status == 404, "Should return 404 for non-existent product")
            }
        }
    }
    
    @Test("Handle empty search query")
    func testEmptySearchQuery() async throws {
        // Arrange
        let endpoint = SearchProductsEndpoint()
        let request = Request(
            endpoint: endpoint,
            queryParams: SearchParameters(q: "")
        )
        
        // Act
        let (response, _) = try await client.send(request)
        
        // Assert - Empty query should return all products
        #expect(response.products.count > 0, "Empty search should return products")
    }
    
    // MARK: - Request Building Tests
    
    @Test("Build URL request with query parameters")
    func testURLRequestBuilding() throws {
        // Arrange
        let endpoint = SearchProductsEndpoint()
        let request = Request(
            endpoint: endpoint,
            queryParams: SearchParameters(q: "laptop")
        )
        
        // Act
        let urlRequest = try request.asURLRequest()
        
        // Assert
        #expect(urlRequest.url?.absoluteString.contains("q=laptop") == true,
                "URL should contain query parameter")
        #expect(urlRequest.method == .get, "Method should be GET")
    }
    
    @Test("Build URL request with body")
    func testURLRequestWithBody() throws {
        // Arrange
        let endpoint = LoginEndpoint()
        let loginBody = LoginBody(username: "test", password: "test123")
        let request = Request(endpoint: endpoint, body: loginBody)
        
        // Act
        let urlRequest = try request.asURLRequest()
        
        // Assert
        #expect(urlRequest.method == .post, "Method should be POST")
        #expect(urlRequest.httpBody != nil, "Should have request body")
        #expect(urlRequest.url?.path == "/auth/login", "Path should be correct")
    }
    
    @Test("Verify default headers are applied")
    func testDefaultHeaders() throws {
        // Arrange - Test that default API headers are applied
        let endpoint = GetProductsEndpoint()
        let request = Request(
            endpoint: endpoint,
            queryParams: PaginationParameters(limit: nil, skip: nil)
        )
        
        // Act
        let urlRequest = try request.asURLRequest()
        
        // Assert - Default headers from DummyJSONAPI should now be applied
        let contentType = urlRequest.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType == "application/json", "Should have default Content-Type header from API")
    }
    
    @Test("Custom headers can be added to request")
    func testCustomHeaders() throws {
        // Arrange
        var customHeaders = HTTPHeaders()
        customHeaders["X-Custom-Header"] = "CustomValue"
        customHeaders["Authorization"] = "Bearer test-token"
        
        let endpoint = GetProductsEndpoint()
        let request = Request(
            endpoint: endpoint,
            queryParams: PaginationParameters(limit: 10, skip: 0),
            headers: customHeaders
        )
        
        // Act
        let urlRequest = try request.asURLRequest()
        
        // Assert - Custom headers should be present
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom-Header") == "CustomValue", 
                "Should have custom header")
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer test-token",
                "Should have authorization header")
        // Default headers should also be merged
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json",
                "Should still have default Content-Type")
    }
}

// MARK: - Advanced Tests

@Suite("DummyJSON Advanced Scenarios")
struct DummyJSONAdvancedTests {
    let client = DefaultNetworkClient()
    
    @Test("Concurrent requests don't interfere")
    func testConcurrentRequests() async throws {
        // Arrange
        let productIds = [1, 2, 3, 4, 5]
        
        // Act - Execute multiple requests concurrently
        let products = try await withThrowingTaskGroup(of: Product.self) { group in
            for id in productIds {
                group.addTask {
                    let endpoint = GetProductEndpoint(productId: id)
                    let request = Request(endpoint: endpoint)
                    let (product, _) = try await self.client.send(request)
                    return product
                }
            }
            
            var results: [Product] = []
            for try await product in group {
                results.append(product)
            }
            return results
        }
        
        // Assert
        #expect(products.count == 5, "Should fetch all 5 products")
        let ids = Set(products.map(\.id))
        #expect(ids.count == 5, "All products should have unique IDs")
        #expect(ids == Set(productIds), "IDs should match requested IDs")
    }
    
    @Test("Large pagination limit")
    func testLargePaginationLimit() async throws {
        // Arrange
        let endpoint = GetProductsEndpoint()
        let request = Request(
            endpoint: endpoint,
            queryParams: PaginationParameters(limit: 100, skip: 0)
        )
        
        // Act
        let (response, _) = try await client.send(request)
        
        // Assert
        #expect(response.products.count > 0, "Should return products")
        #expect(response.products.count <= 100, "Should respect limit")
    }
    
    @Test("Search with special characters")
    func testSearchWithSpecialCharacters() async throws {
        // Arrange
        let endpoint = SearchProductsEndpoint()
        let request = Request(
            endpoint: endpoint,
            queryParams: SearchParameters(q: "phone & tablet")
        )
        
        // Act & Assert - Should not crash
        _ = try await client.send(request)
    }
}
