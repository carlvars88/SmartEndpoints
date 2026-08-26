// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SmartEndpoints",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "SmartEndpoints", targets: ["SmartEndpoints"]),
        // Opt-in product: adds @GET, @POST, @endpoint etc. macros.
        // Brings SmartEndpoints along automatically via @_exported import.
        .library(name: "SmartEndpointsMacros", targets: ["SmartEndpoints", "SmartEndpointsMacros"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "601.0.0"),
        .package(url: "https://github.com/carlvars88/NetworkingCore", branch: "main"),
    ],
    targets: [
        .target(
            name: "SmartEndpoints",
            dependencies: [
                .product(name: "NetworkingCore", package: "NetworkingCore"),
            ]
        ),

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
            dependencies: [
                "SmartEndpoints",
                .product(name: "NetworkingCore", package: "NetworkingCore"),
            ]
        ),
        .testTarget(
            name: "SmartEndpointsMacrosTests",
            dependencies: ["SmartEndpointsMacros"]
        ),
    ]
)
