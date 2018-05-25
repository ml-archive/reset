import Leaf
import Sugar
import Vapor

public struct ResetResponses<U: JWTAuthenticatable> {
    private enum ViewPaths: String {
        case resetPasswordRequestForm = "PasswordReset/reset-password-request-form"
        case resetPasswordEmailSent = "PasswordReset/reset-password-email-sent"
        case resetPasswordForm = "PasswordReset/reset-password-form"
        case resetPasswordSuccess = "PasswordReset/reset-password-success"
    }

    public let resetPasswordRequestForm: (Request) throws -> Future<Response>
    public let resetPasswordEmailSent: (Request) throws -> Future<Response>
    public let resetPasswordForm: (Request, U) throws -> Future<Response>
    public let resetPasswordSuccess: (Request, U) throws -> Future<Response>

    public init(
        resetPasswordRequestForm: @escaping (Request) throws -> Future<Response>,
        resetPasswordEmailSent: @escaping (Request) throws -> Future<Response>,
        resetPasswordForm: @escaping (Request, U) throws -> Future<Response>,
        resetPasswordSuccess: @escaping (Request, U) throws -> Future<Response>
    ) {
        self.resetPasswordRequestForm = resetPasswordRequestForm
        self.resetPasswordEmailSent = resetPasswordEmailSent
        self.resetPasswordForm = resetPasswordForm
        self.resetPasswordSuccess = resetPasswordSuccess
    }

    public static var `default`: ResetResponses {
        return .init(
            resetPasswordRequestForm: { req in
                return try req
                    .make(LeafRenderer.self)
                    // TODO: Remove empty context when this gets fixed
                    // https://github.com/vapor/template-kit/issues/17
                    .render(ViewPaths.resetPasswordRequestForm.rawValue, [String: String]())
                    .encode(for: req)
            },
            resetPasswordEmailSent: { req in
                guard
                    req.http.accept.comparePreference(for: .html, to: .json) == .orderedAscending
                else {
                    return try HTTPResponse(status: .ok).encode(for: req)
                }

                return try req
                    .make(LeafRenderer.self)
                    // TODO: Remove empty context when this gets fixed
                    // https://github.com/vapor/template-kit/issues/17
                    .render(ViewPaths.resetPasswordEmailSent.rawValue, [String: String]())
                    .encode(for: req)
            },
            resetPasswordForm: { req, user in
                return try req
                    .make(LeafRenderer.self)
                    // TODO: Remove empty context when this gets fixed
                    // https://github.com/vapor/template-kit/issues/17
                    .render(ViewPaths.resetPasswordForm.rawValue, [String: String]())
                    .encode(for: req)
            },
            resetPasswordSuccess: { req, user in
                guard
                    req.http.accept.comparePreference(for: .html, to: .json) == .orderedAscending
                else {
                    return try HTTPResponse(status: .ok).encode(for: req)
                }

                return try req
                    .make(LeafRenderer.self)
                    // TODO: Remove empty context when this gets fixed
                    // https://github.com/vapor/template-kit/issues/17
                    .render(ViewPaths.resetPasswordSuccess.rawValue, [String: String]())
                    .encode(for: req)
            }
        )
    }
}
