import SwiftSyntax
import SwiftSyntaxMacros

// Each macro is a thin wrapper that hardcodes its HTTP method and forwards
// all logic to EndpointExpansion.

public struct GETMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "get", pathTemplate: path)
            .members(for: declaration, in: context)
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "get", pathTemplate: path)
            .extensions(for: declaration, type: type, in: context)
    }
}

public struct POSTMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "post", pathTemplate: path)
            .members(for: declaration, in: context)
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "post", pathTemplate: path)
            .extensions(for: declaration, type: type, in: context)
    }
}

public struct PUTMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "put", pathTemplate: path)
            .members(for: declaration, in: context)
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "put", pathTemplate: path)
            .extensions(for: declaration, type: type, in: context)
    }
}

public struct PATCHMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "patch", pathTemplate: path)
            .members(for: declaration, in: context)
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "patch", pathTemplate: path)
            .extensions(for: declaration, type: type, in: context)
    }
}

public struct DELETEMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "delete", pathTemplate: path)
            .members(for: declaration, in: context)
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let path = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: "delete", pathTemplate: path)
            .extensions(for: declaration, type: type, in: context)
    }
}
