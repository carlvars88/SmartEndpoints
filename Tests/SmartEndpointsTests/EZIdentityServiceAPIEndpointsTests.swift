//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 9/11/25.
//

import XCTest
@testable import SmartEndpoints

final class EZIdentityServiceAPIEndpointsTests: XCTestCase {
    func testAuthenticateEndpoint() {
        let endpoint = EZIndentityServiceAPI.AuthorizeEndpoint()
        XCTAssertEqual(endpoint.api.baseUrl, "https://identity.enzona.net")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.path.value, "/oauth2/authorize")
        XCTAssert(type(of: endpoint.bodyEncoder) == EmptyBodyEncoder.self)
        XCTAssert(type(of: endpoint.credentialsEncoder) == EmptyCredentialsEncoder.self)
        XCTAssert(type(of: endpoint.parameterEncoder) == URLQueryEncoder<EZIndentityServiceAPI.AuthorizeEndpoint.Parameters>.self)
        XCTAssert(type(of: endpoint.responseDecoder) == PlainTextDecoder.self)
    }
    
    func testValidateUsernameEndpoint() {
        let endpoint = EZIndentityServiceAPI.ValidateUsernameEndpoint()
        XCTAssertEqual(endpoint.api.baseUrl, "https://identity.enzona.net")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "/commonauth")
        XCTAssert(type(of: endpoint.bodyEncoder) == FormURLEncodedBodyEncoder<EZIndentityServiceAPI.ValidateUsernameEndpoint.Body>.self)
        XCTAssert(type(of: endpoint.credentialsEncoder) == EmptyCredentialsEncoder.self)
        XCTAssert(type(of: endpoint.parameterEncoder) == EmptyParametersEncoder.self)
        XCTAssert(type(of: endpoint.responseDecoder) == PlainTextDecoder.self)
    }
    
    func testValidatePasswordEndpoint() {
        let endpoint = EZIndentityServiceAPI.ValidatePasswordEndpoint()
        XCTAssertEqual(endpoint.api.baseUrl, "https://identity.enzona.net")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "/commonauth")
        XCTAssert(type(of: endpoint.bodyEncoder) == FormURLEncodedBodyEncoder<EZIndentityServiceAPI.ValidatePasswordEndpoint.Body>.self)
        XCTAssert(type(of: endpoint.credentialsEncoder) == EmptyCredentialsEncoder.self)
        XCTAssert(type(of: endpoint.parameterEncoder) == EmptyParametersEncoder.self)
        XCTAssert(type(of: endpoint.responseDecoder) == PlainTextDecoder.self)
    }
    
    func testValidateTOPTEndpoint() {
        let endpoint = EZIndentityServiceAPI.ValidateTOTPEndpoint()
        XCTAssertEqual(endpoint.api.baseUrl, "https://identity.enzona.net")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "/commonauth")
        XCTAssert(type(of: endpoint.bodyEncoder) == FormURLEncodedBodyEncoder<EZIndentityServiceAPI.ValidateTOTPEndpoint.Body>.self)
        XCTAssert(type(of: endpoint.credentialsEncoder) == EmptyCredentialsEncoder.self)
        XCTAssert(type(of: endpoint.parameterEncoder) == EmptyParametersEncoder.self)
        XCTAssert(type(of: endpoint.responseDecoder) == PlainTextDecoder.self)
    }
    
    func testValidateSMSTOPTEndpoint() {
        let endpoint = EZIndentityServiceAPI.ValidateSMSTOTPEndpoint()
        XCTAssertEqual(endpoint.api.baseUrl, "https://identity.enzona.net")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.path.value, "/commonauth")
        XCTAssert(type(of: endpoint.bodyEncoder) == FormURLEncodedBodyEncoder<EZIndentityServiceAPI.ValidateSMSTOTPEndpoint.Body>.self)
        XCTAssert(type(of: endpoint.credentialsEncoder) == EmptyCredentialsEncoder.self)
        XCTAssert(type(of: endpoint.parameterEncoder) == EmptyParametersEncoder.self)
        XCTAssert(type(of: endpoint.responseDecoder) == PlainTextDecoder.self)
    }
}
