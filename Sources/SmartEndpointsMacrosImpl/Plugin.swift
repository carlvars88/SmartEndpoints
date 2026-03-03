import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SmartEndpointsMacrosPlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        EndpointMacro.self,
        GETMacro.self,
        POSTMacro.self,
        PUTMacro.self,
        PATCHMacro.self,
        DELETEMacro.self,
    ]
}
