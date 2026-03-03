// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SmartEndpoints",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "SmartEndpoints", targets: ["SmartEndpoints"]),
        // Opt-in product: adds @GET, @POST, @endpoint etc. macros.
        // Brings SmartEndpoints along automatically via @_exported import.
        .library(name: "SmartEndpointsMacros", targets: ["SmartEndpoints", "SmartEndpointsMacros"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "601.0.0"),
    ],
    targets: [
        .target(name: "SmartEndpoints"),

        // Macro implementation — compiled as a compiler plug-in, never linked into the app.
        .macro(
            name: "SmartEndpointsMacrosImpl",
            dependencies: [
                .product(name: "SwiftSyntax",         package: "swift-syntax"),
                .product(name: "SwiftDiagnostics",    package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros",   package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),

        // Macro declarations — what users import.
        .target(
            name: "SmartEndpointsMacros",
            dependencies: ["SmartEndpoints", "SmartEndpointsMacrosImpl"]
        ),

        .testTarget(
            name: "SmartEndpointsTests",
            dependencies: ["SmartEndpoints"]
        ),
        .testTarget(
            name: "SmartEndpointsMacrosTests",
            dependencies: ["SmartEndpointsMacros"]
        ),
    ]
)
