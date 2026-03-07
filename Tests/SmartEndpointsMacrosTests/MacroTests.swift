import Testing
import SmartEndpointsMacros

// MARK: - Test fixtures
//
// These declarations are compile-time proof that the macros expand correctly.
// If macro expansion produces invalid Swift, this file will not compile.

private struct TestAPI: APIProtocol {
    typealias Credentials = None
    static let baseUrl = "https://api.example.com"
}

// Static path — no path tokens
@GET("/products")
private struct ListProducts {
    typealias API    = TestAPI
    typealias Result = Empty
}

// Single path token
@GET("/products/:id")
private struct GetProduct {
    typealias API    = TestAPI
    typealias Result = Empty
    let id: Int
}

// Multiple path tokens
@GET("/users/:userId/posts/:postId")
private struct GetUserPost {
    typealias API    = TestAPI
    typealias Result = Empty
    let userId: Int
    let postId: Int
}

// POST — user overrides Body, Parameters stays None
@POST("/products")
private struct CreateProduct {
    typealias API    = TestAPI
    typealias Result = Empty
    typealias Body   = CreateProductBody
}

private struct CreateProductBody: JSONEncodable, Sendable {
    let name: String
}

// PUT — user overrides Body
@PUT("/products/:id")
private struct UpdateProduct {
    typealias API    = TestAPI
    typealias Result = Empty
    typealias Body   = CreateProductBody
    let id: Int
}

// PATCH
@PATCH("/products/:id")
private struct PatchProduct {
    typealias API    = TestAPI
    typealias Result = Empty
    typealias Body   = CreateProductBody
    let id: Int
}

// DELETE
@DELETE("/products/:id")
private struct DeleteProduct {
    typealias API    = TestAPI
    typealias Result = Empty
    let id: Int
}

// @endpoint with explicit method
@endpoint(.post, "/orders")
private struct CreateOrder {
    typealias API    = TestAPI
    typealias Result = Empty
    typealias Body   = CreateProductBody
}

// MARK: - Runtime tests

@Suite("Macro expansion — method")
struct MethodTests {
    @Test func get()    { #expect(ListProducts().method    == .get)    }
    @Test func post()   { #expect(CreateProduct().method  == .post)   }
    @Test func put()    { #expect(UpdateProduct(id: 1).method == .put) }
    @Test func patch()  { #expect(PatchProduct(id: 1).method == .patch) }
    @Test func delete() { #expect(DeleteProduct(id: 1).method == .delete) }
    @Test func explicitEndpointMacro() { #expect(CreateOrder().method == .post) }
}

@Suite("Macro expansion — path")
struct PathTests {
    @Test func staticPath() {
        #expect(ListProducts().path.value == "/products")
    }

    @Test func singleToken() {
        #expect(GetProduct(id: 42).path.value == "/products/42")
    }

    @Test func multipleTokens() {
        let e = GetUserPost(userId: 7, postId: 99)
        #expect(e.path.value == "/users/7/posts/99")
    }

    @Test func tokenInPOST() {
        #expect(UpdateProduct(id: 5).path.value == "/products/5")
    }
}

@Suite("Macro expansion — default typealiases")
struct DefaultTypealiasTests {
    // Verifying at the type level that None was synthesised.
    // If Parameters or Body were NOT None, these type assertions would not compile.
    @Test func listProductsHasNoneParameters() {
        #expect(ListProducts.Parameters.self == None.self)
        #expect(ListProducts.Body.self == None.self)
    }

    @Test func createProductHasNoneParameters() {
        #expect(CreateProduct.Parameters.self == None.self)
        #expect(CreateProduct.Body.self == CreateProductBody.self)
    }
}
