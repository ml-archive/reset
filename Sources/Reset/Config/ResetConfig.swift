import Service
import Sugar
import Vapor

public struct ResetConfig<U: JWTAuthenticatable & PasswordResettable>: Service {
    public let name: String
    public let baseURL: String
    public let endpoints: ResetEndpoints
    public let signer: ExpireableJWTSigner
    public let responses: ResetResponses<U>
    public let controller: ResetController<U>

    /// Creates a new PasswordReset configuration.
    ///
    /// - Parameters:
    ///   - name: the name of your project.
    ///   - baseURL: the base url of your project. Used for generating reset password links.
    ///   - endpoints: determines the endpoints for the routes
    ///   - signer: signer and expiration period for password reset tokens.
    ///   - responses: contains the responses to be returned when requesting the endpoints.
    public init(
        name: String,
        baseURL: String,
        endpoints: ResetEndpoints = .default,
        shouldRegisterRoutes: Bool = true,
        signer: ExpireableJWTSigner,
        responses: ResetResponses<U> = .default
    ) {
        self.name = name
        self.baseURL = baseURL
        self.signer = signer
        self.endpoints = endpoints
        self.responses = responses
        self.controller = ResetController<U>()
    }
}

// MAKR: - Helpers

public extension ResetConfig {
    func reset<T: PasswordResettable>(
        _ object: T,
        context: T.Context,
        on req: Request
    ) throws -> Future<Void> {
        let signer = try object.signer(for: context, on: req)
        return try object.signToken(using: signer, on: req)
            .flatMap(to: Void.self) { token in
                let url = self.baseURL
                    .appending("\(self.endpoints.resetPassword ?? "")/\(token)")
                return try object.sendPasswordReset(
                    url: url,
                    token: token,
                    expirationPeriod: signer.expirationPeriod,
                    context: context,
                    on: req
                )
        }
    }
}
