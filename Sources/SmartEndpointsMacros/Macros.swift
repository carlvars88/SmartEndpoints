@_exported import SmartEndpoints

// MARK: - General macro (explicit HTTP method)

/// Declare an Endpoint with an explicit HTTP method.
///
///     @endpoint(.post, "/orders")
///     struct CreateOrder {
///         typealias API    = MyAPI
///         typealias Result = Order
///         typealias Body   = NewOrder   // override None when needed
///     }
///
/// The macro synthesises `method`, `path`, and defaults
/// `typealias Parameters = None` and `typealias Body = None`
/// unless you declare them yourself.
@attached(member, names: named(method), named(path), named(Parameters), named(Body))
@attached(extension, conformances: Endpoint)
public macro endpoint(_ method: HTTPMethod, _ path: StaticString) = #externalMacro(
    module: "SmartEndpointsMacrosImpl",
    type:   "EndpointMacro"
)

// MARK: - HTTP-method convenience macros

@attached(member, names: named(method), named(path), named(Parameters), named(Body))
@attached(extension, conformances: Endpoint)
public macro GET(_ path: StaticString) = #externalMacro(
    module: "SmartEndpointsMacrosImpl",
    type:   "GETMacro"
)

@attached(member, names: named(method), named(path), named(Parameters), named(Body))
@attached(extension, conformances: Endpoint)
public macro POST(_ path: StaticString) = #externalMacro(
    module: "SmartEndpointsMacrosImpl",
    type:   "POSTMacro"
)

@attached(member, names: named(method), named(path), named(Parameters), named(Body))
@attached(extension, conformances: Endpoint)
public macro PUT(_ path: StaticString) = #externalMacro(
    module: "SmartEndpointsMacrosImpl",
    type:   "PUTMacro"
)

@attached(member, names: named(method), named(path), named(Parameters), named(Body))
@attached(extension, conformances: Endpoint)
public macro PATCH(_ path: StaticString) = #externalMacro(
    module: "SmartEndpointsMacrosImpl",
    type:   "PATCHMacro"
)

@attached(member, names: named(method), named(path), named(Parameters), named(Body))
@attached(extension, conformances: Endpoint)
public macro DELETE(_ path: StaticString) = #externalMacro(
    module: "SmartEndpointsMacrosImpl",
    type:   "DELETEMacro"
)
