import Authentication
import Fluent
import JWT
import Leaf
import Sugar
import Vapor

public final class ResetProvider<U: JWTAuthenticatable & PasswordResettable> {
    public let config: ResetConfig<U>

    public init(config: ResetConfig<U>) {
        self.config = config
    }
}

// MARK: - Provider
extension ResetProvider: Provider {
    public func register(_ services: inout Services) throws {
        services.register(config)
    }

    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        if config.shouldRegisterRoutes {
            try registerRoutes(on: container.make())
        }
        return .done(on: container)
    }
}

// MARK: - Commands
extension ResetProvider where U.Database: QuerySupporting, U.ID: LosslessStringConvertible {
    public static func commands(
        databaseIdentifier: DatabaseIdentifier<U.Database>
    ) -> [String: Command] {
        return [
            "reset:generate-token": GeneratePasswordResetTokenCommand<U>(
                databaseIdentifier: databaseIdentifier
            )
        ]
    }
}

// MARK: - Routes
extension ResetProvider {
    public func renderResetPasswordRequestForm(req: Request) throws -> Future<Response> {
        return try config.responses.resetPasswordRequestForm(req)
    }

    public func resetPasswordRequest(req: Request) throws -> Future<Response> {
        return try req
            .content
            .decode(U.RequestLinkType.self)
            .flatMap(to: U?.self) { try U.find(by: $0, on: req) }
            .flatMap(to: Void.self) { user in
                guard let user = user else {
                    // ignore case where user could not be found to prevent malicious users from
                    // finding out which accounts are available on the system
                    return .done(on: req)
                }
                return try user.signToken(using: self.config.signer, on: req)
                    .flatMap(to: Void.self) { token in
                        let link = try req
                            .baseURLString(includePort: true)
                            .appending("\(self.config.endpoints.resetPassword)/\(token)")
                        return user.sendPasswordResetLink(link, on: req)
                }
            }
            .flatMap(to: Response.self) { _ in
                try self.config.responses.resetPasswordEmailSent(req)
            }
    }

    public func renderResetPasswordForm(req: Request) throws -> Future<Response> {
        let payload = try extractVerifiedPayload(from: req.parameters.next())

        return try U
            .authenticate(using: payload, on: req)
            .unwrap(or: ResetError.userNotFound)
            .flatMap(to: Response.self) { user in
                guard user.passwordChangeCount == payload.passwordChangeCount else {
                    throw ResetError.tokenAlreadyUsed
                }
                return try self.config.responses.resetPasswordForm(req, user)
        }
    }

    public func resetPassword(req: Request) throws -> Future<Response> {
        let payload = try extractVerifiedPayload(from: req.parameters.next())

        return try U
            .authenticate(using: payload, on: req)
            .unwrap(or: ResetError.userNotFound)
            .flatMap(to: U.self) { user in
                try req
                    .content
                    .decode(U.ResetPasswordType.self)
                    .flatMap(to: U.self) { resetPassword in
                        var user = user
                        user.password = try U.hashPassword(resetPassword.password)
                        user.passwordChangeCount += 1
                        return user.save(on: req)
                    }
            }
            .flatMap(to: Response.self) { user in
                try self.config.responses.resetPasswordSuccess(req, user)
            }
    }
}

// MARK: - Private
private extension ResetProvider {
    func extractVerifiedPayload(from token: String) throws -> U.JWTPayload {
        let payload = try JWT<U.JWTPayload>(
            from: token.convertToData(),
            verifiedUsing: config.signer.signer
        ).payload

        try payload.verify()

        return payload
    }

    func registerRoutes(on router: Router) {
        let endpoints = config.endpoints
        router.get (endpoints.resetPasswordRequest, use: renderResetPasswordRequestForm)
        router.post(endpoints.resetPasswordRequest, use: resetPasswordRequest)
        router.get (endpoints.resetPassword, String.parameter, use: renderResetPasswordForm)
        router.post(endpoints.resetPassword, String.parameter, use: resetPassword)
    }
}
