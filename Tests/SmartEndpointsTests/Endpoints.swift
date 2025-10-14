//
//  File.swift
//  SmartEndpoints
//
//  Created by MacBook Pro on 9/9/25.
//

import Foundation
@testable import SmartEndpoints

struct EZIndentityServiceAPI: APIProtocol {
    static let baseUrl = "https://identity.enzona.net"
}

protocol EZIndentityServiceAPIEndpoint: Endpoint {}

extension EZIndentityServiceAPIEndpoint {
    var api: EZIndentityServiceAPI.Type { EZIndentityServiceAPI.self }
    var responseDecoder: PlainTextDecoder { .shared }
    var credentialsEncoder: EmptyCredentialsEncoder { .shared }
}

extension EZIndentityServiceAPI {
    struct AuthorizeEndpoint: EZIndentityServiceAPIEndpoint {
        typealias ParametersEncoder =  URLQueryEncoder<Parameters>
        typealias BodyEncoder = EmptyBodyEncoder
        let path = Path("/oauth2/authorize")
        let method: HTTPMethod = .get
    }
    
    struct ValidateUsernameEndpoint: EZIndentityServiceAPIEndpoint {
        typealias ParametersEncoder = EmptyParametersEncoder
        typealias BodyEncoder = FormURLEncodedBodyEncoder<Body>
        let path = Path("/commonauth")
        let method: HTTPMethod = .post
    }
    
    struct ValidatePasswordEndpoint: EZIndentityServiceAPIEndpoint {
        typealias ParametersEncoder = EmptyParametersEncoder
        typealias BodyEncoder = FormURLEncodedBodyEncoder<Body>
        let path = Path("/commonauth")
        let method: HTTPMethod = .post
    }
    
    struct ValidateTOTPEndpoint: EZIndentityServiceAPIEndpoint {
        typealias ParametersEncoder = EmptyParametersEncoder
        typealias BodyEncoder = FormURLEncodedBodyEncoder<Body>
        let path = Path("/commonauth")
        let method: HTTPMethod = .post
    }
    
    struct ValidateSMSTOTPEndpoint: EZIndentityServiceAPIEndpoint {
        typealias ParametersEncoder = EmptyParametersEncoder
        typealias BodyEncoder = FormURLEncodedBodyEncoder<Body>
        let path = Path("/commonauth")
        let method: HTTPMethod = .post
    }
}

extension EZIndentityServiceAPI.AuthorizeEndpoint {
    struct Parameters: Encodable {
        let clientId: String
        let redirectUri: String
        let scope: String
        let codeChallenge: String
        let codeChallengeMethod: String
        let responseType: String
        let deviceAuth: String?
        
        enum CodingKeys: String, CodingKey {
            case clientId = "client_id"
            case redirectUri = "redirect_uri"
            case scope
            case codeChallenge = "code_challenge"
            case codeChallengeMethod = "code_challenge_method"
            case responseType = "response_type"
            case deviceAuth
        }
    }
}

extension EZIndentityServiceAPI.ValidateUsernameEndpoint {
    struct Body: Encodable {
        let username: String
        let sessionDataKey: String
    }
}

extension EZIndentityServiceAPI.ValidatePasswordEndpoint {
    struct Body: Encodable {
        let username: String
        let password: String
        let sessionDataKey: String
    }
}

extension EZIndentityServiceAPI.ValidateTOTPEndpoint {
    struct Body: Encodable {
        let token: String
        let sessionDataKey: String
        let saveDevice: String // "on" or not present
    }
}

extension EZIndentityServiceAPI.ValidateSMSTOTPEndpoint {
    struct Body: Encodable {
        let token: String
        let sessionDataKey: String
        let saveDevice: String // "on" or not present
    }
    
    enum CodingKeys: String, CodingKey {
        case token = "OTPcode"
        case sessionDataKey
        case saveDevice
    }
}

