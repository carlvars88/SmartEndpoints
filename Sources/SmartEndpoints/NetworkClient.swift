//
//  NetworkClient.swift
//  SmartEndpoints
//

/// Type-safe HTTP execution layer.
/// Three variants cover every credential scenario:
///   1. No credentials — public endpoints
///   2. Managed credentials — tokens that expire and need refresh
///   3. Pre-built Request — credentials already embedded by the caller
public protocol NetworkClient: AnyObject {

    // MARK: - Unauthenticated

    func execute<E: Endpoint>(
        _ endpoint: E,
        body: E.Body,
        parameters: E.Parameters,
        headers: HTTPHeaders
    ) async throws -> E.Result where E.Credentials == None

    // MARK: - Authenticated (managed credentials)

    func execute<E: Endpoint, P: CredentialProvider>(
        _ endpoint: E,
        body: E.Body,
        parameters: E.Parameters,
        headers: HTTPHeaders,
        credentialProvider: P
    ) async throws -> E.Result where P.Credentials == E.Credentials

    // MARK: - Pre-built Request (credentials embedded by caller)

    func execute<E: Endpoint>(_ request: Request<E>) async throws -> E.Result
}
