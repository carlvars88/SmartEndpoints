//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 9/11/25.
//

import XCTest
@testable import SmartEndpoints

final class NetworkClientTest: XCTestCase {
    func testBuildRequest() {
        let endpoint = EZIndentityServiceAPI.AuthorizeEndpoint()
        let networkClient = DefaultNetworkClient()
        let paramters = EZIndentityServiceAPI.AuthorizeEndpoint.Parameters(clientId: "test_client", redirectUri: "test_redirect_uri", scope: "test_scope", codeChallenge: "test_code_challenge", codeChallengeMethod: "test_code_challenge_method", responseType: "test_response_type", deviceAuth: "test_device_auth")
        let request = try? XCTUnwrap(networkClient.buildRequest(request: Request(endpoint: endpoint, queryParams: paramters)))
        XCTAssert(request?.url?.absoluteString.contains("client_id=test_client") ?? false)
        XCTAssert(request?.url?.absoluteString.contains("redirect_uri=test_redirect_uri") ?? false)
        XCTAssert(request?.url?.absoluteString.contains("scope=test_scope") ?? false)
        XCTAssert(request?.url?.absoluteString.contains("code_challenge=test_code_challenge") ?? false)
        XCTAssert(request?.url?.absoluteString.contains("code_challenge_method=test_code_challenge_method") ?? false)
        XCTAssert(request?.url?.absoluteString.contains("response_type=test_response_type") ?? false)
    }
}
