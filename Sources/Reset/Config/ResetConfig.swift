import JWT
import Service
import Sugar
import Vapor

public struct ResetConfig<U: JWTAuthenticatable & PasswordResettable>: Service {
    public let baseURL: String
    public let controller: ResetControllerType
    public let endpoints: ResetEndpoints
    public let name: String
    public let responses: ResetResponses<U>
    public let signer: JWTSigner

    /// Creates a new PasswordReset configuration.
    ///
    /// - Parameters:
    ///   - name: the name of your project.
    ///   - baseURL: the base url of your project. Used for generating reset password links.
    ///   - endpoints: determines the endpoints for the routes
    ///   - signer: signer and expiration period for password reset tokens.
    ///   - responses: contains the responses to be returned when requesting the endpoints.
    ///   - controller: contains logic for handling the reset password flow.
    public init(
        name: String,
        baseURL: String,
        endpoints: ResetEndpoints = .default,
        signer: JWTSigner,
        responses: ResetResponses<U> = .default,
        controller: ResetControllerType = ResetController<U>()
    ) {
        self.baseURL = baseURL
        self.controller = controller
        self.endpoints = endpoints
        self.name = name
        self.responses = responses
        self.signer = signer
    }
}

// MAKR: - Helpers

public extension ResetConfig {
    func reset<T: PasswordResettable>(
        _ object: T,
        context: T.Context,
        on req: Request
    ) throws -> Future<Void> {
        let expirationPeriod = T.expirationPeriod(for: context)
        let expirableSigner = ExpireableJWTSigner(
            expirationPeriod: expirationPeriod,
            signer: signer
        )
        return try object
            .signToken(using: expirableSigner, on: req)
            .flatMap(to: Void.self) { token in
                let url = self.baseURL
                    .appending("\(self.endpoints.resetPassword ?? "")/\(token)")
                return try object.sendPasswordReset(
                    url: url,
                    token: token,
                    expirationPeriod: expirationPeriod,
                    context: context,
                    on: req
                )
            }
    }
}
