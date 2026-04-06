//
//  CredentialProvider.swift
//  SmartEndpoints
//

/// Supplies and refreshes credentials of a specific encodable type.
/// Conform to this protocol to provide managed credentials (e.g. access tokens
/// that can expire and need refresh) to a NetworkClient.
public protocol CredentialProvider: AnyObject, Sendable {
    associatedtype Credentials: CredentialsEncodable
    func currentCredentials() async throws -> Credentials
    func refreshCredentials() async throws
}
