import Routing
import Vapor

public struct ResetEndpoints {
    public let renderResetPasswordRequest: String?
    public let resetPasswordRequest: String?
    public let renderResetPassword: String?
    public let resetPassword: String?

    /// Endpoints to use by provider when registering routes.
    ///
    /// - Parameters:
    ///   - renderResetPasswordRequest: reset password request form endpoint (GET).
    ///   - resetPasswordRequest: reset password request endpoint (POST).
    ///   - renderResetPassword: reset password form endpoint (GET).
    ///   - resetPassword: reset password endpoint (POST).
    public init(
        renderResetPasswordRequest: String? = nil,
        resetPasswordRequest: String? = nil,
        renderResetPassword: String? = nil,
        resetPassword: String? = nil
    ) {
        self.renderResetPasswordRequest = renderResetPasswordRequest
        self.resetPasswordRequest = resetPasswordRequest
        self.renderResetPassword = renderResetPassword
        self.resetPassword = resetPassword
    }

    public static var `default`: ResetEndpoints {
        return .init(
            renderResetPasswordRequest: "/users/reset-password/request",
            resetPasswordRequest: "/users/reset-password/request",
            renderResetPassword: "/users/reset-password",
            resetPassword: "/users/reset-password"
        )
    }
}
