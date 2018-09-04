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
        try services.register(MutableLeafTagConfigProvider())
        services.register(config)
        services.register(ResetConfigTagData(name: config.name, baseURL: config.baseURL))
    }

    public func didBoot(_ container: Container) throws -> Future<Void> {
        if config.shouldRegisterRoutes {
            try registerRoutes(on: container.make())
        }
        
        let tags: MutableLeafTagConfig = try container.make()
        tags.use(ResetConfigTag(), as: "reset:config")

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
        return try U.RequestReset.create(on: req)
            .flatMap(to: U?.self) { try U.find(by: $0, on: req) }
            .flatTry { user -> Future<Void> in
                guard let user = user else {
                    // ignore case where user could not be found to prevent malicious attackers from
                    // finding out which accounts are available on the system
                    return .done(on: req)
                }
                return try self.config.reset(
                    user,
                    context: U.Context.requestResetPassword(),
                    on: req
                )
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
            .try { user in
                guard user.passwordChangeCount == payload.passwordChangeCount else {
                    throw ResetError.tokenAlreadyUsed
                }
            }
            .flatMap(to: U.self) { user in
                try U.ResetPassword.create(on: req)
                    .flatMap(to: U.self) { resetPassword in
                        var user = user
                        let password = resetPassword[keyPath: U.ResetPassword.readablePasswordKey]
                        user[keyPath: U.passwordKey] = try U.hashPassword(password)
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

        try payload.verify(using: config.signer.signer)

        return payload
    }

    func registerRoutes(on router: Router) {
        let endpoints = config.endpoints

        if let renderResetPasswordRequestPath = endpoints.renderResetPasswordRequest {
            router.get(renderResetPasswordRequestPath, use: renderResetPasswordRequestForm)
        }

        if let resetPasswordRequestPath = endpoints.resetPasswordRequest {
            router.post(resetPasswordRequestPath, use: resetPasswordRequest)
        }

        if let renderResetPasswordPath = endpoints.renderResetPassword {
            router.get(renderResetPasswordPath, String.parameter, use: renderResetPasswordForm)
        }

        if let resetPasswordPath = endpoints.resetPassword {
            router.post(resetPasswordPath, String.parameter, use: resetPassword)
        }
    }
}
