import Service
import Sugar

public struct ResetConfig<U: JWTAuthenticatable & PasswordResettable>: Service {
    public let endpoints: ResetEndpoints
    public let shouldRegisterRoutes: Bool
    public let signer: ExpireableJWTSigner
    public let responses: ResetResponses<U>

    /// Creates a new PasswordReset configuration.
    ///
    /// - Parameters:
    ///   - endpoints: determines the endpoints for the routes
    ///   - shouldRegisterRoutes: determines whether to register the default routes at boot time
    ///   - signer: signer and expiration period for password reset tokens
    ///   - viewPaths: contains the paths to the views to be rendered
    public init(
        endpoints: ResetEndpoints = .default,
        shouldRegisterRoutes: Bool = true,
        signer: ExpireableJWTSigner,
        responses: ResetResponses<U> = .default
    ) {
        self.signer = signer
        self.endpoints = endpoints
        self.shouldRegisterRoutes = shouldRegisterRoutes
        self.responses = responses
    }
}
