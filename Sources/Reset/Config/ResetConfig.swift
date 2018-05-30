import Service
import Sugar

public struct ResetConfig<U: JWTAuthenticatable & PasswordResettable>: Service {
    public let name: String
    public let baseUrl: String
    public let endpoints: ResetEndpoints
    public let shouldRegisterRoutes: Bool
    public let signer: ExpireableJWTSigner
    public let responses: ResetResponses<U>

    /// Creates a new PasswordReset configuration.
    ///
    /// - Parameters:
    ///   - name: the name of your project
    ///   - baseUrl: the base url of your project. Used for generating reset password links.
    ///   - endpoints: determines the endpoints for the routes
    ///   - shouldRegisterRoutes: determines whether to register the default routes at boot time
    ///   - signer: signer and expiration period for password reset tokens
    ///   - responses: contains the responses to be returned when requesting the endpoints
    public init(
        name: String,
        baseUrl: String,
        endpoints: ResetEndpoints = .default,
        shouldRegisterRoutes: Bool = true,
        signer: ExpireableJWTSigner,
        responses: ResetResponses<U> = .default
    ) {
        self.name = name
        self.baseUrl = baseUrl
        self.signer = signer
        self.endpoints = endpoints
        self.shouldRegisterRoutes = shouldRegisterRoutes
        self.responses = responses
    }
}
