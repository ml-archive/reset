import Authentication
import JWT
import Sugar
import Vapor

public final class ResetController<U: JWTAuthenticatable & PasswordResettable> {
    public func renderResetPasswordRequestForm(req: Request) throws -> Future<Response> {
        let config: ResetConfig<U> = try req.make()
        return try config.responses.resetPasswordRequestForm(req)
    }

    public func resetPasswordRequest(req: Request) throws -> Future<Response> {
        let config: ResetConfig<U> = try req.make()
        return try U.RequestReset.create(on: req)
            .flatMap(to: U?.self) { try U.find(by: $0, on: req) }
            .flatTry { user -> Future<Void> in
                guard let user = user else {
                    // ignore case where user could not be found to prevent malicious attackers from
                    // finding out which accounts are available on the system
                    return .done(on: req)
                }
                return try config.reset(
                    user,
                    context: U.Context.requestResetPassword(),
                    on: req
                )
            }
            .flatMap(to: Response.self) { _ in
                try config.responses.resetPasswordUserNotified(req)
            }
    }

    public func renderResetPasswordForm(req: Request) throws -> Future<Response> {
        let config: ResetConfig<U> = try req.make()
        let payload = try config.extractVerifiedPayload(from: req.parameters.next())

        return try U
            .authenticate(using: payload, on: req)
            .unwrap(or: ResetError.userNotFound)
            .flatMap(to: Response.self) { user in
                guard user.passwordChangeCount == payload.passwordChangeCount else {
                    throw ResetError.tokenAlreadyUsed
                }
                return try config.responses.resetPasswordForm(req, user)
        }
    }

    public func resetPassword(req: Request) throws -> Future<Response> {
        let config: ResetConfig<U> = try req.make()
        let payload = try config.extractVerifiedPayload(from: req.parameters.next())

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
                try config.responses.resetPasswordSuccess(req, user)
            }
    }
}

fileprivate extension ResetConfig {
    fileprivate func extractVerifiedPayload(from token: String) throws -> U.JWTPayload {
        let payload = try JWT<U.JWTPayload>(
            from: token.convertToData(),
            verifiedUsing: signer.signer
        ).payload

        try payload.verify(using: signer.signer)

        return payload
    }
}
