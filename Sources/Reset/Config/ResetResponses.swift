import Sugar
import Vapor

public struct ResetResponses<U: JWTAuthenticatable> {
    public let resetPasswordRequestForm : (Request) throws -> Future<Response>
    public let resetPasswordEmailSent   : (Request) throws -> Future<Response>
    public let resetPasswordForm        : (Request, U) throws -> Future<Response>
    public let resetPasswordSuccess     : (Request, U) throws -> Future<Response>

    public init(
        resetPasswordRequestForm: @escaping (Request) throws -> Future<Response>,
        resetPasswordEmailSent  : @escaping (Request) throws -> Future<Response>,
        resetPasswordForm       : @escaping (Request, U) throws -> Future<Response>,
        resetPasswordSuccess    : @escaping (Request, U) throws -> Future<Response>
    ) {
        self.resetPasswordRequestForm   = resetPasswordRequestForm
        self.resetPasswordEmailSent     = resetPasswordEmailSent
        self.resetPasswordForm          = resetPasswordForm
        self.resetPasswordSuccess       = resetPasswordSuccess
    }

    public static var `default`: ResetResponses {
        return .init(
            resetPasswordRequestForm: { req in
                return try HTTPResponse(status: .ok).encode(for: req)
            },
            resetPasswordEmailSent  : { req in
                return try HTTPResponse(status: .ok).encode(for: req)
            },
            resetPasswordForm       : { req, user in
                return try HTTPResponse(status: .ok).encode(for: req)
            },
            resetPasswordSuccess    : { req, user in
                return try HTTPResponse(status: .ok).encode(for: req)
            }
        )
    }
}
