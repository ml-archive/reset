import Routing
import Vapor

public struct ResetEndpoints {
    public let resetPasswordRequest : String
    public let resetPassword        : String

    /// Endpoints to use by provider when registering routes.
    ///
    /// - Parameters:
    ///   - resetPasswordRequest: reset password request endpoint (POST)
    ///   - resetPassword       : reset password endpoint (POST)
    public init(
        resetPasswordRequest: String,
        resetPassword       : String
    ) {
        self.resetPasswordRequest   = resetPasswordRequest
        self.resetPassword          = resetPassword
    }

    public static var `default`: ResetEndpoints {
        return .init(
            resetPasswordRequest: "/users/reset-password/request",
            resetPassword       : "/users/reset-password"
        )
    }
}
