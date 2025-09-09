import XCTest
@testable import SmartEndpoins


struct TestAPI: API {
    static let baseUrl = "https://example.test"
    var defaultHeaders: [String: String] { ["X-Unit": "1"] }
}

struct UserDTO: Decodable, Equatable, Sendable { let id: Int }
struct TokenDTO: Decodable, Equatable, Sendable { let accessToken: String }
struct LoginBody: Encodable, Equatable, Sendable { let username: String; let password: String }
struct SearchParams: Encodable, Equatable, Sendable { let q: String }


struct GetUsers: QueryableRestEndpoint {
    typealias A = TestAPI
    typealias PEncoder = URLQueryEncoder<SearchParams>
    typealias RDecoder = JSONResponseDecoder<[UserDTO]>
    let path: Path = Path("/users")
}

struct Login: PostableRestEndpoint {
    typealias A = TestAPI
    typealias BEncoder = JSONBodyEncoder<LoginBody>
    typealias RDecoder = JSONResponseDecoder<TokenDTO>

    let path: Path = Path("/login")
}

struct RawSearch: RawQueryableEndpoint {
    typealias A = TestAPI
    typealias PEncoder = URLQueryEncoder<SearchParams>
    let path: Path = Path("/search")
}

struct SubmitForm: RawPostableEndpoint {
    typealias A = TestAPI
    struct Form: Encodable, Equatable, Sendable { let a: String; let b: String }
    typealias BEncoder = FormURLEncodedBodyEncoder<Form>

    let path: Path = Path("/submit")
}

final class EndpointWitnessMatchingTests: XCTestCase {
    
    func testGETMethodMarker() {
        XCTAssertEqual(GetUsers().method, "GET")
    }
    
    func testPOSTMethodMarker() {
        XCTAssertEqual(Login().method, "POST")
    }
    
    // MARK: Parameter encoders
    
    func testQueryableProvidesURLQueryEncoder() {
        let e = RawSearch()
        XCTAssertTrue(type(of: e.bodyEncoder) == EmptyBodyEncoder.self)
        let _: URLQueryEncoder<SearchParams> = e.parameterEncoder
    }
    
    func testEmptyParametersEncoderWitness() {
        let e = Login()
        let _: EmptyParametersEncoder = e.parameterEncoder
    }
    
    // MARK: Body encoders
    
    func testEmptyBodyEncoderWitness() {
        do {
            let e = GetUsers()
            let _: EmptyBodyEncoder = e.bodyEncoder
        }
        do {
            let e = RawSearch()
            let _: EmptyBodyEncoder = e.bodyEncoder
        }
    }
    
    func testRuntime_parameterEncoderMetatype() {
        let e = RawSearch()
        XCTAssertTrue(type(of: e.parameterEncoder) == URLQueryEncoder<SearchParams>.self)
        
        let l = Login()
        XCTAssertTrue(type(of: l.parameterEncoder) == EmptyParametersEncoder.self)
    }
    
    func testRuntime_bodyEncoderMetatype() {
        let g = GetUsers()
        XCTAssertTrue(type(of: g.bodyEncoder) == EmptyBodyEncoder.self)
        
        let p = Login()
        XCTAssertTrue(type(of: p.bodyEncoder) == JSONBodyEncoder<LoginBody>.self)
        
        let f = SubmitForm()
        XCTAssertTrue(type(of: f.bodyEncoder) == FormURLEncodedBodyEncoder<SubmitForm.Form>.self)
    }
    
    func testRuntime_credentialsAndDecoderMetatype() {
        let g = GetUsers()
        XCTAssertTrue(type(of: g.credentialsEncoder) == BearerCredentialEncoder.self)
        XCTAssertTrue(type(of: g.responseDecoder) == JSONResponseDecoder<[UserDTO]>.self)
        XCTAssertTrue(GetUsers.Credentials.self == String.self) // associated-type metatype equality
        
        let r = RawSearch()
        XCTAssertTrue(type(of: r.credentialsEncoder) == EmptyCredentialsEncoder.self)
        XCTAssertTrue(type(of: r.responseDecoder) == PlainTextDecoder.self)
        XCTAssertTrue(RawSearch.Credentials.self == None.self)
    }
    
    // MARK: Typealias compositions
    
    func testTypealiasesComposeCorrectly() {
        let _: any RawQueryableEndpoint = RawSearch()
        let _: any QueryableRestEndpoint = GetUsers()
        let _: any PostableRestEndpoint = Login()
        let _: any RawPostableEndpoint = SubmitForm()
    }
}

