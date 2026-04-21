import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Diagnostics

enum EndpointMacroDiagnostic: DiagnosticMessage {
    case mustBeStruct
    case missingPathProperty(String)

    var message: String {
        switch self {
        case .mustBeStruct:
            return "@endpoint macros can only be applied to a struct"
        case .missingPathProperty(let name):
            return "Path template uses ':\(name)' but no stored property named '\(name)' was found"
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .mustBeStruct:
            return MessageID(domain: "SmartEndpointsMacros", id: "mustBeStruct")
        case .missingPathProperty(let name):
            return MessageID(domain: "SmartEndpointsMacros", id: "missingPathProperty.\(name)")
        }
    }

    var severity: DiagnosticSeverity { .error }
}

struct MacroError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

// MARK: - Core expansion logic

struct EndpointExpansion {
    let httpMethod: String
    let pathTemplate: String

    // MARK: Member expansion

    func members(
        for declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: Syntax(declaration),
                message: EndpointMacroDiagnostic.mustBeStruct
            ))
            return []
        }

        let tokens = pathTokens(in: pathTemplate)
        let props  = storedPropertyNames(in: declaration)

        for token in tokens where !props.contains(token) {
            context.diagnose(Diagnostic(
                node: Syntax(declaration),
                message: EndpointMacroDiagnostic.missingPathProperty(token)
            ))
        }

        let existingAliases = existingTypealiasNames(in: declaration)
        var members: [DeclSyntax] = []

        members.append("var method: String { \"\(raw: httpMethod.uppercased())\" }")
        members.append("\(raw: makePathDecl())")

        if !existingAliases.contains("Parameters") {
            members.append("typealias Parameters = None")
        }
        if !existingAliases.contains("Body") {
            members.append("typealias Body = None")
        }

        return members
    }

    // MARK: Extension expansion

    func extensions(
        for declaration: some DeclGroupSyntax,
        type: some TypeSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else { return [] }
        return [try ExtensionDeclSyntax("extension \(type.trimmed): Endpoint {}")]
    }

    // MARK: Argument extraction

    /// Extracts the path from the LAST argument — works for both
    /// `@GET("/path")` (1 arg) and `@endpoint(.get, "/path")` (2 args).
    static func extractPath(from node: AttributeSyntax) throws -> String {
        guard
            let argList = node.arguments?.as(LabeledExprListSyntax.self),
            let last = argList.last,
            let stringLit = last.expression.as(StringLiteralExprSyntax.self),
            let segment  = stringLit.segments.first?.as(StringSegmentSyntax.self)
        else {
            throw MacroError("Expected a string literal path argument")
        }
        return segment.content.text
    }

    /// Extracts the HTTP method name from the FIRST argument of @endpoint.
    /// `"GET"` → "GET",  `"get"` → "GET"
    static func extractMethod(from node: AttributeSyntax) throws -> String {
        guard
            let argList = node.arguments?.as(LabeledExprListSyntax.self),
            let first = argList.first,
            let stringLit = first.expression.as(StringLiteralExprSyntax.self),
            let segment = stringLit.segments.first?.as(StringSegmentSyntax.self)
        else {
            throw MacroError("Method argument must be a string literal (e.g. \"GET\")")
        }
        return segment.content.text.uppercased()
    }

    // MARK: Private helpers

    private func pathTokens(in template: String) -> [String] {
        var tokens: [String] = []
        var i = template.startIndex
        while i < template.endIndex {
            guard template[i] == ":" else { i = template.index(after: i); continue }
            let start = template.index(after: i)
            var end = start
            while end < template.endIndex,
                  template[end].isLetter || template[end].isNumber || template[end] == "_" {
                end = template.index(after: end)
            }
            if start < end { tokens.append(String(template[start..<end])) }
            i = end
        }
        return tokens
    }

    private func storedPropertyNames(in declaration: some DeclGroupSyntax) -> Set<String> {
        var names = Set<String>()
        for item in declaration.memberBlock.members {
            guard let v = item.decl.as(VariableDeclSyntax.self) else { continue }
            let isLet       = v.bindingSpecifier.tokenKind == .keyword(.let)
            let isStoredVar = v.bindingSpecifier.tokenKind == .keyword(.var)
                           && v.bindings.allSatisfy { $0.accessorBlock == nil }
            guard isLet || isStoredVar else { continue }
            for binding in v.bindings {
                if let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
                    names.insert(name)
                }
            }
        }
        return names
    }

    private func existingTypealiasNames(in declaration: some DeclGroupSyntax) -> Set<String> {
        Set(declaration.memberBlock.members.compactMap {
            $0.decl.as(TypeAliasDeclSyntax.self)?.name.text
        })
    }

    /// Builds the source string for `var path: Path { ... }`.
    private func makePathDecl() -> String {
        let tokens = pathTokens(in: pathTemplate)
        guard !tokens.isEmpty else {
            return "var path: Path { Path(\"\(pathTemplate)\") }"
        }
        // Produces e.g. "id": "\(id)", "name": "\(name)"
        let pairs = tokens
            .map { "\"\($0)\": \"\\(\($0))\"" }
            .joined(separator: ", ")
        return "var path: Path { Path(\"\(pathTemplate)\", values: [\(pairs)]) }"
    }
}

// MARK: - @endpoint macro (explicit HTTP method)

public struct EndpointMacro: MemberMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let method = try EndpointExpansion.extractMethod(from: node)
        let path   = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: method, pathTemplate: path)
            .members(for: declaration, in: context)
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let method = try EndpointExpansion.extractMethod(from: node)
        let path   = try EndpointExpansion.extractPath(from: node)
        return try EndpointExpansion(httpMethod: method, pathTemplate: path)
            .extensions(for: declaration, type: type, in: context)
    }
}
